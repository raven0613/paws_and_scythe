extends SceneTree

const Config = preload("res://src/configs/shop/shop_config.gd")
const Rules = preload("res://src/configs/gameplay/game_rules.gd")
const Catalog = preload("res://src/configs/cat_cards/cat_catalog.gd")
const Market = preload("res://src/service/shop/cat_market.gd")
const Run = preload("res://src/service/gameplay/run_state.gd")
const RICH = 1000
var failures := 0

func _init() -> void:
	_test_open()
	_test_reroll()
	_test_buy()
	_test_capacity()
	_test_sell()
	print("Shop flow tests: %d failures" % failures)
	quit(1 if failures else 0)

func _test_open() -> void:
	var game := _cleared_run([])
	game.open_shop()
	_check(game.shop.offers.size() == Config.CAT_SLOTS, "Opening the shop stocks every cat slot")
	_check(game.shop.reroll_cost() == Config.REROLL_BASE, "Reroll starts at the base cost")
	var owned := _cleared_run(Catalog.CARDS.keys().slice(0, Catalog.MAX_EQUIPPED))
	owned.open_shop()
	_check(owned.shop.offers.all(func(id): return not owned.cats.ids.has(id)), "Owned cats stay off the shelf")

func _test_reroll() -> void:
	var game := _cleared_run([])
	game.money = RICH
	game.open_shop()
	for step in 3:
		var cost: int = Config.REROLL_BASE + step * Config.REROLL_STEP
		_check(game.shop.reroll_cost() == cost, "Each reroll raises the cost by the step")
		var before: int = game.money
		_check(game.reroll() and game.money == before - cost, "Reroll pays the current cost")
		_check(game.shop.offers.size() == Config.CAT_SLOTS, "Reroll restocks the cat slots")
	game.open_shop()
	_check(game.shop.reroll_cost() == Config.REROLL_BASE, "Entering the shop resets the reroll cost")
	game.money = Config.REROLL_BASE - 1
	_check(not game.reroll() and game.money == Config.REROLL_BASE - 1, "Reroll needs enough money")

func _test_buy() -> void:
	var game := _cleared_run([])
	game.money = RICH
	game.open_shop()
	var id: String = game.shop.offers[0]
	_check(game.buy(0), "Affordable offer can be bought")
	_check(game.money == RICH - Market.price(id), "Buying pays the cat price")
	_check(game.cats.ids == [id] and game.shop.offers[0] == "", "Bought cat joins the loadout and leaves an empty slot")
	_check(not game.buy(0), "Empty slot cannot be bought")
	game.money = Market.price(game.shop.offers[1]) - 1
	_check(not game.buy(1), "Buying needs enough money")
	var playing = Run.new()
	playing.start(Rules.TEST_SEED, [])
	playing.money = RICH
	playing.open_shop()
	_check(not playing.buy(0), "The shop only sells after clearing a level")

func _test_capacity() -> void:
	var full: Array = Catalog.CARDS.keys().slice(0, Catalog.MAX_EQUIPPED)
	var game := _cleared_run(full)
	game.money = RICH
	game.open_shop()
	_check(game.cats.is_full() and not game.can_buy(0), "A full loadout blocks buying")
	var offer: String = game.shop.offers[0]
	game.sell(full[0])
	_check(game.buy(0) and game.cats.ids.back() == offer, "Selling frees a slot for a purchase at the end")

func _test_sell() -> void:
	var game = Run.new()
	game.start(Rules.TEST_SEED, ["compact", "industry"])
	_check(game.board_limit() < Rules.BOARD_LIMIT, "Compact cat lowers the board limit")
	game.place(game.hand[0], Vector2i.ZERO)
	game.place(game.hand[0], Vector2i.RIGHT)
	game.score = Rules.SWAP_COSTS[0]
	game.swap(Vector2i.ZERO, Vector2i.RIGHT)
	game.settle()
	var operations: int = game.cats.operations
	var before: int = game.money
	_check(game.sell("compact"), "Cats can be sold during play")
	_check(game.money == before + Market.sell_price("compact"), "Selling pays the rarity sell price")
	_check(game.cats.ids == ["industry"] and game.board_limit() == Rules.BOARD_LIMIT, "Selling removes the cat and its effect")
	_check(not game.sell("compact"), "Unowned cats cannot be sold")
	game.sell("industry")
	game.money = RICH
	game.status = Run.Status.LEVEL_CLEARED
	game.open_shop()
	game.shop.offers[0] = "industry"
	game.buy(0)
	_check(game.cats.operations == operations, "Rebuying keeps the run-wide operation count for retroactive cats")
	game.status = Run.Status.LOST
	_check(not game.sell("industry"), "Finished runs cannot sell")

func _cleared_run(cats: Array) -> RefCounted:
	var game = Run.new()
	game.start(Rules.TEST_SEED, cats)
	game.score = game.target()
	game.place(game.hand[0], Vector2i.ZERO)
	game.settle()
	return game

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
