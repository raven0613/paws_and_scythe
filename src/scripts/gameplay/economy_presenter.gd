extends Node

signal loadout_changed
signal busy_changed(busy: bool)
signal next_level_requested

const ViewConfig = preload("res://src/configs/shop/shop_view_config.gd")
const Market = preload("res://src/service/shop/cat_market.gd")

var shop_open := false
var _game: RefCounted
var _reward: Control
var _shop: Control
var _cats: Control
var _money: Control
var _coins: Control
var _busy := false

func setup(game: RefCounted, reward: Control, shop: Control, cats: Control, money: Control, coins: Control) -> void:
	_game = game
	_reward = reward
	_shop = shop
	_cats = cats
	_money = money
	_coins = coins
	_reward.setup(money, coins)
	_reward.shop_requested.connect(_enter_shop)
	_shop.buy_requested.connect(_buy)
	_shop.reroll_requested.connect(_reroll)
	_shop.next_requested.connect(_leave_shop)
	_cats.sell_requested.connect(_sell)

# 新的一場從起始金錢開始，收起獎勵與商店畫面。
func reset() -> void:
	shop_open = false
	_busy = false
	_reward.hide()
	_shop.hide()
	_coins.clear()
	_raise(false)
	_money.set_money(_game.money)

# 頂部資訊列提升到遮罩上方，金錢從加入獎勵前的金額開始逐列入帳。
func present_reward() -> void:
	_money.z_index = ViewConfig.FRONT_LAYER
	var held: int = _game.money - _game.reward.total
	_money.set_money(held)
	_reward.play(_game.level, _game.score, _game.target(), _game.reward, held)

func _enter_shop() -> void:
	_game.open_shop()
	shop_open = true
	_raise(true)
	_shop.open(_game)
	busy_changed.emit(false)

# 付款金幣從金錢飛進商品格，同時卡片飛向貓牌區的新位置，落地後彈出。
func _buy(slot: int) -> void:
	if _busy or not _game.can_buy(slot):
		return
	var id: String = _game.shop.offers[slot]
	_set_busy(true)
	_game.buy(slot)
	_money.animate_money(_game.money)
	_coins.launch(_money.money_target(), _shop.slot_center(slot), Market.price(id), _ignore_coin)
	loadout_changed.emit()
	var card: Control = _cats.get_card(id)
	card.hide_for_arrival()
	await _shop.play_buy(slot, card.get_global_rect())
	card.play_arrival()
	_shop.refresh(_game)
	_set_busy(false)

func _reroll() -> void:
	var cost: int = _game.shop.reroll_cost()
	if _busy or not _game.reroll():
		return
	_set_busy(true)
	_money.animate_money(_game.money)
	_coins.launch(_money.money_target(), _shop.reroll_center(), cost, _ignore_coin)
	await _shop.play_reroll(_game)
	_set_busy(false)

# 賣出的貓牌彈起消失並噴出金幣，每枚抵達讓金錢推進一段，其餘貓牌接著滑到新位置。
func _sell(id: String) -> void:
	if _busy or not _game.can_sell(id):
		return
	_set_busy(true)
	var previous: Array = _game.cats.ids.duplicate()
	var before: int = _money.money
	var price := Market.sell_price(id)
	_game.sell(id)
	_coins.launch(_cats.get_card(id).get_global_rect().get_center(), _money.money_target(), price, _count_up.bind(before, price))
	await _cats.play_vanish(id)
	loadout_changed.emit()
	_cats.slide_from(previous)
	if shop_open:
		_shop.refresh(_game)
	_set_busy(false)

func _leave_shop() -> void:
	if _busy:
		return
	_set_busy(true)
	await _shop.close()
	shop_open = false
	_busy = false
	_raise(false)
	next_level_requested.emit()

func _count_up(index: int, count: int, before: int, amount: int) -> void:
	_money.animate_money(before + roundi(amount * (index + 1) / float(count)))

func _ignore_coin(_index: int, _count: int) -> void:
	pass

func _set_busy(value: bool) -> void:
	_busy = value
	busy_changed.emit(value)

func _raise(front: bool) -> void:
	for node in [_cats, _money]:
		node.z_index = ViewConfig.FRONT_LAYER if front else 0
