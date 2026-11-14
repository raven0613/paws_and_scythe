extends RefCounted

const Catalog = preload("res://src/configs/cat_cards/cat_catalog.gd")
const Modifiers = preload("res://src/service/cat_cards/rule_modifiers.gd")
const Context = preload("res://src/service/cat_cards/effect_context.gd")
const Effects = preload("res://src/service/cat_cards/effect_rules.gd")
const Scoring = preload("res://src/service/gameplay/scoring.gd")

# 純計算：結果及事件共用完整精度，預覽與演出讀取相同快照。
# 事件依演出順序排列：得分資格、高牌保底、各組貓牌加成與額外計分、依序入帳、整次與總分效果。
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
	result.events.append_array(_group_pass(result, context, ids, scoring))
	for index in scoring:
		_append_repeats(result, context, ids, index)
	for index in scoring:
		_award_group(result, context, index)
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

# 逐組貓牌依位置發動，每張讓所有符合的組從目前分數套用；activation 相同的事件屬於同一次發動。
static func _group_pass(result: Dictionary, context: Dictionary, ids: Array, indices: Array) -> Array:
	var current := {}
	for index in indices:
		current[index] = result.groups[index].original_score
	var events: Array = []
	var activation := 0
	for id in ids:
		var effect: Dictionary = Catalog.CARDS[id]
		if effect.stage != "group":
			continue
		var each_group: bool = effect.get("each_group", false)
		var emitted := false
		for index in indices:
			if not Effects.eligible(effect, context, index):
				continue
			var amount := Effects.amount(effect, context, index)
			var after := Effects.apply(current[index], effect, amount)
			if after == current[index]:
				continue
			var event := _event("effect", id, "group", current[index], after, index, effect.op, amount)
			event.activation = activation
			events.append(event)
			current[index] = after
			emitted = true
			if each_group:
				activation += 1
		if emitted and not each_group:
			activation += 1
	for index in indices:
		result.groups[index].score = current[index]
		result.groups[index].total_score += current[index]
	return events

# 額外計分從原始分數獨立重算逐組效果，再累加到該組目前合計。
static func _append_repeats(result: Dictionary, context: Dictionary, ids: Array, index: int) -> void:
	var group: Dictionary = result.groups[index]
	for id in ids:
		var effect: Dictionary = Catalog.CARDS[id]
		if effect.stage != "repeat" or not Effects.eligible(effect, context, index):
			continue
		for repeat_index in int(Effects.amount(effect, context, index)):
			var accumulated: float = group.total_score
			var calculation := _group_pass(result, context, ids, [index])
			var event := _event("repeat", id, "group", accumulated, group.total_score, index, "add", group.score)
			event.calculation = calculation
			result.events.append(event)

# 每個得分組入帳一次，同時推進 Combo 組數與基本倍率。
static func _award_group(result: Dictionary, context: Dictionary, index: int) -> void:
	var group: Dictionary = result.groups[index]
	var before: float = result.subtotal
	result.subtotal += group.total_score
	result.base += group.total_score
	var event := _event("group_award", "", "subtotal", before, result.subtotal, index)
	event.combo_count = context.scoring.find(index) + 1
	event.multiplier = Scoring.combo_multiplier(event.combo_count)
	result.events.append(event)

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
