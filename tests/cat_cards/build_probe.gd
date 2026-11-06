extends SceneTree

const Config = preload("res://src/configs/cat_cards/build_probe_config.gd")
const Rules = preload("res://src/configs/gameplay/game_rules.gd")
const Catalog = preload("res://src/configs/cat_cards/cat_catalog.gd")
const Cards = preload("res://src/service/gameplay/cards.gd")
const Scoring = preload("res://src/service/gameplay/scoring.gd")
const Resolver = preload("res://src/service/cat_cards/cat_resolver.gd")
const Modifiers = preload("res://src/service/cat_cards/rule_modifiers.gd")

func _init() -> void:
	for name in Config.CASES:
		var fixture: Dictionary = Config.CASES[name]
		var board := {}
		var used := {}
		assert(Catalog.valid_selection(fixture.cats))
		for line in fixture.lines:
			for x in line.ranks.size():
				var card := Cards.id(line.ranks[x], line.suits[x])
				var cell: Vector2i = line.origin + Vector2i(x, 0)
				assert(not used.has(card) and not board.has(cell))
				used[card] = true
				board[cell] = card
		assert(board.size() < Modifiers.board_limit(fixture.cats))
		var raw := Scoring.evaluate(board, [], Modifiers.extended_min(fixture.cats))
		var result := Resolver.resolve(raw, board, fixture.cats, {})
		print(JSON.stringify({"build": name, "cards": board.size(), "groups": result.groups.map(func(g): return g.kind),
			"subtotal": result.subtotal, "combo_multiplier": result.multiplier, "total": result.total,
			"last_level_settlements": ceili(Rules.LEVEL_TARGETS[-1] / result.total)}))
	quit()
