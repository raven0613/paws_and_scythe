extends SceneTree

const Catalog = preload("res://src/configs/cat_cards/cat_catalog.gd")
const Rules = preload("res://src/configs/gameplay/game_rules.gd")
const Cards = preload("res://src/service/gameplay/cards.gd")
const Scoring = preload("res://src/service/gameplay/scoring.gd")
const Modifiers = preload("res://src/service/cat_cards/rule_modifiers.gd")
const Resolver = preload("res://src/service/cat_cards/cat_resolver.gd")
var failures := 0

func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = Rules.TEST_SEED
	for sample in Rules.TEST_SAMPLES:
		var board := {}
		var deck: Array = range(Rules.DECK_SIZE)
		for i in range(Rules.BOARD_LIMIT - 1):
			var chosen := rng.randi_range(0, deck.size() - 1)
			board[Vector2i(i % Rules.EXTENDED_MIN, i / Rules.EXTENDED_MIN)] = deck.pop_at(chosen)
		var ids: Array = Catalog.CARDS.keys()
		var selected: Array = []
		for i in sample % (Catalog.MAX_EQUIPPED + 1):
			selected.append(ids.pop_at(rng.randi_range(0, ids.size() - 1)))
		var raw := Scoring.evaluate(board, board.values(), Modifiers.extended_min(selected))
		var result := Resolver.resolve(raw, board, selected, {"hand_count": rng.randi_range(0, Rules.HAND_LIMIT), "settlements": sample % Rules.SETTLEMENTS, "operations": sample, "discards_used": sample % Rules.DISCARDS, "discards_left": Rules.DISCARDS - sample % Rules.DISCARDS})
		_replay(result)
		_check_order(result, selected)
		_check(result.combo == result.groups.filter(func(g): return g.scoring).size(), "Combo counts eligible scoring groups")
	_test_shared_activation()
	_test_highest_tie()
	_test_copy_award()
	_test_copy_champion()
	print("Cat event flow: %d failures" % failures)
	quit(1 if failures else 0)

func _replay(result: Dictionary) -> void:
	var totals := {"subtotal": 0.0, "multiplier": result.original_multiplier, "total": 0.0}
	var group_values := {}
	for i in result.groups.size():
		group_values[i] = result.groups[i].original_score
	var awards := {}
	var award_counts := {}
	for event in result.events:
		match event.kind:
			"repeat":
				_check(is_equal_approx(group_values[event.group], event.before), "Repeat preserves the accumulated group score")
				_check(event.op == "add", "Repeat adds its independently calculated score")
				_check(is_equal_approx(event.after, event.before + event.amount), "Repeat continues from the preceding total")
				_check(event.after >= event.before, "Extra scoring increases the group total")
				_verify_calculation(event, result.groups[event.group].original_score)
				group_values[event.group] = event.after
			"combo_apply":
				_check(is_equal_approx(totals.subtotal, event.before), "Combo receives exact subtotal")
				totals.total = totals.subtotal * totals.multiplier
				_check(is_equal_approx(totals.total, event.after), "Combo event follows displayed multiplier")
			"effect":
				var before: float = group_values[event.group] if event.target == "group" else totals[event.target]
				_check(is_equal_approx(before, event.before), "Effect starts from the preceding event value")
				var after: float = before + event.amount if event.op == "add" else before * event.amount
				_check(is_equal_approx(after, event.after), "Effect arithmetic matches its annotation")
				if event.target == "group":
					group_values[event.group] = after
				else:
					totals[event.target] = after
			"group_award":
				award_counts[event.group] = award_counts.get(event.group, 0) + 1
				_check(is_equal_approx(totals.subtotal, event.before), "Group award continues running subtotal")
				totals.subtotal += group_values[event.group]
				awards[event.group] = awards.get(event.group, 0.0) + group_values[event.group]
				_check(is_equal_approx(totals.subtotal, event.after), "Group award equals displayed group score")
			"high":
				var points: float = event.cards.reduce(func(sum, card): return sum + card.points, 0.0)
				_check(is_equal_approx(points, event.after), "High event lists every high card and its points")
				totals.subtotal = event.after
	_check(is_equal_approx(totals.total, result.total), "Replaying events reconstructs exact final score")
	for i in result.groups.size():
		_check(is_equal_approx(awards.get(i, 0.0), result.groups[i].total_score), "Preview group total includes all passes")
		_check(award_counts.get(i, 0) == (1 if result.groups[i].scoring else 0), "Each scoring group awards its complete score exactly once")

# 所有組先完成貓牌加成與額外計分，再依 Combo 清單順序入帳並推進組數。
func _check_order(result: Dictionary, ids: Array) -> void:
	var events: Array = result.events
	var scoring: Array = range(result.groups.size()).filter(func(i): return result.groups[i].scoring)
	var reveals: Array = range(events.size()).filter(func(i): return events[i].kind == "reveal")
	_check(reveals.size() == (1 if not scoring.is_empty() else 0), "Scoring groups are revealed once per settlement")
	for slot in reveals:
		_check(events[slot].groups == scoring, "Reveal lists every scoring group in combo order")
		_check(events.slice(0, slot).all(func(e): return e.kind in ["selection", "high"]), "Reveal follows selection and high cards")
	var row_work: Array = range(events.size()).filter(func(i): return events[i].kind == "repeat" or (events[i].kind == "effect" and events[i].target == "group"))
	var award_slots: Array = range(events.size()).filter(func(i): return events[i].kind == "group_award")
	if not row_work.is_empty() and not award_slots.is_empty():
		_check(row_work.max() < award_slots.min(), "Every group finishes its cats before any award")
	if not award_slots.is_empty():
		_check(award_slots.max() - award_slots.min() == award_slots.size() - 1, "Awards form one consecutive sequence")
	var previous_group := -1
	for slot in award_slots:
		var event: Dictionary = events[slot]
		_check(event.group > previous_group, "Awards follow combo list order")
		previous_group = event.group
		_check(event.combo_count == award_slots.find(slot) + 1, "Each award advances the combo count by one")
		_check(is_equal_approx(event.multiplier, Scoring.combo_multiplier(event.combo_count)), "Award carries the base multiplier of its combo count")
	var effects: Array = events.filter(func(e): return e.kind == "effect" and e.target == "group")
	var last_activation := -1
	var last_position := {true: -1, false: -1}
	var multiplied := false
	var sources := {}
	for event in effects:
		var adds: bool = event.op == "add"
		_check(event.activation >= last_activation, "Activations play in order")
		_check(not (adds and multiplied), "Group additions activate before multiplications")
		_check(ids.find(event.source) >= last_position[adds], "Cats of the same kind activate in equipped order")
		last_activation = event.activation
		last_position[adds] = ids.find(event.source)
		multiplied = multiplied or not adds
		sources[event.source] = sources.get(event.source, []) + [event.activation]
	for id in sources:
		var activations: Array = sources[id]
		_check(activations.all(func(a): return a == activations[0]), "Each group cat activates once for every matching group")

func _test_shared_activation() -> void:
	var board := {Vector2i(0, 0): Cards.id(8, 0), Vector2i(1, 0): Cards.id(8, 1),
		Vector2i(0, 2): Cards.id(5, 0), Vector2i(1, 2): Cards.id(5, 1), Vector2i(2, 2): Cards.id(5, 2)}
	var ids := ["compact", "consecutive"]
	var result := Resolver.resolve(Scoring.evaluate(board, []), board, ids, {})
	_replay(result)
	_check_order(result, ids)
	var compact: Array = result.events.filter(func(e): return e.source == "compact")
	_check(compact.size() == 2 and compact[0].activation == compact[1].activation, "One shared activation scales every matching group together")
	var consecutive: Array = result.events.filter(func(e): return e.source == "consecutive")
	_check(consecutive.size() == 2 and consecutive[0].activation == consecutive[1].activation, "Run bonuses differ per group within one activation")
	_check(consecutive[0].amount != consecutive[1].amount, "Each group keeps its own run bonus")
	_check(consecutive.all(func(e): return e.activation < compact[0].activation), "Later equipped additions activate before earlier multiplications")

func _verify_calculation(event: Dictionary, original: float) -> void:
	_check(event.has("calculation"), "Repeat retains its independent calculation details")
	if not event.has("calculation"):
		return
	var current: float = original
	for step in event.calculation:
		_check(is_equal_approx(step.before, current), "Extra pass starts from original score and follows effect order")
		if step.kind == "effect":
			current = current + step.amount if step.op == "add" else current * step.amount
		_check(is_equal_approx(step.after, current), "Extra pass arithmetic matches its details")
	_check(is_equal_approx(current, event.amount), "Repeat adds exactly one complete extra pass")

func _test_copy_award() -> void:
	var board := {Vector2i.ZERO: Cards.id(8, 0), Vector2i.RIGHT: Cards.id(8, 1)}
	var raw := Scoring.evaluate(board, [])
	for ids in [["matching", "copy", "combo"], ["compact", "matching", "copy"], ["matching", "compact", "copy"]]:
		var result := Resolver.resolve(raw, board, ids, {})
		_replay(result)
		var single_ids: Array = ids.duplicate()
		single_ids.erase("copy")
		var single := Resolver.resolve(raw, board, single_ids, {})
		_check(is_equal_approx(result.total, single.total * (1 + Catalog.CARDS.copy.value)), "Copy recalculates the full group in equipped order")
		var awards: Array = result.events.filter(func(e): return e.kind == "group_award")
		_check(awards.size() == 1, "Copy combines both passes into one award")
		var combo_effects: Array = result.events.filter(func(e): return e.source == "combo")
		_check(combo_effects.size() == (1 if ids.has("combo") else 0), "Settlement effects trigger once across copied passes")
		var repeat_index: int = result.events.find(result.events.filter(func(e): return e.kind == "repeat")[0])
		_check(result.events.slice(repeat_index + 1).all(func(e): return e.kind != "effect" or e.target != "group"), "Extra scoring keeps the existing group without restarting it")
		for id in single_ids:
			_check(result.events.filter(func(e): return e.source == id).size() == single.events.filter(func(e): return e.source == id).size(), "Copy presents other cats once")

func _test_copy_champion() -> void:
	var ids := ["strays", "champion", "solo", "single_length", "copy"]
	for ranks in [[4, 4, 5, 5], [8, 8], [3, 4, 5, 6, 7], [9, 9, 9, 4, 4]]:
		var board := {}
		for i in ranks.size():
			board[Vector2i(i, 0)] = Cards.id(ranks[i], i % Rules.SUITS.size())
		# A separated card also exercises the fractional strays multiplier.
		board[Vector2i(0, 2)] = Cards.id(1, 0)
		var raw := Scoring.evaluate(board, [])
		var result := Resolver.resolve(raw, board, ids, {})
		var single := Resolver.resolve(raw, board, ids.slice(0, -1), {})
		_replay(result)
		_check(is_equal_approx(result.total, single.total * (1 + Catalog.CARDS.copy.value)), "Champion build copies the full score for different hands")
		_check(result.combo == single.combo, "Extra pass preserves combo count")
		var repeats: Array = result.events.filter(func(e): return e.kind == "repeat")
		_check(repeats.size() == int(Catalog.CARDS.copy.value), "Copy emits one accumulation event per extra pass")

func _test_highest_tie() -> void:
	var board := {Vector2i(0, 0): Cards.id(8, 0), Vector2i(1, 0): Cards.id(8, 1),
		Vector2i(0, 2): Cards.id(8, 2), Vector2i(1, 2): Cards.id(8, 3)}
	var result := Resolver.resolve(Scoring.evaluate(board, []), board, ["reserve"], {"hand_count": Rules.HAND_LIMIT})
	var effects: Array = result.events.filter(func(e): return e.source == "reserve")
	_check(effects.size() == 1 and effects[0].group == 0, "Highest-score tie selects first group once")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
