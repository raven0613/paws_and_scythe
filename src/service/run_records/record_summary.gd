extends RefCounted

const Rules = preload("res://src/configs/gameplay/game_rules.gd")
const Catalog = preload("res://src/configs/cat_cards/cat_catalog.gd")

static func build(events: Array) -> Dictionary:
	var result := {"settlements": 0, "levels": [], "patterns": {}, "cats": {},
		"actions": {}, "money": {"initial": 0, "reward": 0, "sale": 0, "purchase": 0, "reroll": 0}}
	var levels := {}
	var seen_groups := {}
	for kind in Rules.HAND_NAMES:
		result.patterns[kind] = {"settlements": 0, "scoring_settlements": 0, "levels": 0,
			"valid_groups": 0, "scoring_groups": 0, "new_groups": 0}
	for id in Catalog.CARDS:
		result.cats[id] = _cat_stats()
	for event in events:
		var level: int = event.after.level if event.kind in ["start", "advance"] else event.before.level
		if not levels.has(level):
			levels[level] = {"level": level, "target": event.after.target, "settlements": 0,
				"gross_score": 0.0, "score_cost": 0.0, "score_refund": 0.0,
				"score": 0.0, "status": "playing", "patterns": [], "settlement_scores": [],
				"cats_start": event.after.cats, "cats_end": event.after.cats, "cats": {}, "actions": {},
				"income": {"reward": 0, "sale": 0, "components": {}}, "expenses": {"purchase": 0, "reroll": 0}}
		var row: Dictionary = levels[level]
		row.score = event.after.score
		row.status = event.after.status
		row.cats_end = event.after.cats
		if event.kind in ["place", "swap", "dig", "discard", "undo"]:
			_action(result.actions, event.kind, 1, 1)
			_action(row.actions, event.kind, 1, 1)
		if event.kind in ["swap", "dig"]:
			row.score_cost += event.detail.cost
		if event.kind == "undo":
			_action(result.actions, event.detail.action.kind, 0, -1)
			_action(row.actions, event.detail.action.kind, 0, -1)
			row.score_refund += event.detail.action.get("cost", 0)
		_money(result.money, row, event)
		if event.kind == "settle":
			result.settlements += 1
			row.settlements += 1
			row.gross_score += event.detail.result.total
			row.settlement_scores.append({"event": event.id, "earned": event.detail.result.total,
				"before": event.before.score, "after": event.after.score, "target": event.before.target})
			_patterns(result.patterns, row, event, seen_groups)
			_cats(result.cats, event)
			_cats(row.cats, event)
	for row in levels.values():
		row.target_ratio = row.score / row.target
		row.deficit = maxf(0, row.target - row.score)
		for stats in row.cats.values():
			stats.effective_rate = _rate(stats.effective_settlements, stats.held_settlements)
		result.levels.append(row)
	for stats in result.patterns.values():
		stats.settlement_rate = _rate(stats.settlements, result.settlements)
		stats.scoring_settlement_rate = _rate(stats.scoring_settlements, result.settlements)
		stats.level_rate = _rate(stats.levels, levels.size())
	for stats in result.cats.values():
		stats.effective_rate = _rate(stats.effective_settlements, stats.held_settlements)
	return result

static func _action(actions: Dictionary, kind: String, executed: int, retained: int) -> void:
	if not actions.has(kind):
		actions[kind] = {"executed": 0, "retained": 0}
	actions[kind].executed += executed
	actions[kind].retained += retained

static func _money(totals: Dictionary, row: Dictionary, event: Dictionary) -> void:
	match event.kind:
		"start": totals.initial = event.after.money
		"sell":
			totals.sale += event.detail.income
			row.income.sale += event.detail.income
		"buy":
			totals.purchase += event.detail.cost
			row.expenses.purchase += event.detail.cost
		"reroll":
			totals.reroll += event.detail.cost
			row.expenses.reroll += event.detail.cost
		"settle":
			for entry in event.after.reward.get("entries", []):
				totals.reward += entry.amount
				row.income.reward += entry.amount
				row.income.components[entry.kind] = row.income.components.get(entry.kind, 0) + entry.amount

static func _patterns(patterns: Dictionary, row: Dictionary, event: Dictionary, seen: Dictionary) -> void:
	var present := {}
	var scored := {}
	for group in event.detail.result.groups:
		present[group.kind] = true
		patterns[group.kind].valid_groups += 1
		if group.scoring:
			patterns[group.kind].scoring_groups += 1
			scored[group.kind] = true
		var key: String = str(row.level) + ":" + group.fingerprint
		if not seen.has(key):
			seen[key] = true
			patterns[group.kind].new_groups += 1
	if event.detail.result.high > 0:
		present.high = true
		scored.high = true
	for kind in scored:
		patterns[kind].scoring_settlements += 1
	for kind in present:
		patterns[kind].settlements += 1
		if not row.patterns.has(kind):
			row.patterns.append(kind)
			patterns[kind].levels += 1

static func _cats(cats: Dictionary, event: Dictionary) -> void:
	var active := {}
	for id in event.before.cats:
		if not cats.has(id):
			cats[id] = _cat_stats()
		cats[id].held_settlements += 1
		if event.before.rule_modifiers.has(id):
			cats[id].rule_settlements += 1
	_effects(cats, event.detail.result.events, active, false)
	for id in active:
		cats[id].effective_settlements += 1

static func _effects(cats: Dictionary, events: Array, active: Dictionary, repeated: bool) -> void:
	for event in events:
		if event.kind in ["effect", "repeat"] and event.source != "":
			active[event.source] = true
			var key := "repeat_effect_rows" if repeated else "original_effect_rows"
			cats[event.source][key] += 1
		if event.has("calculation"):
			_effects(cats, event.calculation, active, true)

static func _rate(numerator: int, denominator: int) -> Variant:
	return float(numerator) / denominator if denominator > 0 else null

static func _cat_stats() -> Dictionary:
	return {"held_settlements": 0, "effective_settlements": 0,
		"original_effect_rows": 0, "repeat_effect_rows": 0, "rule_settlements": 0}
