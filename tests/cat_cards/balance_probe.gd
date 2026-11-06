extends SceneTree

const Rules = preload("res://src/configs/gameplay/game_rules.gd")
const Probe = preload("res://src/configs/gameplay/balance_probe_config.gd")
const Balance = preload("res://src/configs/cat_cards/cat_balance_config.gd")
const Run = preload("res://src/service/gameplay/run_state.gd")
const Cards = preload("res://src/service/gameplay/cards.gd")
const BoardRules = preload("res://src/service/board/board_rules.gd")

func _init() -> void:
	for count in Balance.PROBE_COUNTS:
		for build_name in Balance.BUILDS:
			if count == 0 and build_name != Balance.BUILDS.keys()[0]:
				continue
			var scores: Array = []
			var by_turn := {}
			for turn in Balance.REPORT_TURNS:
				by_turn[turn] = []
			for sample in Balance.PROBE_SAMPLES:
				var game = Run.new()
				game.start(Probe.SEED + sample, Balance.BUILDS[build_name].slice(0, count))
				game.level = Rules.LEVEL_TARGETS.size()
				for turn in Probe.PLAYS_BY_TURN.size():
					_discard_unmatched(game)
					for play in Probe.PLAYS_BY_TURN[turn]:
						_place_best(game)
					game.settle()
					if by_turn.has(turn + 1):
						by_turn[turn + 1].append(game.score)
					# 探針量測完整六次的產出；提早達標後繼續量測相同資源。
					if game.status == Run.Status.LEVEL_CLEARED or game.status == Run.Status.WON:
						game.status = Run.Status.PLAYING
						game.hand.append_array(game.deck.draw(game.hand_limit - game.hand.size()))
				scores.append(game.score)
			scores.sort()
			var report := {"cards": count, "build": build_name, "min": scores[0], "median": scores[scores.size() / 2], "max": scores[-1]}
			var target: int = Rules.LEVEL_TARGETS[Balance.TARGET_TEST_LEVELS[count] - 1]
			report.target = target
			report.passes = scores.filter(func(score): return score >= target).size()
			for turn in by_turn:
				by_turn[turn].sort()
				report["turn_%d" % turn] = by_turn[turn][by_turn[turn].size() / 2]
			print(JSON.stringify(report))
	quit()

func _place_best(game: RefCounted) -> void:
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

func _discard_unmatched(game: RefCounted) -> void:
	var discard: Array = []
	for card in game.hand:
		var matches := 0
		for other in game.hand + game.board.values():
			if other != card and Cards.rank(card) == Cards.rank(other):
				matches += 1
		if matches == 0 and discard.size() < Rules.MAX_DISCARD:
			discard.append(card)
	game.discard(discard)
