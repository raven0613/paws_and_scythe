extends SceneTree

const Flame = preload("res://src/service/score/flame_math.gd")
const Config = preload("res://src/configs/score/celebration_config.gd")
const Feedback = preload("res://src/configs/score/score_feedback_config.gd")
const TOLERANCE = 0.01
const LOW_ENERGY = 0.2
var glyph := Rect2(Vector2(-2, -0.5) * Feedback.NUMBER_FONT_SIZE, Vector2(4, 1) * Feedback.NUMBER_FONT_SIZE)
var failures := 0

func _init() -> void:
	var rng := RandomNumberGenerator.new()
	for layer in Config.FIRE_LAYERS:
		var particle := Flame.spawn(layer, rng)
		var start := Flame.block(layer, particle, 0.0, glyph, 1.0, 0.0)
		var finish := Flame.block(layer, particle, 1.0, glyph, 1.0, 0.0)
		_check(absf(start.point.y - _height(layer.bottom)) < TOLERANCE, "Blocks start at the layer bottom")
		_check(absf(finish.point.y - _height(layer.top)) < TOLERANCE, "Blocks rise to the layer top")
		_check(is_zero_approx(start.side) and is_zero_approx(finish.side), "Blocks emerge from nothing and fade out at the top")
		var half := Flame.block(layer, particle, 0.5, glyph, 1.0, 0.0)
		_check(half.point.y > lerpf(_height(layer.bottom), _height(layer.top), 0.5), "Blocks rise slowly at the bottom and faster above")
		_check(absf(half.point.x - glyph.get_center().x) <= glyph.size.x * layer.width / 2 + layer.spread, "Blocks stay within the layer width")
		var calm_start := Flame.block(layer, particle, 0.0, glyph, LOW_ENERGY, 0.0)
		var calm_finish := Flame.block(layer, particle, 1.0, glyph, LOW_ENERGY, 0.0)
		_check(absf(calm_start.point.y - _height(layer.bottom * LOW_ENERGY)) < TOLERANCE, "Lower energy scales the layer bottom toward the digit base")
		_check(absf(calm_finish.point.y - _height(layer.top * LOW_ENERGY)) < TOLERANCE, "Lower energy scales the layer top toward the digit base")
		var burst_start := Flame.block(layer, particle, 0.0, glyph, 1.0, 1.0)
		var burst := Flame.block(layer, particle, 1.0, glyph, 1.0, 1.0)
		_check(absf(burst_start.point.y - start.point.y) < TOLERANCE, "Impact flare keeps the layer bottom in place")
		_check(burst.point.y < finish.point.y, "Impact flare lifts the flame above its top")
		_check(is_equal_approx(Flame.progress(particle, particle.life), particle.phase), "Each block loops once per lifetime")
	for index in Config.FIRE_LAYERS.size() - 1:
		var back: Dictionary = Config.FIRE_LAYERS[index]
		var front: Dictionary = Config.FIRE_LAYERS[index + 1]
		for energy in [LOW_ENERGY, 1.0]:
			var back_start := Flame.block(back, Flame.spawn(back, rng), 0.0, glyph, energy, 0.0)
			var front_finish := Flame.block(front, Flame.spawn(front, rng), 1.0, glyph, energy, 0.0)
			_check(back_start.point.y > front_finish.point.y, "Each layer starts below the top of the layer in front at every energy")
	print("Flame math: %d failures" % failures)
	quit(1 if failures else 0)

func _height(ratio: float) -> float:
	return glyph.end.y - ratio * glyph.size.y

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
