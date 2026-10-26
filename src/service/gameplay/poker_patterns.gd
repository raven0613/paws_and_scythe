extends RefCounted

const Config = preload("res://src/configs/gameplay/game_rules.gd")
const Cards = preload("res://src/service/gameplay/cards.gd")

# 回傳連續格子中全部合法牌型，供分組器比較總基礎分。
static func candidates(cards: Array) -> Array:
	var counts := {}
	var same_suit := true
	for card in cards:
		var rank_value := Cards.rank(card)
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
	kinds.sort_custom(func(a, b): return Config.HAND_ORDER.find(a) < Config.HAND_ORDER.find(b))
	var result: Array = []
	for kind in kinds:
		var score: float = Config.SCORES[kind]
		if kind in ["straight", "flush", "straight_flush"]:
			score *= 1 + (cards.size() - Config.EXTENDED_MIN) * Config.LENGTH_BONUS
		result.append({"kind": kind, "score": score})
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
