extends RefCounted

const Catalog = preload("res://src/configs/cat_cards/cat_catalog.gd")
const Modifiers = preload("res://src/service/cat_cards/rule_modifiers.gd")
const Context = preload("res://src/service/cat_cards/effect_context.gd")
const Effects = preload("res://src/service/cat_cards/effect_rules.gd")
const Scoring = preload("res://src/service/gameplay/scoring.gd")

# 純計算：結果及事件共用完整精度，預覽與演出讀取相同快照。
static func resolve(raw: Dictionary, board: Dictionary, ids: Array, state: Dictionary) -> Dictionary:
	var result: Dictionary = raw.duplicate(true)
	var selection := Modifiers.selection_source(ids)
	var scoring: Array = range(raw.groups.size())
	if not selection.is_empty() and not scoring.is_empty():
		scoring = [Modifiers.highest(raw.groups)]
	var context := Context.build(raw, board, state, scoring)
	result.events = []
	result.subtotal = raw.high
	result.base = 0.0
	result.combo = scoring.size()
	result.multiplier = Scoring.combo_multiplier(result.combo)
	result.original_multiplier = result.multiplier
	if not selection.is_empty() and not scoring.is_empty():
		var event := _event("selection", selection, "group", 0, 0, context.highest)
		event.excluded = []
		for index in raw.groups.size():
			if not scoring.has(index):
				event.excluded.append(index)
		result.events.append(event)
	if raw.high > 0:
		result.events.append(_event("high", "", "subtotal", 0, raw.high))
	for index in result.groups.size():
		var group: Dictionary = result.groups[index]
		group.original_score = raw.groups[index].score
		group.total_score = 0.0
		group.scoring = scoring.has(index)
		group.excluded_by = "" if group.scoring else selection
		if not group.scoring:
			group.score = 0.0
			continue
		result.events.append_array(_group_pass(result, context, ids, index))
		for id in ids:
			var effect: Dictionary = Catalog.CARDS[id]
			if effect.stage != "repeat" or not Effects.eligible(effect, context, index):
				continue
			var repeat_count := int(Effects.amount(effect, context, index))
			for repeat_index in repeat_count:
				var accumulated: float = group.total_score
				var calculation := _group_pass(result, context, ids, index)
				var event := _event("repeat", id, "group", accumulated, group.total_score, index, "add", group.score)
				event.calculation = calculation
				result.events.append(event)
		_award_group(result, index)
	for id in ids:
		var effect: Dictionary = Catalog.CARDS[id]
		if effect.stage == "settlement" and Effects.eligible(effect, context, -1):
			_apply_global(result, effect, context, id)
	var before: float = result.subtotal
	result.total = before * result.multiplier
	result.events.append(_event("combo_apply", "", "total", before, result.total, -1, "multiply", result.multiplier))
	for id in ids:
		var effect: Dictionary = Catalog.CARDS[id]
		if effect.stage == "final" and Effects.eligible(effect, context, -1):
			_apply_global(result, effect, context, id)
	return result

static func _group_pass(result: Dictionary, context: Dictionary, ids: Array, index: int) -> Array:
	var group: Dictionary = result.groups[index]
	var current: float = group.original_score
	var start := _event("group_start", "", "group", current, current, index)
	start.combo_count = context.scoring.find(index) + 1
	start.multiplier = Scoring.combo_multiplier(start.combo_count)
	var events: Array = [start]
	for id in ids:
		var effect: Dictionary = Catalog.CARDS[id]
		if effect.stage != "group" or not Effects.eligible(effect, context, index):
			continue
		var amount := Effects.amount(effect, context, index)
		var after := Effects.apply(current, effect, amount)
		if after == current:
			continue
		events.append(_event("effect", id, "group", current, after, index, effect.op, amount))
		current = after
	group.score = current
	group.total_score += current
	return events

static func _award_group(result: Dictionary, index: int) -> void:
	var group: Dictionary = result.groups[index]
	var before: float = result.subtotal
	result.subtotal += group.total_score
	result.base += group.total_score
	result.events.append(_event("group_award", "", "subtotal", before, result.subtotal, index))

static func _apply_global(result: Dictionary, effect: Dictionary, context: Dictionary, id: String) -> void:
	var before: float = result[effect.target]
	var amount := Effects.amount(effect, context, -1)
	var after := Effects.apply(before, effect, amount)
	if before == after:
		return
	result[effect.target] = after
	result.events.append(_event("effect", id, effect.target, before, after, -1, effect.op, amount))

static func _event(kind: String, source: String, target: String, before: float, after: float, group := -1, op := "", amount := 0.0) -> Dictionary:
	return {"kind": kind, "source": source, "target": target, "before": before,
		"after": after, "group": group, "op": op, "amount": amount}
