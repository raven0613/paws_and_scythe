extends Control

const Config = preload("res://src/configs/score/score_feedback_config.gd")
var _source := Vector2.ZERO
var _target := Vector2.ZERO
var _offsets: Array[Vector2] = []
var _rng := RandomNumberGenerator.new()
var _progress := 0.0
var _active := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = Config.PARTICLE_LAYER
	_rng.randomize()
	for i in Config.PARTICLE_COUNT:
		_offsets.append(Vector2.ZERO)

func begin(source: Vector2, target: Vector2) -> void:
	var inverse := get_global_transform().affine_inverse()
	_source = inverse * source
	_target = inverse * target
	for i in _offsets.size():
		_offsets[i] = Vector2.from_angle(_rng.randf() * TAU) * _rng.randf() * Config.PARTICLE_SPREAD
	_active = true
	progress(0.0)

func progress(amount: float) -> void:
	_progress = amount
	queue_redraw()

func clear() -> void:
	_active = false
	queue_redraw()

func _draw() -> void:
	if not _active:
		return
	for i in _offsets.size():
		var delay := float(i) / maxf(1, _offsets.size() - 1) * Config.PARTICLE_EMIT_SPAN
		var time := (_progress - delay) / (1.0 - Config.PARTICLE_EMIT_SPAN)
		if time >= 1.0:
			continue
		var travel := pow(clampf(time, 0, 1), 2)
		var origin := _source + _offsets[i]
		var point := origin.lerp(_target, travel)
		point.y -= sin(travel * PI) * Config.PARTICLE_ARC
		var alpha := 1.0 if time >= 0 else Config.PARTICLE_WAIT_ALPHA
		for layer in range(Config.PARTICLE_GLOW_LAYERS, 0, -1):
			var color := Config.PARTICLE_COLOR
			color.a = alpha * Config.PARTICLE_GLOW_ALPHA
			draw_circle(point, Config.PARTICLE_GLOW_RADIUS * layer / Config.PARTICLE_GLOW_LAYERS, color)
		var core := Config.PARTICLE_CORE_COLOR
		core.a = alpha
		draw_circle(point, Config.PARTICLE_RADIUS, core)
