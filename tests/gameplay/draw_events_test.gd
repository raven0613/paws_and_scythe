extends SceneTree

const Config = preload("res://src/configs/gameplay/game_rules.gd")
const Run = preload("res://src/service/gameplay/run_state.gd")
var failures := 0

func _init() -> void:
	var game = Run.new()
	game.start(Config.TEST_SEED)
	_check(game.money == Config.STARTING_MONEY, "New runs use configured starting money")
	_check(game.last_draw.size() == Config.HAND_LIMIT, "Opening draw records every dealt card")
	_check_draw(game)
	for index in game.last_draw.size():
		_check(game.last_draw[index].remaining == Config.DECK_SIZE - index - 1, "Draw events record actual remaining deck count")
	game.place(game.hand[0], Vector2i.ZERO)
	game.place(game.hand[0], Vector2i.RIGHT)
	game.swap(Vector2i.ZERO, Vector2i.RIGHT)
	game.dig(Vector2i.RIGHT)
	game.settle()
	_check(game.money == Config.STARTING_MONEY, "Paid board operations consume score, preserving money")
	_check(game.last_draw.size() == 2, "Settlement only records refill cards")
	_check_draw(game)
	game.discard(game.hand.slice(0, Config.MAX_DISCARD))
	_check(game.last_draw.size() == Config.MAX_DISCARD, "Discard records replacement cards")
	_check_draw(game)
	game.score = game.target()
	game.place(game.hand[0], Vector2i.RIGHT)
	game.settle()
	_check(game.last_draw.is_empty(), "Level completion has no premature refill")
	game.money += Config.STARTING_MONEY
	var carried: int = game.money
	_check(game.advance() and game.money == carried, "Money carries across levels")
	_check(game.last_draw.size() == Config.HAND_LIMIT, "Next level records a fresh opening deal")
	game.start(Config.TEST_SEED)
	_check(game.money == Config.STARTING_MONEY, "Restart resets money")
	# 抽牌堆耗盡時，棄掉的牌會成為唯一補抽來源；ID 相同仍是一次實際抽牌。
	var cell := 0
	while not game.deck.draw_pile.is_empty():
		game.board[Vector2i(cell, 0)] = game.deck.draw_pile.pop_back()
		cell += 1
	var discarded: int = game.hand[0]
	game.discard([discarded])
	_check(game.last_draw.size() == 1 and game.last_draw[0].card == discarded, "Recycled same-ID draws still produce an event")
	_check(game.last_draw[0].remaining == 0, "Recycling reports remaining draw pile")
	_check_draw(game)
	print("Money and draw event tests: %d failures" % failures)
	quit(1 if failures else 0)

func _check_draw(game: RefCounted) -> void:
	var seen := {}
	for event in game.last_draw:
		_check(game.hand.has(event.card), "Every drawn card reaches the hand")
		_check(not seen.has(event.card), "Draw events contain unique physical cards")
		seen[event.card] = true
	if not game.last_draw.is_empty():
		_check(game.last_draw.back().remaining == game.deck.draw_pile.size(), "Final event agrees with actual deck count")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
