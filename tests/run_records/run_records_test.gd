extends SceneTree

const Run = preload("res://src/service/gameplay/run_state.gd")
const Recorder = preload("res://src/service/run_records/run_recorder.gd")
const Summary = preload("res://src/service/run_records/record_summary.gd")
const Store = preload("res://src/service/run_records/record_store.gd")
const Rules = preload("res://src/configs/gameplay/game_rules.gd")
const Market = preload("res://src/service/shop/cat_market.gd")
var failures := 0

func _init() -> void:
	_test_actions()
	_test_economy()
	_test_effects()
	_test_lifecycle()
	_test_observer()
	_test_storage()
	print("Run record tests: %d failures" % failures)
	quit(1 if failures else 0)

func _test_actions() -> void:
	var game = Run.new()
	var log = Recorder.new(game)
	game.start(Rules.TEST_SEED)
	var original: Array = log.document().events[0].after.hand.duplicate()
	game.place(game.hand[0], Vector2i.ZERO)
	game.place(game.hand[0], Vector2i.RIGHT)
	game.score = Rules.SWAP_COSTS[0]
	game.swap(Vector2i.ZERO, Vector2i.RIGHT)
	game.undo()
	game.discard([game.hand[0]])
	var count: int = log.document().events.size()
	game.preview()
	game.preview()
	game.discard([])
	_check(log.document().events.size() == count, "Previews and rejected actions create no events")
	var result: Dictionary = game.settle()
	var doc: Dictionary = log.document()
	var event: Dictionary = doc.events.back()
	_check(event.kind == "settle" and event.detail.result.total == result.total, "Committed score is recorded exactly once")
	_check(event.before.hand.size() < event.after.hand.size(), "Settlement preserves pre-refill hand")
	_check(doc.events[0].after.hand == original, "Snapshots are immutable")
	_check(doc.summary.actions.swap.executed == 1 and doc.summary.actions.swap.retained == 0, "Undo excludes refunded operations from retained counts")
	_check(doc.events[4].detail.undo_event == doc.events[3].id, "Undo links to its operation")
	_check(JSON.parse_string(JSON.stringify(doc)) is Dictionary, "Export is valid JSON")
	_check(doc.summary.levels[0].settlements == 1, "Summary counts actual settlements")

func _test_economy() -> void:
	var game = Run.new()
	var log = Recorder.new(game)
	game.start(Rules.TEST_SEED, ["combo"], "test")
	game.place(game.hand[0], Vector2i.ZERO)
	game.score = game.target()
	game.settle()
	game.open_shop()
	var id: String = game.shop.offers[0]
	game.sell("combo")
	game.money = Market.price(id)
	_check(game.buy(0), "Purchase fixture is affordable")
	game.sell(id)
	game.money = game.shop.reroll_cost()
	game.reroll()
	game.advance()
	var doc: Dictionary = log.document()
	_check(doc.mode == "test", "Test runs are marked")
	_check(doc.events.filter(func(e): return e.kind == "shop_open").size() == 1, "Initial shop inventory is recorded")
	var sale: Dictionary = doc.events.filter(func(e): return e.kind == "sell")[0]
	_check(sale.before.phase == "shop" and sale.before.level == 1, "Sale retains shop and cleared level")
	_check(doc.summary.levels.size() == 2, "Started levels include unfinished levels")
	_check(doc.summary.levels[0].income.reward == game_reward(doc), "Reward breakdown is counted once")
	_check(doc.summary.money.purchase == Market.price(id), "Purchase expense is attributed")

func game_reward(doc: Dictionary) -> int:
	return doc.events.filter(func(e): return e.kind == "settle")[0].after.reward.total

func _test_effects() -> void:
	var game = Run.new()
	var log = Recorder.new(game)
	game.start(Rules.TEST_SEED, ["matching", "copy"])
	# A pair uses the same rank across two suits.
	game.hand = [0, Rules.RANKS.size()]
	game.place(game.hand[0], Vector2i.ZERO)
	game.place(game.hand[0], Vector2i.RIGHT)
	game.settle()
	var cats: Dictionary = log.document().summary.cats
	_check(cats.matching.held_settlements == 1 and cats.matching.effective_settlements == 1, "Repeated calculations count as one effective settlement")
	_check(cats.matching.original_effect_rows == 1 and cats.matching.repeat_effect_rows == 1, "Copy calculations are separate from original effects")
	_check(cats.copy.effective_settlements == 1, "Copy itself counts as effective")
	_check(log.document().summary.patterns.pair.settlement_rate == 1.0, "Pattern occurrence uses settlement denominator")
	game.hand = [1]
	game.place(game.hand[0], Vector2i.DOWN)
	game.settle()
	var patterns: Dictionary = log.document().summary.patterns
	_check(patterns.pair.settlements == 2 and patterns.pair.new_groups == 1, "Persistent pair scores twice but is formed once")
	_check(log.document().summary.levels[0].cats.matching.effective_settlements == 2, "Cat activation is available per level")

func _test_lifecycle() -> void:
	var game = Run.new()
	var log = Recorder.new(game)
	var archived: Array = []
	log.archived.connect(func(doc): archived.append(doc))
	game.start(Rules.TEST_SEED)
	var first: String = log.document().run_id
	game.start(Rules.TEST_SEED)
	_check(archived.size() == 1 and archived[0].outcome == "restarted", "Restart preserves previous run")
	_check(log.document().run_id != first, "Runs have distinct identities")
	game.turns_left = 1
	game.place(game.hand[0], Vector2i.ZERO)
	game.settle()
	_check(log.document().outcome == "lost", "Failure is retained")
	_check(log.document().final_state.loss_reason != "", "Loss reason survives export")
	var exported: Dictionary = log.document()
	exported.events.clear()
	_check(not log.document().events.is_empty(), "Consumers cannot mutate the recorder")
	var winner = Run.new()
	var winning_log = Recorder.new(winner)
	winner.start(Rules.TEST_SEED)
	winner.level = Rules.LEVEL_TARGETS.size()
	winner.score = winner.target()
	winner.place(winner.hand[0], Vector2i.ZERO)
	winner.settle()
	_check(winning_log.document().outcome == "won", "Final clear is a win")
	_check(winning_log.document().summary.money.reward == 0, "Final clear creates no reward")

func _test_observer() -> void:
	var observed = Run.new()
	var control = Run.new()
	var log = Recorder.new(observed)
	observed.start(Rules.TEST_SEED, ["combo", "compact"])
	control.start(Rules.TEST_SEED, ["combo", "compact"])
	for game in [observed, control]:
		game.discard(game.hand.slice(0, Rules.MAX_DISCARD))
		game.place(game.hand[0], Vector2i.ZERO)
		game.settle()
		game.open_shop()
	_check(observed.hand == control.hand and observed.deck.rng.state == control.deck.rng.state, "Recording preserves deck randomness")
	_check(observed.shop.offers == control.shop.offers and observed.shop.rng.state == control.shop.rng.state, "Recording preserves shop randomness")
	_check(observed.score == control.score, "Recording preserves scoring")
	observed.reorder_cats(["compact", "combo"])
	var event: Dictionary = log.document().events.back()
	_check(event.before.cats == ["combo", "compact"] and event.after.cats == ["compact", "combo"], "Reordering captures both orders")
	_check(log.document().summary.cats.compact.rule_settlements == 1, "Passive rule presence is separate from numerical activation")

func _test_storage() -> void:
	var game = Run.new()
	var log = Recorder.new(game)
	game.start(Rules.TEST_SEED)
	var directory: String = "/tmp/paws-record-tests-" + log.document().run_id
	_check(Store.save(log.document(), directory) == OK, "Checkpoint can be saved")
	game.place(game.hand[0], Vector2i.ZERO)
	_check(Store.save(log.document(), directory) == OK, "Checkpoint replaces the previous revision")
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(directory.path_join(log.document().run_id + ".json")))
	_check(saved.events.size() == 2 and saved.final_state.board.size() == 1, "Saved file contains the latest immutable state")
	_check(saved.rules_hash == log.document().rules_hash, "Saved rule version matches the run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
