extends SceneTree

const Config = preload("res://src/configs/gameplay/game_rules.gd")
const Probe = preload("res://src/configs/gameplay/balance_probe_config.gd")
const Run = preload("res://src/service/gameplay/run_state.gd")
const Cards = preload("res://src/service/gameplay/cards.gd")
const BoardRules = preload("res://src/service/board/board_rules.gd")
const Scoring = preload("res://src/service/gameplay/scoring.gd")

func _init() -> void:
	for use_discard in [false, true]:
		var scores: Array = []
		for sample in Probe.SAMPLE_COUNT:
			var game = Run.new()
			game.start(Probe.SEED + sample)
			game.level = Config.LEVEL_TARGETS.size()
			for budget in Probe.PLAYS_BY_TURN:
				if game.status != Run.Status.PLAYING:
					break
				if use_discard:
					_discard_unmatched(game)
				for play in budget:
					var cells: Array[Vector2i] = []
					cells.assign(game.board.keys())
					var placements := BoardRules.get_placements(cells)
					var best_score := -INF
					var best_card := -1
					var best_cell := Vector2i.ZERO
					for card in game.hand:
						for cell in placements:
							game.board[cell] = card
							var result := Scoring.evaluate(game.board, game.played + [card])
							game.board.erase(cell)
							if result.net > best_score:
								best_score = result.net
								best_card = card
								best_cell = cell
					if best_card >= 0:
						game.place(best_card, best_cell)
				game.settle()
			scores.append(game.score)
		scores.sort()
		print("Greedy %s: min=%s median=%s max=%s" % ["with discards" if use_discard else "no discards", scores[0], scores[scores.size() / 2], scores[-1]])
		for level in [1, Config.LEVEL_TARGETS.size() / 2 + 1, Config.LEVEL_TARGETS.size()]:
			var passes := 0
			for score in scores:
				if score >= Config.LEVEL_TARGETS[level - 1]:
					passes += 1
			print("Lv %d target %d: %d/%d baseline scores reach target" % [level, Config.LEVEL_TARGETS[level - 1], passes, scores.size()])
	quit()

func _discard_unmatched(game: RefCounted) -> void:
	var discard: Array = []
	for card in game.hand:
		var matches := 0
		for other in game.hand + game.board.values():
			if other != card and Cards.rank(card) == Cards.rank(other):
				matches += 1
		if matches == 0 and discard.size() < Config.MAX_DISCARD:
			discard.append(card)
	game.discard(discard)
