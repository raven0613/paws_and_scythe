extends RefCounted

const Catalog = preload("res://src/configs/cat_cards/cat_catalog.gd")
const Config = preload("res://src/configs/shop/shop_config.gd")

static func price(id: String) -> int:
	return Config.CAT_PRICES[id]

static func sell_price(id: String) -> int:
	return Config.SELL_PRICES[Catalog.CARDS[id].rarity]

# 每格獨立抽稀有度，從尚未持有、也未在前面格子上架的貓牌中等機率選出；沒有可上架的貓牌時該格為空字串。
static func roll(rng: RandomNumberGenerator, owned: Array, count: int) -> Array:
	var offers: Array = []
	for slot in count:
		offers.append(_pick(rng, owned + offers))
	return offers

# 抽中的稀有度沒有可上架的貓牌時，先往低稀有度、再往高稀有度遞補。
static func fallback(rarity: String) -> Array:
	var index: int = Config.RARITY_ORDER.find(rarity)
	var lower: Array = Config.RARITY_ORDER.slice(0, index + 1)
	lower.reverse()
	return lower + Config.RARITY_ORDER.slice(index + 1)

static func _pick(rng: RandomNumberGenerator, excluded: Array) -> String:
	for rarity in fallback(_roll_rarity(rng)):
		var pool: Array = Catalog.CARDS.keys().filter(func(id): return Catalog.CARDS[id].rarity == rarity and not excluded.has(id))
		if not pool.is_empty():
			return pool[rng.randi_range(0, pool.size() - 1)]
	return ""

static func _roll_rarity(rng: RandomNumberGenerator) -> String:
	var total := 0
	for rarity in Config.RARITY_ORDER:
		total += Config.RARITY_WEIGHTS[rarity]
	var pick := rng.randi_range(1, total)
	for rarity in Config.RARITY_ORDER:
		pick -= Config.RARITY_WEIGHTS[rarity]
		if pick <= 0:
			return rarity
	return Config.RARITY_ORDER[-1]
