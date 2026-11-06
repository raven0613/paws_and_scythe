extends RefCounted

const Geometry = preload("res://src/service/cat_cards/board_facts.gd")
const Modifiers = preload("res://src/service/cat_cards/rule_modifiers.gd")
const Cards = preload("res://src/service/gameplay/cards.gd")

# 目標與條件以本次鎖定的牌陣、原始分組及補牌前狀態建立。
static func build(raw: Dictionary, board: Dictionary, state: Dictionary, scoring: Array) -> Dictionary:
	var context := state.duplicate(true)
	context.groups = raw.groups
	context.kinds = {}
	context.scoring = scoring
	context.highest = Modifiers.highest(raw.groups)
	context.scoring_longest = 0
	context.geometry = Geometry.build(board, raw.groups, scoring)
	context.longest = 0
	context.facts = []
	var uses := {}
	for index in scoring:
		var group: Dictionary = raw.groups[index]
		context.scoring_longest = maxi(context.scoring_longest, group.cells.size())
		context.kinds[group.kind] = context.kinds.get(group.kind, 0) + 1
		for cell in group.cells:
			uses[cell] = uses.get(cell, 0) + 1
	for index in raw.groups.size():
		var group: Dictionary = raw.groups[index]
		context.longest = maxi(context.longest, group.cells.size())
		var ranks: Array = []
		var suits: Array = []
		var colors: Array = []
		var crossing := false
		for cell in group.cells:
			var card: int = board[cell]
			ranks.append(Cards.rank(card))
			suits.append(Cards.suit(card))
			colors.append(Cards.is_red(card))
			crossing = crossing or uses.get(cell, 0) > 1
		var consecutive := 0
		var alternating := true
		for i in range(1, colors.size()):
			if ranks[i] == ranks[i - 1]:
				consecutive += 1
			alternating = alternating and colors[i] != colors[i - 1]
		context.facts.append({
			"same_rank": ranks.all(func(rank_value): return rank_value == ranks[0]),
			"same_suit": suits.all(func(suit_value): return suit_value == suits[0]),
			"alternating": alternating, "crossing": crossing, "consecutive": consecutive,
		})
	return context
