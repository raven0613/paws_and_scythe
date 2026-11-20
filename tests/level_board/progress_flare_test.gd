extends SceneTree

const Flare = preload("res://src/service/level_board/progress_flare.gd")
const Config = preload("res://src/configs/level_board/progress_flare_config.gd")
const Feedback = preload("res://src/configs/score/score_feedback_config.gd")
const Feel = preload("res://src/configs/score/celebration_config.gd")
const SAMPLES = 200
var failures := 0

func _init() -> void:
	_test_params()
	for tier in [Feel.Tier.HOLOGRAPHIC, Feel.Tier.GALAXY]:
		_test_pose(tier)
	_test_galaxy_scale()
	print("Progress flare: %d failures" % failures)
	quit(1 if failures else 0)

# 全像彩虹與銀河各用一組數值，銀河的震動、放大與發光都比全像彩虹誇張。
func _test_params() -> void:
	var rainbow := Flare.params(Feel.Tier.HOLOGRAPHIC)
	var galaxy := Flare.params(Feel.Tier.GALAXY)
	_check(rainbow == Config.HOLOGRAPHIC and galaxy == Config.GALAXY, "Each high tier uses its own flare values.")
	_check(galaxy.shake.x > rainbow.shake.x and galaxy.shake.y > rainbow.shake.y and galaxy.tilt > rainbow.tilt, "Galaxy shakes harder than holographic.")
	_check(galaxy.scale > rainbow.scale, "Galaxy enlarges the bar more than holographic.")
	_check(galaxy.core > rainbow.core and galaxy.halo_size > rainbow.halo_size and galaxy.halo_alpha > rainbow.halo_alpha, "Galaxy glows brighter and wider than holographic.")

# 從原位起震、跑分期間快速震動並維持最亮，跑完時回到原位與原尺寸且保持最亮。
func _test_pose(tier: int) -> void:
	var flare := Flare.params(tier)
	var duration := Feedback.LEVEL_COUNT_DURATION
	var start := Flare.pose(0.0, duration, flare)
	_check(start.position.is_zero_approx() and is_zero_approx(start.rotation) and is_equal_approx(start.scale, 1.0) and is_zero_approx(start.glow), "Tier %d starts from the resting bar." % tier)
	var peak := Vector2.ZERO
	var tilt := 0.0
	var lit := true
	for step in SAMPLES:
		var time := lerpf(Config.GLOW_RISE, duration, float(step) / SAMPLES)
		var pose := Flare.pose(time, duration, flare)
		peak = peak.max(pose.position.abs())
		tilt = maxf(tilt, absf(pose.rotation))
		lit = lit and is_equal_approx(pose.glow, 1.0)
	_check(peak.x > flare.shake.x * 0.8 and peak.y > flare.shake.y * 0.8 and tilt > flare.tilt * 0.8, "Tier %d shakes close to full strength while counting." % tier)
	_check(peak.x <= flare.shake.x and peak.y <= flare.shake.y and tilt <= flare.tilt, "Tier %d stays within its shake range." % tier)
	_check(lit, "Tier %d holds full glow from the rise to the end of the count." % tier)
	var rising := Flare.pose(Config.GLOW_RISE / 2.0, duration, flare)
	_check(rising.glow > 0.0 and rising.glow < 1.0, "Tier %d brightens during the glow rise." % tier)
	var rest := Flare.pose(duration, duration, flare)
	_check(rest.position.is_zero_approx() and is_zero_approx(rest.rotation) and is_equal_approx(rest.scale, 1.0) and is_equal_approx(rest.glow, 1.0), "Tier %d returns to rest at full glow when the count lands." % tier)

# 銀河在 ATTACK 內衝過頭到放大倍率，維持到收回前，跑完時回到原尺寸；全像彩虹維持原尺寸。
func _test_galaxy_scale() -> void:
	var duration := Feedback.LEVEL_COUNT_DURATION
	var galaxy := Flare.params(Feel.Tier.GALAXY)
	var overshoot := false
	for step in range(1, 10):
		overshoot = overshoot or Flare.pose(Config.ATTACK * step / 10.0, duration, galaxy).scale > galaxy.scale
	_check(overshoot, "Galaxy overshoots while enlarging.")
	_check(is_equal_approx(Flare.pose(Config.ATTACK, duration, galaxy).scale, galaxy.scale), "Galaxy reaches its scale after the attack.")
	_check(is_equal_approx(Flare.pose(duration - Config.RELEASE, duration, galaxy).scale, galaxy.scale), "Galaxy holds its scale until the release.")
	var returning: float = Flare.pose(duration - Config.RELEASE / 2.0, duration, galaxy).scale
	_check(returning > 1.0 and returning < galaxy.scale, "Galaxy shrinks back during the release.")
	var rainbow := Flare.params(Feel.Tier.HOLOGRAPHIC)
	_check(is_equal_approx(Flare.pose(duration / 2.0, duration, rainbow).scale, rainbow.scale), "Holographic keeps its configured scale while counting.")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
