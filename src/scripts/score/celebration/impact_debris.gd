@tool
extends Node2D

const Config = preload("res://src/configs/score/celebration_config.gd")
const Fill = preload("res://src/scripts/score/celebration/score_fill.gd")
var speed := 1.0
var _time := 0.0
var _pieces: Array[Dictionary] = []
var _palette := Fill.debris_palette()
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

# 由噴出點射出目前填色色盤的方塊，以噴出方向為中心向兩側散開。
func burst(origin: Vector2, emitter: Dictionary) -> void:
	var direction: Vector2 = emitter.direction
	for index in emitter.count:
		var angle := direction.angle() + _rng.randf_range(-emitter.spread, emitter.spread)
		_pieces.append({
			"origin": origin,
			"velocity": Vector2.from_angle(angle) * _rng.randf_range(emitter.speed.x, emitter.speed.y),
			"born": _time,
			"life": _rng.randf_range(Config.DEBRIS_LIFETIME.x, Config.DEBRIS_LIFETIME.y),
			"size": _rng.randf_range(Config.DEBRIS_SIZE.x, Config.DEBRIS_SIZE.y),
			"angle": _rng.randf() * TAU,
			"spin": _rng.randf_range(-Config.DEBRIS_SPIN, Config.DEBRIS_SPIN),
			"color": _palette[_rng.randi() % _palette.size()],
		})

func clear() -> void:
	_pieces = []
	queue_redraw()

func _process(delta: float) -> void:
	if _pieces.is_empty():
		return
	_time += delta * speed
	_pieces = _pieces.filter(func(piece: Dictionary) -> bool: return _time - piece.born < piece.life)
	queue_redraw()

func _draw() -> void:
	for piece in _pieces:
		var age: float = _time - piece.born
		var p: float = age / piece.life
		var point: Vector2 = piece.origin + piece.velocity * age + Vector2(0.0, Config.DEBRIS_GRAVITY * age * age / 2)
		var side: float = piece.size * (1.0 - p * p)
		draw_set_transform(point, piece.angle + piece.spin * age)
		draw_rect(Rect2(Vector2.ONE * -side / 2, Vector2.ONE * side), piece.color)
	draw_set_transform(Vector2.ZERO)
