extends SceneTree

const Config = preload("res://src/configs/gameplay/game_rules.gd")
const Run = preload("res://src/service/gameplay/run_state.gd")
const BoardRules = preload("res://src/service/board/board_rules.gd")
var failures := 0

func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = Config.TEST_SEED
	for sample in Config.TEST_SAMPLES:
		var game = Run.new()
		game.start(sample)
		for step in Config.DECK_SIZE * Config.SETTLEMENTS:
			if game.status == Run.Status.LEVEL_CLEARED:
				game.advance()
			elif game.status != Run.Status.PLAYING:
				break
			var cells: Array[Vector2i] = []
			cells.assign(game.board.keys())
			match rng.randi_range(0, 5):
				0:
					if not game.hand.is_empty():
						var places := BoardRules.get_placements(cells)
						game.place(game.hand[rng.randi_range(0, game.hand.size() - 1)], places[rng.randi_range(0, places.size() - 1)])
				1:
					game.discard(game.hand.slice(0, rng.randi_range(1, Config.MAX_DISCARD)))
				2:
					if cells.size() > 1:
						game.swap(cells[0], cells[-1])
				3:
					if not cells.is_empty():
						game.dig(cells[0])
				4:
					game.undo()
				5:
					var before: Dictionary = game.preview()
					var result: Dictionary = game.settle()
					if not result.is_empty():
						_check(before == result, "Preview exactly equals committed report")
			var all: Array = game.hand + game.board.values() + game.deck.draw_pile + game.deck.discard_pile + game.reserved_cards()
			var unique := {}
			for card in all:
				unique[card] = true
			_check(all.size() == Config.DECK_SIZE and unique.size() == Config.DECK_SIZE, "Card conservation under mixed actions")
			_check(game.pending_cost() >= 0 and game.swaps_left() >= 0 and game.digs_left() >= 0, "Fees and quotas remain valid")
			_check(game.hand.size() <= game.hand_limit and game.played.size() <= Config.MAX_PLAYS, "Hand and play limits")
	print("Mixed action invariants: %d seeds, %d failures" % [Config.TEST_SAMPLES, failures])
	quit(1 if failures else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
