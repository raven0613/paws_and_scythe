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
	_check(absf(calm_start.point.y - _height(layer.bottom * LOW_ENERGY)) < TOLERANCE, "Lower energy scales the layer bottom toward the digit base")
	_check(absf(calm_finish.point.y - _height(layer.top * LOW_ENERGY)) < TOLERANCE, "Lower energy scales the layer top toward the digit base")
	var burst_start := Flame.block(layer, particle, 0.0, glyph, 1.0, 1.0)
	var burst := Flame.block(layer, particle, 1.0, glyph, 1.0, 1.0)
	_check(absf(burst_start.point.y - start.point.y) < TOLERANCE, "Impact flare keeps the layer bottom in place")
	_check(burst.point.y < finish.point.y, "Impact flare lifts the flame above its top")
	var life := Flame.lifetime(layer, particle)
	_check(is_equal_approx(Flame.advance(layer, particle, particle.phase, life), particle.phase), "Each block loops once per lifetime")
	_check(is_equal_approx(Flame.advance(layer, particle, particle.phase, life * HALFWAY), fposmod(particle.phase + HALFWAY, 1.0)), "Progress advances with elapsed time")

func _check_blend(rng: RandomNumberGenerator) -> void:
	_check(is_equal_approx(Flame.speed(0.0), Config.FIRE_SPEED_HOLOGRAPHIC) and is_equal_approx(Flame.speed(1.0), Config.FIRE_SPEED_GALAXY), "Flame speed follows the blend between both sets")
	_check(Flame.speed(1.0) > Flame.speed(0.0), "Galaxy flame moves faster than holographic flame")
	var calm := Flame.glow(0.0)
	var bright := Flame.glow(1.0)
	_check(is_equal_approx(calm.blur, Config.FIRE_GLOW_HOLOGRAPHIC.blur) and is_equal_approx(bright.intensity, Config.FIRE_GLOW_GALAXY.intensity), "Flame glow follows the blend between both sets")
	_check(bright.blur > calm.blur and bright.intensity > calm.intensity and bright.size > calm.size, "Galaxy flame glows wider and brighter")
	var glow_layer := Flame.layer(0, 0.0)
	_check(Flame.glow_color(glow_layer, calm).get_luminance() >= glow_layer.color.get_luminance(), "Glow takes a lighter shade of the flame color")
	_check(Flame.lit_color(glow_layer, bright).get_luminance() >= Flame.lit_color(glow_layer, calm).get_luminance(), "Galaxy brightens the flame itself more")
	for index in Flame.layer_count():
		var from: Dictionary = Config.FIRE_LAYERS_HOLOGRAPHIC[index]
		var to: Dictionary = Config.FIRE_LAYERS_GALAXY[index]
		_check(Flame.layer(index, 0.0).color.is_equal_approx(from.color) and Flame.layer(index, 1.0).color.is_equal_approx(to.color), "Blend ends match each flame set")
		_check(Flame.layer(index, HALFWAY).color.is_equal_approx(from.color.lerp(to.color, HALFWAY)), "Flame colors shift gradually between sets")
		var particle := Flame.spawn(rng)
		var near := Flame.block(Flame.layer(index, HALFWAY - TOLERANCE), particle, HALFWAY, glyph, 1.0, 0.0)
		var far := Flame.block(Flame.layer(index, HALFWAY + TOLERANCE), particle, HALFWAY, glyph, 1.0, 0.0)
		_check(near.point.distance_to(far.point) < 1.0, "Blocks move continuously while the sets blend")

func _height(ratio: float) -> float:
	return glyph.end.y - ratio * glyph.size.y

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
