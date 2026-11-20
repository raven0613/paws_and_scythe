extends RefCounted

const Catalog = preload("res://src/configs/cat_cards/cat_catalog.gd")
const Rules = preload("res://src/configs/gameplay/game_rules.gd")
const Layout = preload("res://src/service/cat_card_area/cat_card_layout.gd")

# 每張持有貓牌的效益倍數；上下舖依貓牌區的實際排別，讓上排其他數值類貓牌乘上 upper、下排乘上 lower。
static func potency(ids: Array) -> Dictionary:
	var result := {}
	for id in ids:
		result[id] = 1.0
	var upper := Layout.upper_count(ids.size())
	for source in ids:
		var rows: Dictionary = Catalog.CARDS[source].get("rules", {}).get("row_potency", {})
		if rows.is_empty():
			continue
		for index in ids.size():
			var id: String = ids[index]
			if id != source and Catalog.CARDS[id].stage in Catalog.NUMERIC_STAGES:
				result[id] *= rows.upper if index < upper else rows.lower
	return result

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
