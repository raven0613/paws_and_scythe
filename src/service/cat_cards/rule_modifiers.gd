extends RefCounted

const Catalog = preload("res://src/configs/cat_cards/cat_catalog.gd")
const Rules = preload("res://src/configs/gameplay/game_rules.gd")

static func extended_min(ids: Array) -> int:
	var minimum: int = Rules.EXTENDED_MIN
	for id in ids:
		minimum = maxi(minimum, Catalog.CARDS[id].get("rules", {}).get("extended_min", minimum))
	return minimum

static func board_limit(ids: Array) -> int:
	var limit: int = Rules.BOARD_LIMIT
	for id in ids:
		limit += Catalog.CARDS[id].get("rules", {}).get("capacity_delta", 0)
	return limit

static func selection_source(ids: Array) -> String:
	for id in ids:
		if Catalog.CARDS[id].get("rules", {}).get("selection") == "highest":
			return id
	return ""

static func highest(groups: Array) -> int:
	var index := -1
	var best := -INF
	for i in groups.size():
		if groups[i].score > best:
			best = groups[i].score
			index = i
	return index
