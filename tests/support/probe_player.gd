extends RefCounted

const Rules = preload("res://src/configs/gameplay/game_rules.gd")
const Probe = preload("res://src/configs/gameplay/balance_probe_config.gd")
const Run = preload("res://src/service/gameplay/run_state.gd")
const Cards = preload("res://src/service/gameplay/cards.gd")
const BoardRules = preload("res://src/service/board/board_rules.gd")

# 探針玩家：每次結算先棄掉沒有同點數的手牌，再依 PLAYS_BY_TURN 逐張放在含貓牌加成的即時最高分落點。
# 回傳六次結算後各自的累積分數；提早達標後繼續量測相同資源的完整產出。
static func measure(seed_value: int, cats: Array) -> Array:
	var game = Run.new()
	game.start(seed_value, cats)
	game.level = Rules.LEVEL_TARGETS.size()
	var totals: Array = []
	for turn in Probe.PLAYS_BY_TURN.size():
		_discard_unmatched(game)
		for play in Probe.PLAYS_BY_TURN[turn]:
			_place_best(game)
		game.settle()
		totals.append(game.score)
		if game.status == Run.Status.WON:
			game.status = Run.Status.PLAYING
			game.hand.append_array(game.deck.draw(game.hand_limit - game.hand.size()))
	return totals

static func median(values: Array) -> float:
	var sorted := values.duplicate()
	sorted.sort()
	return sorted[sorted.size() / 2]

static func _place_best(game: RefCounted) -> void:
	var cells: Array[Vector2i] = []
	cells.assign(game.board.keys())
	var placements := BoardRules.get_placements(cells)
	var best := -INF
	var best_card := -1
	var best_cell := Vector2i.ZERO
	var hand: Array = game.hand.duplicate()
	for card in hand:
		game.hand.erase(card)
		game.played.append(card)
		for cell in placements:
			game.board[cell] = card
			var value: float = game.preview().total
			game.board.erase(cell)
			if value > best:
				best = value
				best_card = card
				best_cell = cell
		game.played.erase(card)
		game.hand = hand.duplicate()
	if best_card >= 0:
		game.place(best_card, best_cell)

static func _discard_unmatched(game: RefCounted) -> void:
	var discard: Array = []
	for card in game.hand:
		var matches := 0
		for other in game.hand + game.board.values():
			if other != card and Cards.rank(card) == Cards.rank(other):
				matches += 1
		if matches == 0 and discard.size() < Rules.MAX_DISCARD:
			discard.append(card)
	game.discard(discard)
