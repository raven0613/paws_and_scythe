extends RefCounted

const Config = preload("res://src/configs/shop/shop_config.gd")
const Market = preload("res://src/service/shop/cat_market.gd")

var rng := RandomNumberGenerator.new()
# 每格為上架的貓牌 ID，已買走的格子為空字串並維持到重骰。
var offers: Array = []
var rerolls := 0

# 每次進入商店重置重骰費用並重新上架貓牌。
func open(owned: Array) -> void:
	rerolls = 0
	offers = Market.roll(rng, owned, Config.CAT_SLOTS)

func reroll_cost() -> int:
	return Config.REROLL_BASE + rerolls * Config.REROLL_STEP

func reroll(owned: Array) -> void:
	rerolls += 1
	offers = Market.roll(rng, owned, Config.CAT_SLOTS)

func take(slot: int) -> String:
	var id: String = offers[slot]
	offers[slot] = ""
	return id
