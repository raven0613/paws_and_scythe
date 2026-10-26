extends RefCounted

const Config = preload("res://src/configs/gameplay/game_rules.gd")
var draw_pile: Array = []
var discard_pile: Array = []
var rng := RandomNumberGenerator.new()

func reset() -> void:
	draw_pile = range(Config.DECK_SIZE)
	discard_pile.clear()
	_shuffle()

func draw(count: int) -> Array:
	var result: Array = []
	for i in count:
		if draw_pile.is_empty():
			draw_pile.assign(discard_pile)
			discard_pile.clear()
			_shuffle()
		if draw_pile.is_empty():
			break
		result.append(draw_pile.pop_back())
	return result

func _shuffle() -> void:
	for i in range(draw_pile.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var card: int = draw_pile[i]
		draw_pile[i] = draw_pile[j]
		draw_pile[j] = card
