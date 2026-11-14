extends Control

const Config = preload("res://src/configs/score/score_feedback_config.gd")
var _waves := {}
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = Config.PARTICLE_LAYER
	_rng.randomize()

# 每波以 key 區分並可同時飛行，進度到 1 時自動移除。
func begin(key: int, source: Vector2, target: Vector2) -> void:
	var inverse := get_global_transform().affine_inverse()
	var offsets: Array[Vector2] = []
	for i in Config.PARTICLE_COUNT:
		offsets.append(Vector2.from_angle(_rng.randf() * TAU) * _rng.randf() * Config.PARTICLE_SPREAD)
	_waves[key] = {"source": inverse * source, "target": inverse * target, "offsets": offsets, "progress": 0.0}
	queue_redraw()

func progress(amount: float, key: int) -> void:
	if amount >= 1.0:
		_waves.erase(key)
	else:
		_waves[key].progress = amount
	queue_redraw()

func clear() -> void:
	_waves.clear()
	queue_redraw()

func _draw() -> void:
	for wave in _waves.values():
		_draw_wave(wave)

func _draw_wave(wave: Dictionary) -> void:
	var offsets: Array[Vector2] = wave.offsets
	for i in offsets.size():
		var delay := float(i) / maxf(1, offsets.size() - 1) * Config.PARTICLE_EMIT_SPAN
		var time: float = (wave.progress - delay) / (1.0 - Config.PARTICLE_EMIT_SPAN)
		if time >= 1.0:
			continue
		var travel := pow(clampf(time, 0, 1), 2)
		var origin: Vector2 = wave.source + offsets[i]
		var point := origin.lerp(wave.target, travel)
		point.y -= sin(travel * PI) * Config.PARTICLE_ARC
		var alpha := 1.0 if time >= 0 else Config.PARTICLE_WAIT_ALPHA
		for layer in range(Config.PARTICLE_GLOW_LAYERS, 0, -1):
			var color := Config.PARTICLE_COLOR
			color.a = alpha * Config.PARTICLE_GLOW_ALPHA
			draw_circle(point, Config.PARTICLE_GLOW_RADIUS * layer / Config.PARTICLE_GLOW_LAYERS, color)
		var core := Config.PARTICLE_CORE_COLOR
		core.a = alpha
		draw_circle(point, Config.PARTICLE_RADIUS, core)
