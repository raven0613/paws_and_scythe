@tool
extends Control

signal layout_changed

const Config = preload("res://src/configs/score/score_feedback_config.gd")
const Feel = preload("res://src/configs/score/celebration_config.gd")
const Transition = preload("res://src/configs/score/galaxy_transition_config.gd")
const Math = preload("res://src/service/score/celebration_math.gd")
const Slam = preload("res://src/service/score/slam_math.gd")
const Surge = preload("res://src/service/score/galaxy_surge.gd")
const VignetteMotion = preload("res://src/service/score/vignette_motion.gd")
const Distortion = preload("res://src/service/score/impact_distortion.gd")
const Odometer = preload("res://src/scripts/score/odometer/odometer_label.gd")
const Flame = preload("res://src/scripts/score/celebration/block_flame.gd")
const Glow = preload("res://src/scripts/score/celebration/flash_glow.gd")
const Debris = preload("res://src/scripts/score/celebration/impact_debris.gd")
const Quake = preload("res://src/scripts/score/celebration/screen_quake.gd")
const Fill = preload("res://src/scripts/score/celebration/score_fill.gd")
const Vignette = preload("res://src/scripts/score/celebration/vignette.gd")
const DistortionLayer = preload("res://src/scripts/score/celebration/impact_distortion.gd")
var _visual: Node2D
var _digits: Control
var _flame: Node2D
var _glow: Node2D
var _debris_back: Node2D
var _debris_front: Node2D
var _vignette: ColorRect
var _distortion: ColorRect
var _fills := {}
var _fill: ShaderMaterial
var _tier := Feel.Tier.NORMAL
var _total := 0.0
var _active := false
var _clock := 0.0
var _fill_clock := 0.0
var _flow := 1.0
var _speed := 1.0
var _width := 0.0
var _contacts := 0
# 銀河撞頂後與衝擊波發出後經過的秒數，負值表示尚未發生。
var _surge_time := -1.0
var _wave_time := -1.0
var _wave_center := Vector2.ZERO
# 熱浪雜訊累積的向上飄移量（像素），速度改變時連續。
var _haze_drift := 0.0
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
	_digits.outer_outline_size = Config.NUMBER_OUTER_OUTLINE_SIZE
	_digits.outer_outline_color = Config.NUMBER_OUTER_OUTLINE
	_visual.add_child(_digits)
	_vignette = Vignette.new()
	add_child(_vignette)
	_distortion = DistortionLayer.new()
	add_child(_distortion)
	for tier in [Feel.Tier.HOLOGRAPHIC, Feel.Tier.GALAXY]:
		_fills[tier] = Fill.new(tier)
	_use_fill(Feel.Tier.HOLOGRAPHIC)
	_digits.minimum_size_changed.connect(_layout)
	resized.connect(_layout)
	_layout()
	_rest()

func prepare(total: float, level_target: float) -> void:
	_total = total
	_tier = Math.tier(total, level_target)
	_debris_back.palette = Fill.debris_palette(_tier)
	_debris_front.palette = Fill.debris_palette(_tier)
	_clock = 0.0
	_fill_clock = 0.0
	_contacts = 0
	_clear_finale()
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
	return Math.duration(_tier, final)

func final_hold() -> float:
	return Math.final_hold(_tier)

func feedback_progress(progress: float, final: bool) -> void:
	if final and _high():
		_finale(progress * Math.duration(_tier, true))
	else:
		_apply_pose(Math.impact(progress, _high(), final))

func reset_feedback() -> void:
	_active = false
	_contacts = 0
	_digits.set_value(_total)
	_rest()
	_clear_finale()
	_fill.set_shader_parameter("energy", 0.0)
	_set_flash(0.0)
	_flame.energy = 0.0
	_flame.flare = 0.0
	_flame.redraw()
	_debris_back.clear()
	_debris_front.clear()
	Quake.reset(get_viewport())

func _high() -> bool:
	return _tier != Feel.Tier.NORMAL

func _galaxy() -> bool:
	return _fill == _fills[Feel.Tier.GALAXY]

func _clear_finale() -> void:
	_surge_time = -1.0
	_wave_time = -1.0
	_haze_drift = 0.0
	_distortion.hide()
	for fill in _fills.values():
		fill.set_shader_parameter("impact", 0.0)
	_use_fill(Feel.Tier.HOLOGRAPHIC)
	_set_flow(1.0, 0.0)
	_flame.blend = 0.0
	_digits.outer_outline_color = Config.NUMBER_OUTER_OUTLINE
	_vignette.hide()

func _use_fill(tier: int) -> void:
	_fill = _fills[tier]
	_digits.set_fill_material(_fill)

func _set_flow(flow: float, brightness: float) -> void:
	_flow = flow
	_fill.set_shader_parameter("brightness", _fill.base_brightness * (1.0 + brightness))

func _apply_pose(pose: Dictionary) -> void:
	_visual.position = size / 2 + pose.position
	_visual.scale = pose.scale
	_visual.rotation = pose.rotation

# 結算完成表演：銀河等級先蓄力，再播放撞擊時間軸；time 為表演開始後的秒數。
func _finale(time: float) -> void:
	var lead := Surge.lead(_tier)
	if time < lead:
		var charge := Surge.charge(time)
		_set_flow(charge.flow, charge.brightness)
		_apply_pose({"position": Vector2.ZERO, "scale": charge.scale, "rotation": 0.0})
		return
	if _flow != 1.0:
		_set_flow(1.0, 0.0)
	_slam((time - lead) / Slam.duration())

func _slam(progress: float) -> void:
	var pose := Slam.pose(progress, _digits.size, _tier)
	_apply_pose(pose)
	_set_flash(pose.flash)
	_flame.flare = pose.flare if Feel.FIRE_FLARE_ENABLED else 0.0
	if Feel.SCREEN_QUAKE_ENABLED:
		Quake.apply(get_viewport(), pose.quake)
	var reached := Slam.contacts(progress)
	while _contacts < reached:
		if _contacts == 0 and _tier == Feel.Tier.GALAXY:
			_surge_time = 0.0
		else:
			_burst(_contacts)
		if _contacts == 0 and _tier == Feel.Tier.HOLOGRAPHIC:
			_start_wave()
		_contacts += 1

func _burst(contact: int) -> void:
	if not Feel.DEBRIS_ENABLED:
		return
	for emitter in Slam.emitters(contact, _digits.size, _tier):
		var layer := _debris_front if emitter.front else _debris_back
		layer.burst(size / 2 + emitter.point, emitter)

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

# 高分依跑分漸強為全像彩虹，換成銀河後維持完整效果。
func _update_energy() -> void:
	var energy := 0.0
	if _galaxy():
		energy = 1.0
	elif _high():
		energy = Math.energy(value, _total)
	_fill.set_shader_parameter("energy", energy)
	_flame.energy = energy

func _process(delta: float) -> void:
	if not _active:
		return
	var elapsed := delta * _speed
	_clock += elapsed
	if _high() and _digits.motion.active:
		_visual.position = size / 2 + Feel.COUNT_SHAKE * Vector2(
			sin(_clock * Feel.COUNT_SHAKE_FREQUENCY.x), sin(_clock * Feel.COUNT_SHAKE_FREQUENCY.y))
	if _surge_time >= 0.0:
		_surge_time += elapsed
		_advance_surge()
	if _wave_time >= 0.0:
		_wave_time += elapsed
	if _high():
		_update_distortion(elapsed)
	_fill_clock += elapsed * _flow
	_fill.set_shader_parameter("clock_time", _fill_clock)
	_flame.advance(elapsed)

# 撞頂後先播反轉幀，結束時換成銀河並噴出撞頂碎片；火焰漸變與暗角持續到結算結束。
func _advance_surge() -> void:
	var pose := Surge.pose(_surge_time)
	if pose.galaxy and not _galaxy():
		_use_fill(Feel.Tier.GALAXY)
		_update_energy()
		_burst(0)
		_start_wave()
	_fill.set_shader_parameter("impact", pose.impact)
	var outline := Transition.IMPACT_OUTLINE if pose.impact > 0.0 else Config.NUMBER_OUTER_OUTLINE
	if _digits.outer_outline_color != outline:
		_digits.outer_outline_color = outline
	_flame.blend = pose.fire
	_vignette.apply(VignetteMotion.pose(_surge_time))

# 炸開的瞬間由數字當下的中心發出衝擊波，熱浪同時開始增強。
func _start_wave() -> void:
	_wave_time = 0.0
	_wave_center = _visual.get_global_transform().origin

# 熱浪隨火焰在跑分時出現，衝擊波發出後增強；兩者都沒有強度時隱藏扭曲層。
func _update_distortion(elapsed: float) -> void:
	var shockwave := Feel.SHOCKWAVE_ENABLED and _wave_time >= 0.0
	var wave := Distortion.shockwave(_tier, _wave_time if shockwave else -1.0)
	var settings := Distortion.haze(_tier, _flame.energy, _wave_time)
	var strength: float = settings.strength if Feel.HEAT_HAZE_ENABLED and Feel.FIRE_ENABLED else 0.0
	if wave.strength <= 0.0 and strength <= 0.0:
		_distortion.hide()
		return
	_haze_drift += elapsed * settings.speed
	var region := Distortion.haze_region(settings, _flame.glyph)
	var frame := _visual.get_global_transform()
	_distortion.apply(_wave_center, wave, {
		"center": frame * region.center,
		"radius": region.radius * frame.get_scale(),
		"strength": strength,
		"frequency": settings.frequency,
		"drift": _haze_drift,
	})
