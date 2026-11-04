extends RefCounted

const Config = preload("res://src/configs/gameplay/game_rules.gd")
const Cards = preload("res://src/service/gameplay/cards.gd")

# 回傳連續格子的合法牌型與基礎分，分組器依牌型階級選取。
static func candidates(cards: Array) -> Array:
	var counts := {}
	var same_suit := true
	var card_points := 0
	for card in cards:
		var rank_value := Cards.rank(card)
		card_points += Cards.points(card)
		counts[rank_value] = counts.get(rank_value, 0) + 1
		same_suit = same_suit and Cards.suit(card) == Cards.suit(cards[0])
	var frequencies: Array = counts.values()
	frequencies.sort()
	var kinds: Array = []
	match frequencies:
		[2]: kinds.append("pair")
		[2, 2]: kinds.append("two_pair")
		[3]: kinds.append("three")
		[2, 3]: kinds.append("full_house")
		[4]: kinds.append("four")
	if cards.size() >= Config.EXTENDED_MIN:
		var straight := _is_straight(counts, cards.size())
		if straight:
			kinds.append("straight")
		if same_suit:
			kinds.append("flush")
		if straight and same_suit:
			kinds.append("straight_flush")
	var result: Array = []
	for kind in kinds:
		var bonus: float = Config.HAND_BONUSES[kind]
		if kind in ["straight", "flush", "straight_flush"]:
			bonus *= 1 + (cards.size() - Config.EXTENDED_MIN) * Config.LENGTH_BONUS
		result.append({"kind": kind, "score": bonus + card_points})
	return result

static func _is_straight(counts: Dictionary, length: int) -> bool:
	if counts.size() != length:
		return false
	var rank_count := Config.RANKS.size()
	for start in counts:
		var continuous := true
		for offset in length:
			if not counts.has((start - 1 + offset) % rank_count + 1):
				continuous = false
				break
		if continuous:
			return true
	return false
