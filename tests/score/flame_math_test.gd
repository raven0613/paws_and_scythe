extends SceneTree

const Flame = preload("res://src/service/score/flame_math.gd")
const Config = preload("res://src/configs/score/celebration_config.gd")
const Feedback = preload("res://src/configs/score/score_feedback_config.gd")
const TOLERANCE = 0.01
const LOW_ENERGY = 0.2
const HALFWAY = 0.5
var glyph := Rect2(Vector2(-2, -0.5) * Feedback.NUMBER_FONT_SIZE, Vector2(4, 1) * Feedback.NUMBER_FONT_SIZE)
var failures := 0

func _init() -> void:
	var rng := RandomNumberGenerator.new()
	_check(Config.FIRE_LAYERS_HOLOGRAPHIC.size() == Config.FIRE_LAYERS_GALAXY.size(), "Both flame sets pair up layer by layer")
	for blend in [0.0, 1.0]:
		for index in Flame.layer_count():
			_check_layer(Flame.layer(index, blend), Flame.spawn(rng))
		for index in Flame.layer_count() - 1:
			var back := Flame.layer(index, blend)
			var front := Flame.layer(index + 1, blend)
			for energy in [LOW_ENERGY, 1.0]:
				var back_start := Flame.block(back, Flame.spawn(rng), 0.0, glyph, energy, 0.0)
				var front_finish := Flame.block(front, Flame.spawn(rng), 1.0, glyph, energy, 0.0)
				_check(back_start.point.y > front_finish.point.y, "Each layer starts below the top of the layer in front at every energy")
	_check_scale(rng)
	_check_blend(rng)
	print("Flame math: %d failures" % failures)
	quit(1 if failures else 0)

func _check_layer(layer: Dictionary, particle: Dictionary) -> void:
	var start := Flame.block(layer, particle, 0.0, glyph, 1.0, 0.0)
	var finish := Flame.block(layer, particle, 1.0, glyph, 1.0, 0.0)
	_check(absf(start.point.y - _height(layer.bottom)) < TOLERANCE, "Blocks start at the layer bottom")
	_check(absf(finish.point.y - _height(layer.top)) < TOLERANCE, "Blocks rise to the layer top")
	_check(is_zero_approx(start.side) and is_zero_approx(finish.side), "Blocks emerge from nothing and fade out at the top")
	var half := Flame.block(layer, particle, HALFWAY, glyph, 1.0, 0.0)
	_check(half.point.y > lerpf(_height(layer.bottom), _height(layer.top), HALFWAY), "Blocks rise slowly at the bottom and faster above")
	_check(absf(half.point.x - glyph.get_center().x) <= glyph.size.x * layer.width / 2 + layer.spread, "Blocks stay within the layer width")
	var calm_start := Flame.block(layer, particle, 0.0, glyph, LOW_ENERGY, 0.0)
	var calm_finish := Flame.block(layer, particle, 1.0, glyph, LOW_ENERGY, 0.0)
	_check(absf(calm_start.point.y - _height(layer.bottom * Flame.scale(LOW_ENERGY))) < TOLERANCE, "Lower energy scales the layer bottom toward the digit base")
	_check(absf(calm_finish.point.y - _height(layer.top * Flame.scale(LOW_ENERGY))) < TOLERANCE, "Lower energy scales the layer top toward the digit base")
	var burst_start := Flame.block(layer, particle, 0.0, glyph, 1.0, 1.0)
	var burst := Flame.block(layer, particle, 1.0, glyph, 1.0, 1.0)
	_check(absf(burst_start.point.y - start.point.y) < TOLERANCE, "Impact flare keeps the layer bottom in place")
	_check(burst.point.y < finish.point.y, "Impact flare lifts the flame above its top")
	var life := Flame.lifetime(layer, particle)
	_check(is_equal_approx(Flame.advance(layer, particle, particle.phase, life), particle.phase), "Each block loops once per lifetime")
	_check(is_equal_approx(Flame.advance(layer, particle, particle.phase, life * HALFWAY), fposmod(particle.phase + HALFWAY, 1.0)), "Progress advances with elapsed time")

# 漸強一開始即以 FIRE_MIN_SCALE 燃起並長到完整尺寸；任何能量下整團火焰以字底中央為基準等比例縮放，維持寬高比例。
func _check_scale(rng: RandomNumberGenerator) -> void:
	_check(is_zero_approx(Flame.scale(0.0)), "The flame stays hidden before the energy rises")
	_check(absf(Flame.scale(TOLERANCE) - Config.FIRE_MIN_SCALE) < TOLERANCE, "The flame ignites at its minimum scale")
	_check(is_equal_approx(Flame.scale(1.0), 1.0), "Full energy reaches the full flame")
	_check(Flame.scale(LOW_ENERGY) < Flame.scale(HALFWAY) and Flame.scale(HALFWAY) < Flame.scale(1.0), "The flame grows with the energy")
	var base := Vector2(glyph.get_center().x, glyph.end.y)
	for index in Flame.layer_count():
		var layer := Flame.layer(index, 0.0)
		var particle := Flame.spawn(rng)
		for p in [0.0, HALFWAY, 1.0]:
			var full := Flame.block(layer, particle, p, glyph, 1.0, 0.0)
			for energy in [TOLERANCE, LOW_ENERGY, HALFWAY]:
				var scaled := Flame.block(layer, particle, p, glyph, energy, 0.0)
				var ratio := Flame.scale(energy)
				_check((scaled.point - base).is_equal_approx((full.point - base) * ratio), "Energy scales the whole flame around the digit base center")
				_check(is_equal_approx(scaled.side, full.side * ratio), "Energy scales the blocks with the flame")

func _check_blend(rng: RandomNumberGenerator) -> void:
	_check(is_equal_approx(Flame.speed(0.0), Config.FIRE_SPEED_HOLOGRAPHIC) and is_equal_approx(Flame.speed(1.0), Config.FIRE_SPEED_GALAXY), "Flame speed follows the blend between both sets")
	_check(Flame.speed(1.0) > Flame.speed(0.0), "Galaxy flame moves faster than holographic flame")
	_check_glow()
	for index in Flame.layer_count():
		var from: Dictionary = Config.FIRE_LAYERS_HOLOGRAPHIC[index]
		var to: Dictionary = Config.FIRE_LAYERS_GALAXY[index]
		_check(Flame.layer(index, 0.0).color.is_equal_approx(from.color) and Flame.layer(index, 1.0).color.is_equal_approx(to.color), "Blend ends match each flame set")
		_check(Flame.layer(index, HALFWAY).color.is_equal_approx(from.color.lerp(to.color, HALFWAY)), "Flame colors shift gradually between sets")
		var particle := Flame.spawn(rng)
		var near := Flame.block(Flame.layer(index, HALFWAY - TOLERANCE), particle, HALFWAY, glyph, 1.0, 0.0)
		var far := Flame.block(Flame.layer(index, HALFWAY + TOLERANCE), particle, HALFWAY, glyph, 1.0, 0.0)
		_check(near.point.distance_to(far.point) < 1.0, "Blocks move continuously while the sets blend")

# 發光跟隨兩組漸變；火焰方塊本身維持色相與飽和度提高亮度，銀河的提亮、外暈淡出距離與亮度都比全像彩虹強。
func _check_glow() -> void:
	var calm := Flame.glow(0.0)
	var bright := Flame.glow(1.0)
	_check(calm == Config.FIRE_GLOW_HOLOGRAPHIC and bright == Config.FIRE_GLOW_GALAXY, "Blend ends match each glow set")
	var half := Flame.glow(HALFWAY)
	for key in calm:
		_check(is_equal_approx(half[key], lerpf(calm[key], bright[key], HALFWAY)), "Glow shifts gradually between sets")
	_check(bright.brighten > calm.brighten and bright.blur > calm.blur and bright.halo_alpha > calm.halo_alpha, "Galaxy flame glows brighter and wider")
	for glow in [calm, bright]:
		_check(glow.halo_alpha > 0.0 and glow.halo_alpha <= 1.0, "The halo edge stays within full opacity")
		for index in Flame.layer_count():
			var layer := Flame.layer(index, 0.0)
			var lit := Flame.lit_color(layer, glow)
			_check(absf(lit.h - layer.color.h) < TOLERANCE and absf(lit.s - layer.color.s) < TOLERANCE, "Glowing blocks keep their fire hue and saturation")
			_check(absf(lit.v - lerpf(layer.color.v, 1.0, glow.brighten)) < TOLERANCE, "Glowing blocks raise their brightness by the configured ratio")

func _height(ratio: float) -> float:
	return glyph.end.y - ratio * glyph.size.y

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
