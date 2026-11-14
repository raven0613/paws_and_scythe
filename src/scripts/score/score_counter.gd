@tool
extends Control

signal layout_changed

const Config = preload("res://src/configs/score/score_feedback_config.gd")
const Feel = preload("res://src/configs/score/celebration_config.gd")
const Math = preload("res://src/service/score/celebration_math.gd")
const Slam = preload("res://src/service/score/slam_math.gd")
const Odometer = preload("res://src/scripts/score/odometer/odometer_label.gd")
const Flame = preload("res://src/scripts/score/celebration/block_flame.gd")
const Glow = preload("res://src/scripts/score/celebration/flash_glow.gd")
const Debris = preload("res://src/scripts/score/celebration/impact_debris.gd")
const Quake = preload("res://src/scripts/score/celebration/screen_quake.gd")
const Fill = preload("res://src/scripts/score/celebration/score_fill.gd")
var _visual: Node2D
var _digits: Control
var _flame: Node2D
var _glow: Node2D
var _debris_back: Node2D
var _debris_front: Node2D
var _fill: ShaderMaterial
var _high := false
var _total := 0.0
var _active := false
var _clock := 0.0
var _speed := 1.0
var _width := 0.0
var _contacts := 0
var value: float:
	get:
		return _digits.motion.current if _digits else 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = Config.NUMBER_LAYER
	_debris_back = Debris.new()
	add_child(_debris_back)
	_visual = Node2D.new()
	add_child(_visual)
	_debris_front = Debris.new()
	add_child(_debris_front)
	_flame = Flame.new()
	_visual.add_child(_flame)
	_glow = Glow.new()
	_visual.add_child(_glow)
	_digits = Odometer.new()
	_digits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_digits.add_theme_font_size_override("font_size", Config.NUMBER_FONT_SIZE)
	_digits.add_theme_color_override("font_color", Config.NUMBER_COLOR)
	_digits.add_theme_color_override("font_outline_color", Config.NUMBER_OUTLINE)
	_digits.add_theme_constant_override("outline_size", Config.NUMBER_OUTLINE_SIZE)
	_visual.add_child(_digits)
	_fill = Fill.new()
	_digits.set_fill_material(_fill)
	_digits.minimum_size_changed.connect(_layout)
	resized.connect(_layout)
	_layout()
	_rest()

func prepare(total: float, level_target: float) -> void:
	_total = total
	_high = Math.is_high(total, level_target)
	_clock = 0.0
	_contacts = 0
	_active = true
	set_value(0.0)

func set_playback_speed(speed: float) -> void:
	_speed = speed
	_debris_back.speed = speed
	_debris_front.speed = speed

func set_value(amount: float) -> void:
	_digits.set_value(amount)
	_rest()
	_update_energy()

func begin_count(target: float, seconds: float) -> void:
	_digits.begin_count(target, seconds)
	_rest()

func count_progress(progress: float) -> void:
	_digits.count_progress(progress)
	_update_energy()

func finish_count() -> void:
	_digits.finish_count()
	_rest()
	_update_energy()

func feedback_duration(final: bool) -> float:
	return Math.duration(_high, final)

func feedback_progress(progress: float, final: bool) -> void:
	if final and _high:
		_slam(progress)
	else:
		_apply_pose(Math.impact(progress, _high, final))

func reset_feedback() -> void:
	_active = false
	_contacts = 0
	_digits.set_value(_total)
	_rest()
	_fill.set_shader_parameter("energy", 0.0)
	_set_flash(0.0)
	_flame.energy = 0.0
	_flame.flare = 0.0
	_flame.queue_redraw()
	_debris_back.clear()
	_debris_front.clear()
	Quake.reset(get_viewport())

func _apply_pose(pose: Dictionary) -> void:
	_visual.position = size / 2 + pose.position
	_visual.scale = pose.scale
	_visual.rotation = pose.rotation

func _slam(progress: float) -> void:
	var pose := Slam.pose(progress, _digits.size)
	_apply_pose(pose)
	_set_flash(pose.flash)
	_flame.flare = pose.flare if Feel.FIRE_FLARE_ENABLED else 0.0
	if Feel.SCREEN_QUAKE_ENABLED:
		Quake.apply(get_viewport(), pose.quake)
	var reached := Slam.contacts(progress)
	while _contacts < reached:
		if Feel.DEBRIS_ENABLED:
			for emitter in Slam.emitters(_contacts, _digits.size):
				var layer := _debris_front if emitter.front else _debris_back
				layer.burst(size / 2 + emitter.point, emitter)
		_contacts += 1

func _set_flash(amount: float) -> void:
	_fill.set_shader_parameter("flash", amount)
	_glow.amount = amount if Feel.FLASH_GLOW_ENABLED else 0.0
	_glow.queue_redraw()

func _rest() -> void:
	_visual.position = size / 2
	_visual.scale = Vector2.ONE
	_visual.rotation = 0.0

func _layout() -> void:
	_digits.size = _digits.get_minimum_size()
	_digits.position = -_digits.size / 2
	_width = _digits.size.x
	var bounds: Vector2 = _digits.digit_bounds() + Vector2.ONE * _digits.position.y
	_flame.glyph = Rect2(-_width / 2, bounds.x, _width, bounds.y - bounds.x)
	_glow.width = _width
	_glow.height = _digits.size.y
	layout_changed.emit()

func layout_right() -> float:
	var launch := Feel.LAUNCH_SCALE.x * maxf(1.0, Feel.CEILING_SQUASH.x)
	var landing := maxf(Feel.FALL_STRETCH.x, Feel.FLOOR_SQUASH.x)
	var peak := maxf(maxf(Feel.FINAL_SCALE, Feel.HIGH_STEP_SCALE), maxf(launch, landing))
	return position.x + size.x / 2 + _width / 2 * peak

func particle_origin() -> Vector2:
	return get_global_transform_with_canvas() * (size / 2)

func _update_energy() -> void:
	var energy := Math.energy(value, _total) if _high else 0.0
	_fill.set_shader_parameter("energy", energy)
	_flame.energy = energy

func _process(delta: float) -> void:
	if not _active:
		return
	_clock += delta * _speed
	_fill.set_shader_parameter("clock_time", _clock)
	_flame.clock_time = _clock
	_flame.queue_redraw()
	if _high and _digits.motion.active:
		_visual.position = size / 2 + Feel.COUNT_SHAKE * Vector2(
			sin(_clock * Feel.COUNT_SHAKE_FREQUENCY.x), sin(_clock * Feel.COUNT_SHAKE_FREQUENCY.y))
