extends SceneTree

const Distortion = preload("res://src/service/score/impact_distortion.gd")
const Config = preload("res://src/configs/score/impact_distortion_config.gd")
const Feel = preload("res://src/configs/score/celebration_config.gd")
const Feedback = preload("res://src/configs/score/score_feedback_config.gd")
const SAMPLE = 0.01
const HALF = 0.5
const HIGH_TIERS = [Feel.Tier.HOLOGRAPHIC, Feel.Tier.GALAXY]
var glyph := Rect2(Vector2(-2, -0.5) * Feedback.NUMBER_FONT_SIZE, Vector2(4, 1) * Feedback.NUMBER_FONT_SIZE)
var failures := 0

func _init() -> void:
	for tier in HIGH_TIERS:
		_test_shockwave(tier)
		_test_haze(tier)
	_test_exaggeration()
	_check(Feedback.DISTORTION_LAYER > Feedback.LABEL_LAYER and Feedback.DISTORTION_LAYER < Feedback.VIGNETTE_LAYER, "Distortion sits above peripheral labels and below the vignette")
	_check(Feedback.VIGNETTE_LAYER < Feedback.PARTICLE_LAYER and Feedback.PARTICLE_LAYER < Feedback.NUMBER_LAYER, "Particles and the number stay above the distortion")
	print("Impact distortion: %d failures" % failures)
	quit(1 if failures else 0)

func _test_shockwave(tier: int) -> void:
	var settings: Dictionary = Config.SHOCKWAVE[tier]
	var idle := Distortion.shockwave(tier, -SAMPLE)
	_check(is_zero_approx(idle.strength) and is_zero_approx(idle.aberration), "Shockwave stays calm before it fires")
	var start := Distortion.shockwave(tier, 0.0)
	_check(is_zero_approx(start.radius) and is_equal_approx(start.strength, settings.strength) and is_equal_approx(start.aberration, settings.aberration), "Shockwave bursts from the number at full strength")
	var expanding := true
	var weakening := true
	var previous := start
	for step in range(1, int(settings.duration / SAMPLE) + 1):
		var wave := Distortion.shockwave(tier, step * SAMPLE)
		expanding = expanding and wave.radius >= previous.radius
		weakening = weakening and wave.strength <= previous.strength and wave.aberration <= previous.aberration
		previous = wave
	_check(expanding and weakening, "Shockwave expands while it weakens")
	var halfway := Distortion.shockwave(tier, settings.duration * HALF)
	_check(halfway.radius > settings.radius * HALF, "Shockwave decelerates as it spreads")
	_check(halfway.strength >= settings.strength * HALF - 0.001, "Shockwave keeps half its strength halfway across")
	var done := Distortion.shockwave(tier, settings.duration)
	_check(is_equal_approx(done.radius, settings.radius) and is_zero_approx(done.strength), "Shockwave reaches its radius and fades out")

func _test_haze(tier: int) -> void:
	var wave: float = Config.SHOCKWAVE[tier].duration
	var calm: Dictionary = Config.HEAT_HAZE_COUNT
	var peak: Dictionary = Config.HEAT_HAZE[tier]
	_check(is_zero_approx(Distortion.haze(tier, 0.0, -1.0).strength), "Heat haze waits for the flame")
	_check(is_equal_approx(Distortion.haze(tier, HALF, -1.0).strength, calm.strength * HALF), "Heat haze grows with the flame while counting")
	_check(is_equal_approx(Distortion.haze(tier, 1.0, 0.0).strength, calm.strength), "Shockwave starts from the counting haze")
	var rising := Distortion.haze(tier, 1.0, wave * HALF)
	_check(rising.strength > calm.strength and rising.strength < peak.strength, "Heat haze intensifies during the shockwave")
	var settled := Distortion.haze(tier, 1.0, wave)
	_check(is_equal_approx(settled.strength, peak.strength) and is_equal_approx(settled.speed, peak.speed), "Heat haze holds its exaggerated settings after the shockwave")
	_check(peak.strength > calm.strength, "Heat haze after the shockwave is stronger than while counting")
	var region := Distortion.haze_region(settled, glyph)
	_check(region.center.y < glyph.end.y and region.radius.x > glyph.size.x / 2 and region.radius.y > glyph.size.y, "Heat haze surrounds the flame above the digits")

func _test_exaggeration() -> void:
	var holographic: Dictionary = Config.SHOCKWAVE[Feel.Tier.HOLOGRAPHIC]
	var galaxy: Dictionary = Config.SHOCKWAVE[Feel.Tier.GALAXY]
	_check(galaxy.strength > holographic.strength and galaxy.radius > holographic.radius and galaxy.aberration > holographic.aberration, "Galaxy shockwave is stronger and wider")
	_check(Config.HEAT_HAZE[Feel.Tier.GALAXY].strength > Config.HEAT_HAZE[Feel.Tier.HOLOGRAPHIC].strength, "Galaxy heat haze bends the air harder")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
