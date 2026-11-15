extends RefCounted

const Config = preload("res://src/configs/score/score_feedback_config.gd")
const Shake = preload("res://src/service/motion/shake_motion.gd")

# 中央分數乘上倍率的 duration 期間，倍率數字開頭回彈放大並衰減抖動，維持放大後於結尾補間縮回，duration 時回到原狀。
static func pose(time: float, duration: float) -> Dictionary:
	var grow: float = Tween.interpolate_value(1.0, Config.MULTIPLIER_HIT_SCALE - 1.0, minf(time, Config.MULTIPLIER_HIT_GROW),
		Config.MULTIPLIER_HIT_GROW, Tween.TRANS_BACK, Tween.EASE_OUT)
	var release := clampf(time - (duration - Config.MULTIPLIER_HIT_RELEASE), 0.0, Config.MULTIPLIER_HIT_RELEASE)
	var back: float = Tween.interpolate_value(0.0, 1.0, release, Config.MULTIPLIER_HIT_RELEASE, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	var shake := Shake.pose(minf(time / Config.MULTIPLIER_HIT_SHAKE_DURATION, 1.0), Config.MULTIPLIER_HIT_SHAKE, Config.MULTIPLIER_HIT_TILT,
		Config.MULTIPLIER_HIT_CYCLES, Config.MULTIPLIER_HIT_VERTICAL_CYCLES, Config.MULTIPLIER_HIT_DECAY_POWER)
	return {"scale": lerpf(grow, 1.0, back), "position": shake.position, "rotation": shake.rotation}
