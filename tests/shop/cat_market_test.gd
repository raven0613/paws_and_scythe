extends SceneTree

const Config = preload("res://src/configs/shop/shop_config.gd")
const Rules = preload("res://src/configs/gameplay/game_rules.gd")
const Catalog = preload("res://src/configs/cat_cards/cat_catalog.gd")
const Market = preload("res://src/service/shop/cat_market.gd")
const SAMPLES = 6000
const TOLERANCE = 0.025
var failures := 0

func _init() -> void:
	_test_prices()
	_test_fallback()
	_test_exclusions()
	_test_distribution()
	print("Cat market tests: %d failures" % failures)
	quit(1 if failures else 0)

func _test_prices() -> void:
	for id in Catalog.CARDS:
		_check(Config.CAT_PRICES.has(id), "Every cat has a purchase price: %s" % id)
		_check(Market.sell_price(id) == Config.SELL_PRICES[Catalog.CARDS[id].rarity], "Sell price follows rarity: %s" % id)
		_check(Market.sell_price(id) < Market.price(id), "Selling returns less than buying: %s" % id)
	for rarity in Config.RARITY_ORDER:
		_check(Config.RARITY_WEIGHTS.has(rarity) and Config.SELL_PRICES.has(rarity), "Every rarity has a weight and sell price")

func _test_fallback() -> void:
	_check(Market.fallback("R") == ["R", "SR", "SSR"], "Lowest rarity falls back upward")
	_check(Market.fallback("SR") == ["SR", "R", "SSR"], "Middle rarity falls back downward first")
	_check(Market.fallback("SSR") == ["SSR", "SR", "R"], "Highest rarity falls back downward")

func _test_exclusions() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = Rules.TEST_SEED
	var owned: Array = Catalog.CARDS.keys().slice(0, Catalog.MAX_EQUIPPED)
	for sample in Rules.TEST_SAMPLES:
		var offers := Market.roll(rng, owned, Config.CAT_SLOTS)
		_check(offers.size() == Config.CAT_SLOTS, "Roll fills every slot")
		_check(offers.all(func(id): return not owned.has(id)), "Owned cats are not offered")
		_check(offers[0] != offers[1], "Slots offer different cats")
	var all_but_one: Array = Catalog.CARDS.keys().slice(1)
	var scarce := Market.roll(rng, all_but_one, Config.CAT_SLOTS)
	_check(scarce == [Catalog.CARDS.keys()[0], ""], "Slots stay empty once every cat is owned or shown")
	var first := RandomNumberGenerator.new()
	var second := RandomNumberGenerator.new()
	first.seed = Rules.TEST_SEED
	second.seed = Rules.TEST_SEED
	_check(Market.roll(first, [], Config.CAT_SLOTS) == Market.roll(second, [], Config.CAT_SLOTS), "Rolls are reproducible from the seed")

func _test_distribution() -> void:
	var total_weight := 0
	for rarity in Config.RARITY_ORDER:
		total_weight += Config.RARITY_WEIGHTS[rarity]
	var counts := _rarity_counts([])
	for rarity in Config.RARITY_ORDER:
		var expected := float(Config.RARITY_WEIGHTS[rarity]) / total_weight
		_check(absf(counts[rarity] / float(SAMPLES) - expected) < TOLERANCE, "First slot follows the %s weight" % rarity)
	var top: String = Config.RARITY_ORDER[-1]
	var owned_top: Array = Catalog.CARDS.keys().filter(func(id): return Catalog.CARDS[id].rarity == top)
	var fallback_counts := _rarity_counts(owned_top)
	var below: String = Config.RARITY_ORDER[-2]
	var expected_below := float(Config.RARITY_WEIGHTS[below] + Config.RARITY_WEIGHTS[top]) / total_weight
	_check(fallback_counts[top] == 0, "Owned top-rarity cats leave that rarity empty")
	_check(absf(fallback_counts[below] / float(SAMPLES) - expected_below) < TOLERANCE, "Empty top rarity falls back to the next rarity")

func _rarity_counts(owned: Array) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = Rules.TEST_SEED
	var counts := {}
	for rarity in Config.RARITY_ORDER:
		counts[rarity] = 0
	for sample in SAMPLES:
		var id: String = Market.roll(rng, owned, 1)[0]
		counts[Catalog.CARDS[id].rarity] += 1
	return counts

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
