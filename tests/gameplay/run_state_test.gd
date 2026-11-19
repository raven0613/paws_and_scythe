extends SceneTree

const Config = preload("res://src/configs/gameplay/game_rules.gd")
const Run = preload("res://src/service/gameplay/run_state.gd")
const Cards = preload("res://src/service/gameplay/cards.gd")
var failures := 0

func _init() -> void:
	var game = Run.new()
	game.start(Config.TEST_SEED)
	_check(game.hand.size() == Config.HAND_LIMIT, "Deal full opening hand")
	_check(game.deck.draw_pile.size() == Config.DECK_SIZE - Config.HAND_LIMIT, "Opening draw removes cards")
	_check(not game.can_settle(), "Require a newly played card")
	_check(game.settle().is_empty(), "Invalid settle preserves turn")
	_check_unique(game)
	var original: Array = game.hand.duplicate()
	_check(game.place(original[0], Vector2i.ZERO), "Place first card")
	_check(not game.place(original[1], Vector2i.ONE), "Reject diagonal placement")
	_check(game.place(original[1], Vector2i.RIGHT), "Place neighbor")
	var funds: int = Config.SWAP_COSTS[0] + Config.DIG_COST
	game.score = funds
	_check(game.swap(Vector2i.ZERO, Vector2i.RIGHT), "Swap")
	_check(game.score == funds - Config.SWAP_COSTS[0], "First swap immediately charges score")
	_check(game.dig(Vector2i.ZERO), "Dig")
	_check(game.score == 0, "Both fees are immediately paid")
	var discarded: int = game.hand[0]
	_check(game.discard([discarded]), "Discard mid-turn")
	var replacement: int = game.hand[0]
	_check(game.undo() and game.board[Vector2i.ZERO] == original[1], "Undo dig restores swapped card")
	_check(game.score == Config.DIG_COST, "Undo dig refunds fee")
	_check(game.undo() and game.board[Vector2i.ZERO] == original[0], "Undo swap restores content")
	_check(game.score == funds, "Undo swap refunds fee")
	_check(game.undo() and game.undo(), "Undo placements")
	_check(game.hand[0] == original[0] and game.hand[1] == original[1] and game.hand[2] == replacement, "Restore hand order while keeping irreversible discard")
	_check(game.discards_left == Config.DISCARDS - 1 and not game.undo(), "Discard stays spent and has no undo record")
	_check_unique(game)
	game.start(Config.TEST_SEED)
	for i in Config.MAX_PLAYS:
		_check(game.place(game.hand[0], Vector2i(i, 0)), "Up to maximum plays")
	var preview: Dictionary = game.preview()
	var report: Dictionary = game.settle()
	_check(report.total == preview.total, "Preview equals settlement")
	_check(game.board.size() == Config.MAX_PLAYS, "Scoring preserves all cards")
	_check(game.hand.size() == Config.HAND_LIMIT, "Refill after settlement")
	_check(game.turns_left == Config.SETTLEMENTS - 1 and game.history.is_empty(), "Settlement consumes turn and commits history")
	_check(game.played.is_empty(), "Fallback eligibility resets")
	_check_unique(game)
	_test_payments()
	_test_limits()
	_test_levels()
	_test_capacity()
	_test_reserved_recycling()
	print("Run state tests: %d failures" % failures)
	quit(1 if failures else 0)

func _test_payments() -> void:
	var game = Run.new()
	game.start(Config.TEST_SEED)
	game.place(game.hand[0], Vector2i.ZERO)
	game.place(game.hand[0], Vector2i.RIGHT)
	var original: Dictionary = game.board.duplicate()
	var history: Array = game.history.duplicate(true)
	_check(not game.can_dig() and not game.can_swap(), "Opening score cannot fund paid actions")
	_check(not game.dig(Vector2i.ZERO) and not game.swap(Vector2i.ZERO, Vector2i.RIGHT), "Core rejects unpaid actions")
	_check(game.board == original and game.history == history and game.score == 0, "Rejected actions leave state untouched")
	_check(game.digs_used == 0 and game.swaps_used == 0, "Rejected actions preserve quotas")
	game.score = Config.DIG_COST - Config.COMBO_STEP
	_check(not game.dig(Vector2i.ZERO), "Affordability uses exact score rather than rounded display")
	game.score = Config.SWAP_COSTS[0] - Config.COMBO_STEP
	_check(not game.swap(Vector2i.ZERO, Vector2i.RIGHT), "Insufficient swap balance is rejected")
	game.score = Config.SWAP_COSTS[0]
	_check(not game.swap(Vector2i.ZERO, Vector2i.ZERO), "Self-swap cannot charge a fee")
	_check(not game.swap(Vector2i.ZERO, Vector2i.DOWN), "Missing swap target cannot charge a fee")
	_check(game.score == Config.SWAP_COSTS[0] and game.history == history, "Invalid targets preserve payment and history")
	_check(game.can_swap() and game.swap(Vector2i.ZERO, Vector2i.RIGHT), "Exact balance funds a swap")
	_check(game.score == 0 and not game.can_swap() and not game.can_dig(), "Spent balance disables paid actions")
	_check(game.undo() and game.score == Config.SWAP_COSTS[0] and game.board == original, "Undo refunds exact swap payment")
	var budget := 0
	for cost in Config.SWAP_COSTS:
		budget += cost
	game.score = budget
	for cost in Config.SWAP_COSTS:
		_check(game.swap(Vector2i.ZERO, Vector2i.RIGHT), "Escalating swaps are paid individually")
		budget -= cost
		_check(game.score == budget, "Each swap charges its configured price")
	for index in range(Config.SWAP_COSTS.size() - 1, -1, -1):
		budget += Config.SWAP_COSTS[index]
		_check(game.undo() and game.score == budget, "Undo refunds each escalating price in reverse order")
	game.score = Config.DIG_COST
	_check(not game.dig(Vector2i.DOWN) and game.score == Config.DIG_COST, "Missing dig target cannot charge a fee")
	_check(game.can_dig() and game.dig(Vector2i.ZERO) and game.score == 0, "Exact balance funds a dig")
	_check(game.undo() and game.score == Config.DIG_COST and game.board == original, "Undo dig restores card and balance")
	game.score = game.target()
	_check(game.dig(Vector2i.ZERO), "Paid dig before settlement")
	var paid_balance: float = game.score
	var preview: Dictionary = game.preview()
	game.settle()
	_check(game.score == paid_balance + preview.total, "Settlement only credits new earnings")
	_check(not game.undo(), "Committed operations cannot refund paid fees")
	game.start(Config.TEST_SEED)
	game.place(game.hand[0], Vector2i.ZERO)
	_check(game.undo() and game.score == 0, "First-turn placement undo remains free")

func _test_limits() -> void:
	var game = Run.new()
	game.hand_limit = Config.MAX_HAND_LIMIT
	game.start(Config.TEST_SEED)
	for i in Config.MAX_PLAYS:
		game.place(game.hand[0], Vector2i(i, 0))
	_check(not game.place(game.hand[0], Vector2i(Config.MAX_PLAYS, 0)), "Play quota enforced with remaining hand cards")
	_check(game.discard([game.hand[0]]), "Discard remains available at play limit")
	_check_unique(game)
	game.hand_limit = Config.HAND_LIMIT
	game.start(Config.TEST_SEED)
	game.place(game.hand[0], Vector2i.ZERO)
	game.place(game.hand[0], Vector2i.RIGHT)
	game.score = Config.DIGS * Config.DIG_COST
	for cost in Config.SWAP_COSTS:
		game.score += cost
	for cost in Config.SWAP_COSTS:
		_check(game.next_swap_cost() == cost, "Escalating swap cost")
		_check(game.swap(Vector2i.ZERO, Vector2i.RIGHT), "Swap within quota")
	_check(not game.swap(Vector2i.ZERO, Vector2i.RIGHT), "Swap quota enforced")
	for cell in game.board.keys():
		_check(game.dig(cell), "Dig within quota")
	_check(game.digs_left() == 0, "Dig quota spent")
	_check_unique(game)
	game.settle()
	_check(game.swaps_left() == Config.SWAP_COSTS.size() and game.digs_left() == Config.DIGS, "Paid quotas reset")
	_check(game.score == 0, "Settlement does not charge already-paid fees again")
	game.start(Config.TEST_SEED)
	_check(not game.discard([]), "Empty discard rejected")
	_check(not game.discard(game.hand.slice(0, Config.MAX_DISCARD + 1)), "Oversized discard rejected")
	for i in Config.DISCARDS:
		_check(game.discard([game.hand[0]]), "Discard within quota")
	_check(not game.discard([game.hand[0]]), "Discard quota enforced")
	_check_unique(game)

func _test_levels() -> void:
	for i in range(1, Config.LEVEL_TARGETS.size()):
		_check(Config.LEVEL_TARGETS[i] > Config.LEVEL_TARGETS[i - 1], "Targets strictly increase")
	var game = Run.new()
	game.start(Config.TEST_SEED)
	game.turns_left = 1
	game.place(game.hand[0], Vector2i.ZERO)
	game.settle()
	_check(game.status == Run.Status.LOST, "Turns exhausted loses")
	game.start(Config.TEST_SEED)
	for level in range(1, Config.LEVEL_TARGETS.size() + 1):
		game.score = game.target()
		game.turns_left = 1
		game.place(game.hand[0], Vector2i.ZERO)
		game.settle()
		if level < Config.LEVEL_TARGETS.size():
			_check(game.status == Run.Status.LEVEL_CLEARED, "Pass takes priority over exhausted turns")
			_check(game.advance(), "Continue to next level")
			_check(game.score == 0 and game.board.is_empty() and game.hand.size() == Config.HAND_LIMIT, "New level resets board and deck")
			_check_unique(game)
		else:
			_check(game.status == Run.Status.WON and not game.advance(), "Final target ends the run")

func _test_capacity() -> void:
	var game := _full_board_game()
	_check(game.board.size() == game.board_limit(), "The last free slot accepts a card")
	_check(not game.can_place(game.hand[0], Vector2i.LEFT), "Full board rejects further placement")
	_check(game.undo() and game.can_place(game.hand[0], Vector2i.RIGHT), "Undo reopens the last slot")
	game.place(game.hand[0], Vector2i.RIGHT)
	game.score = Config.DIG_COST
	_check(game.dig(Vector2i(2, 0)) and game.can_place(game.hand[0], Vector2i(2, 0)), "Digging frees a slot for placement")
	# 結算後滿格：付得起挖牌時繼續，付不起時敗北；達標仍優先判定。
	var cases := [
		{"score": Config.DIG_COST, "status": Run.Status.PLAYING, "message": "Full board continues while a dig is affordable"},
		{"score": Config.DIG_COST - 1, "status": Run.Status.LOST, "message": "Full board without an affordable dig loses"},
		{"score": Config.LEVEL_TARGETS[-1], "status": Run.Status.WON, "message": "Reaching the target takes priority over a full board"},
	]
	for case in cases:
		game = _full_board_game()
		game.score = case.score - game.preview().total
		game.settle()
		_check(game.status == case.status, case.message)
		_check_unique(game)

# 最終關的盤面差一張達上限，再由手牌放入最後一張。
func _full_board_game() -> RefCounted:
	var game = Run.new()
	game.start(Config.TEST_SEED)
	game.level = Config.LEVEL_TARGETS.size()
	for i in Config.BOARD_LIMIT - 1:
		game.board[Vector2i(i * 2, 0)] = game.deck.draw_pile.pop_back()
	game.place(game.hand[0], Vector2i.RIGHT)
	return game

func _test_reserved_recycling() -> void:
	var game = Run.new()
	game.start(Config.TEST_SEED)
	var index := 0
	while not game.deck.draw_pile.is_empty():
		game.board[Vector2i(index, 0)] = game.deck.draw_pile.pop_back()
		index += 1
	game.score = Config.DIG_COST
	var dug: int = game.board[Vector2i.ZERO]
	game.dig(Vector2i.ZERO)
	game.discard(game.hand.slice(0, Config.MAX_DISCARD))
	_check(not game.hand.has(dug), "Recycling excludes reversible dug cards")
	_check(game.undo() and game.board[Vector2i.ZERO] == dug, "Dig restores after discard pile recycled")
	_check_unique(game)

func _check_unique(game) -> void:
	var all: Array = game.hand + game.board.values() + game.deck.draw_pile + game.deck.discard_pile + game.reserved_cards()
	var unique := {}
	for card in all:
		unique[card] = true
	_check(all.size() == Config.DECK_SIZE and unique.size() == Config.DECK_SIZE, "All physical cards exist in exactly one location")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
