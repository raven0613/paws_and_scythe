extends RefCounted

const Config = preload("res://src/configs/gameplay/game_rules.gd")
const Deck = preload("res://src/service/gameplay/deck.gd")
const Scoring = preload("res://src/service/gameplay/scoring.gd")
const BoardRules = preload("res://src/service/board/board_rules.gd")
const CatLoadout = preload("res://src/service/cat_cards/cat_loadout.gd")
const CatRules = preload("res://src/service/cat_cards/rule_modifiers.gd")
const CatResolver = preload("res://src/service/cat_cards/cat_resolver.gd")
const LevelReward = preload("res://src/service/level_reward/level_reward.gd")
const Shop = preload("res://src/service/shop/shop_state.gd")
const Market = preload("res://src/service/shop/cat_market.gd")
enum Status { PLAYING, LEVEL_CLEARED, WON, LOST }

var cats = CatLoadout.new()
var deck = Deck.new()
var shop = Shop.new()
var money := Config.STARTING_MONEY
# 最近一次過關的獎勵明細，過關時立即入帳，進入下一關時清空。
var reward: Dictionary = {}
var last_draw: Array[Dictionary] = []
var hand: Array = []
var board: Dictionary = {}
var played: Array = []
var history: Array[Dictionary] = []
var level := 1
var score := 0.0
var turns_left := Config.SETTLEMENTS
var discards_left := Config.DISCARDS
var swaps_used := 0
var digs_used := 0
var hand_limit := Config.HAND_LIMIT
var status := Status.PLAYING
var loss_reason := ""

func start(seed_value: int = -1, selected_cats: Array = []) -> void:
	var valid := cats.select(selected_cats)
	assert(valid, "Invalid cat selection")
	if seed_value < 0:
		deck.rng.randomize()
		shop.rng.randomize()
	else:
		deck.rng.seed = seed_value
		shop.rng.seed = seed_value
	level = 1
	money = Config.STARTING_MONEY
	_begin_level()

func _begin_level() -> void:
	cats.begin_level()
	board.clear()
	deck.reset()
	last_draw.clear()
	hand = _draw(hand_limit)
	score = 0
	turns_left = Config.SETTLEMENTS
	discards_left = Config.DISCARDS
	status = Status.PLAYING
	loss_reason = ""
	reward = {}
	_clear_turn()

func target() -> int:
	return Config.LEVEL_TARGETS[level - 1]

func can_settle() -> bool:
	return status == Status.PLAYING and not played.is_empty()

func can_place(card: int, cell: Vector2i) -> bool:
	var cells: Array[Vector2i] = []
	cells.assign(board.keys())
	return can_play() and hand.has(card) and BoardRules.can_place(cells, cell)

# 本次仍有出牌額度且場上未達容量上限時可以出牌。
func can_play() -> bool:
	return status == Status.PLAYING and played.size() < Config.MAX_PLAYS and not is_board_full()

func is_board_full() -> bool:
	return board.size() >= board_limit()

func place(card: int, cell: Vector2i) -> bool:
	if not can_place(card, cell):
		return false
	history.append({"kind": "place", "cell": cell, "card": card, "index": hand.find(card)})
	hand.erase(card)
	board[cell] = card
	played.append(card)
	return true

func swaps_left() -> int:
	return Config.SWAP_COSTS.size() - swaps_used

func digs_left() -> int:
	return Config.DIGS - digs_used

func next_swap_cost() -> int:
	return Config.SWAP_COSTS[swaps_used] if swaps_left() > 0 else 0

func can_swap() -> bool:
	return status == Status.PLAYING and swaps_left() > 0 and board.size() >= 2 and score >= next_swap_cost()

func can_dig() -> bool:
	return status == Status.PLAYING and digs_left() > 0 and not board.is_empty() and score >= Config.DIG_COST

func swap(a: Vector2i, b: Vector2i) -> bool:
	if not can_swap() or a == b or not board.has(a) or not board.has(b):
		return false
	var cost := next_swap_cost()
	history.append({"kind": "swap", "a": a, "b": b, "cost": cost})
	_swap(a, b)
	score -= cost
	swaps_used += 1
	return true

func _swap(a: Vector2i, b: Vector2i) -> void:
	var card: int = board[a]
	board[a] = board[b]
	board[b] = card

func dig(cell: Vector2i) -> bool:
	if not can_dig() or not board.has(cell):
		return false
	history.append({"kind": "dig", "cell": cell, "card": board[cell], "cost": Config.DIG_COST})
	board.erase(cell)
	score -= Config.DIG_COST
	digs_used += 1
	return true

func can_discard(cards: Array) -> bool:
	if status != Status.PLAYING or discards_left == 0 or cards.is_empty() or cards.size() > Config.MAX_DISCARD:
		return false
	var seen := {}
	for card in cards:
		if not hand.has(card) or seen.has(card):
			return false
		seen[card] = true
	return true

func discard(cards: Array) -> bool:
	if not can_discard(cards):
		return false
	deck.discard_pile.append_array(cards)
	last_draw.clear()
	var replacements: Array = _draw(cards.size())
	# 替換原槽位，保留已出牌撤銷時的插入位置與其他手牌順序。
	for i in range(hand.size() - 1, -1, -1):
		if cards.has(hand[i]):
			if replacements.is_empty():
				hand.remove_at(i)
			else:
				hand[i] = replacements.pop_back()
	discards_left -= 1
	return true

func undo() -> bool:
	if status != Status.PLAYING or history.is_empty():
		return false
	var action: Dictionary = history.pop_back()
	match action.kind:
		"place":
			board.erase(action.cell)
			hand.insert(mini(action.index, hand.size()), action.card)
			played.erase(action.card)
		"swap":
			_swap(action.a, action.b)
			score += action.cost
			swaps_used -= 1
		"dig":
			board[action.cell] = action.card
			score += action.cost
			digs_used -= 1
	return true

func reserved_cards() -> Array:
	var result: Array = []
	for action in history:
		if action.kind == "dig":
			result.append(action.card)
	return result

func board_limit() -> int:
	return CatRules.board_limit(cats.ids)

func cat_state() -> Dictionary:
	return {
		"hand_count": hand.size(), "settlements": cats.settlements,
		"swaps": swaps_used, "digs": digs_used,
		"discards_used": Config.DISCARDS - discards_left, "discards_left": discards_left,
		"operations": cats.operations + swaps_used + digs_used,
	}

func preview() -> Dictionary:
	var raw := Scoring.evaluate(board, played, CatRules.extended_min(cats.ids))
	return CatResolver.resolve(raw, board, cats.ids, cat_state())

func settle(snapshot: Dictionary = {}) -> Dictionary:
	if not can_settle():
		return {}
	last_draw.clear()
	var result := preview() if snapshot.is_empty() else snapshot
	cats.commit(swaps_used + digs_used)
	score += result.total
	turns_left -= 1
	# 可撤銷的挖牌在確認後進入可洗回的棄牌堆。
	deck.discard_pile.append_array(reserved_cards())
	_clear_turn()
	if score >= target():
		_clear_level()
	elif turns_left == 0:
		_lose("結算次數已用完")
	else:
		hand.append_array(_draw(hand_limit - hand.size()))
		if hand.is_empty():
			_lose("牌庫耗盡，已無可出的手牌")
		# 每次結算至少要出一張牌；場上已滿時需先挖牌騰出空位，付不起挖牌即無法再結算。
		elif is_board_full() and not can_dig():
			_lose("場上已滿且無法挖牌")
	return result

func _clear_turn() -> void:
	played.clear()
	history.clear()
	swaps_used = 0
	digs_used = 0

func _lose(reason: String) -> void:
	status = Status.LOST
	loss_reason = reason

# 最終關達標結束整場；其餘關卡以過關當下的持有金錢與剩餘結算次數計算獎勵並立即入帳。
func _clear_level() -> void:
	if level == Config.LEVEL_TARGETS.size():
		status = Status.WON
		return
	status = Status.LEVEL_CLEARED
	reward = LevelReward.compute(money, turns_left)
	money += reward.total

func advance() -> bool:
	if status != Status.LEVEL_CLEARED:
		return false
	level += 1
	_begin_level()
	return true

func open_shop() -> void:
	shop.open(cats.ids)

func can_buy(slot: int) -> bool:
	var id: String = shop.offers[slot]
	return status == Status.LEVEL_CLEARED and not id.is_empty() and not cats.is_full() and money >= Market.price(id)

func buy(slot: int) -> bool:
	if not can_buy(slot):
		return false
	money -= Market.price(shop.offers[slot])
	cats.add(shop.take(slot))
	return true

func can_reroll() -> bool:
	return status == Status.LEVEL_CLEARED and money >= shop.reroll_cost()

func reroll() -> bool:
	if not can_reroll():
		return false
	money -= shop.reroll_cost()
	shop.reroll(cats.ids)
	return true

# 操作階段與商店期間都可賣出貓牌；效果隨持有清單即時移除。
func can_sell(id: String) -> bool:
	return status in [Status.PLAYING, Status.LEVEL_CLEARED] and cats.ids.has(id)

func sell(id: String) -> bool:
	if not can_sell(id):
		return false
	cats.remove(id)
	money += Market.sell_price(id)
	return true


func _draw(count: int) -> Array:
	var cards: Array = []
	for i in count:
		var drawn: Array = deck.draw(1)
		if drawn.is_empty():
			break
		cards.append(drawn[0])
		last_draw.append({"card": drawn[0], "remaining": deck.draw_pile.size()})
	return cards
