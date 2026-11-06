extends SceneTree

const Catalog = preload("res://src/configs/cat_cards/cat_catalog.gd")
const Rules = preload("res://src/configs/gameplay/game_rules.gd")
const Run = preload("res://src/service/gameplay/run_state.gd")
var failures := 0

func _init() -> void:
	_test_loadout_across_levels()
	_test_combo_per_settlement()
	var game = Run.new()
	game.start(Rules.TEST_SEED, ["growth", "peace", "combo"])
	_check(game.place(game.hand[0], Vector2i.ZERO), "Place initial card")
	var preview: Dictionary = game.preview()
	_check(game.cats.settlements == 0, "Preview leaves growth unchanged")
	var result: Dictionary = game.settle(preview)
	_check(game.score == preview.total and result == preview, "Commit the same snapshot used by presentation")
	_check(game.cats.settlements == 1, "Commit increments growth once")
	if game.status == Run.Status.LEVEL_CLEARED:
		game.advance()
		_check(game.cats.settlements == 0 and game.cats.ids == ["growth", "peace", "combo"], "Cross-level reset retains loadout")
	game.start(Rules.TEST_SEED, ["peace", "growth"])
	game.place(game.hand[0], Vector2i.ZERO)
	game.place(game.hand[0], Vector2i.RIGHT)
	game.score = Rules.DIG_COST + Rules.SWAP_COSTS[0]
	var before: Dictionary = game.preview()
	_check(game.dig(Vector2i.RIGHT), "Dig available")
	_check(not game.preview().events.any(func(event): return event.source == "peace"), "Dig removes untouched activation")
	_check(game.undo(), "Undo dig")
	_check(game.preview() == before, "Undo restores all scoring eligibility")
	_check(game.swap(Vector2i.ZERO, Vector2i.RIGHT), "Swap available")
	_check(not game.preview().events.any(func(event): return event.source == "peace"), "Swap removes untouched activation")
	game.undo()
	_check(game.preview() == before, "Undo swap restores exact preview")
	_check(game.cats.reorder(["growth", "peace"]), "Reorder same collection")
	_check(not game.cats.reorder(["copy", "peace"]), "Reorder cannot replace cards")
	game.start(Rules.TEST_SEED)
	_check(game.cats.ids.is_empty() and game.cats.settlements == 0, "New run can select zero cats")
	print("Cat run integration: %d failures" % failures)
	quit(1 if failures else 0)

func _test_loadout_across_levels() -> void:
	var available: Array = Catalog.CARDS.keys()
	for start in available.size():
		var selected: Array = []
		for offset in Catalog.MAX_EQUIPPED:
			selected.append(available[(start + offset) % available.size()])
		var game = Run.new()
		game.start(Rules.TEST_SEED, selected)
		for level in Rules.LEVEL_TARGETS.size():
			_check(game.cats.ids == selected, "Every level preserves all five selected cats and their order")
			selected.reverse()
			_check(game.cats.reorder(selected), "Reordering preserves the equipped collection")
			game.place(game.hand[0], Vector2i.ZERO)
			game.score = game.target()
			game.settle()
			_check(game.cats.ids == selected, "Settlement preserves the reordered loadout")
			if level < Rules.LEVEL_TARGETS.size() - 1:
				_check(game.advance(), "Advance with all selected cats")

func _test_combo_per_settlement() -> void:
	var game = Run.new()
	game.start(Rules.TEST_SEED, ["combo"])
	game.level = Rules.LEVEL_TARGETS.size()
	for turn in Rules.SETTLEMENTS:
		game.place(game.hand[0], Vector2i(turn, 0))
		var result: Dictionary = game.settle()
		_check(result.multiplier == result.original_multiplier + Catalog.CARDS.combo.value, "Combo bonus applies fresh to each settlement")
		_check(result.events.filter(func(e): return e.source == "combo").size() == 1, "Combo cat activates once per settlement")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
