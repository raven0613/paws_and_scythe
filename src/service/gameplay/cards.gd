extends RefCounted

const Config = preload("res://src/configs/gameplay/game_rules.gd")

static func id(rank_value: int, suit_value: int) -> int:
	return suit_value * Config.RANKS.size() + rank_value - 1

static func rank(card: int) -> int:
	return card % Config.RANKS.size() + 1

static func points(card: int) -> int:
	return Config.RANK_POINTS[rank(card) - 1]

static func suit(card: int) -> int:
	return card / Config.RANKS.size()

static func caption(card: int) -> String:
	return Config.SUIT_NAMES[suit(card)] + Config.RANKS[rank(card) - 1]
