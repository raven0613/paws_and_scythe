extends RefCounted

const Config = preload("res://src/configs/level_board/progress_flare_config.gd")
const Feel = preload("res://src/configs/score/celebration_config.gd")

# 依表演等級取用進度條入帳的數值，銀河使用較誇張的一組。
static func params(tier: int) -> Dictionary:
	return Config.GALAXY if tier == Feel.Tier.GALAXY else Config.HOLOGRAPHIC

# flare 為 params() 取得的等級數值；跑分 duration 秒期間經過 time 秒的進度條姿態：position、rotation 為相對原位的震動，scale 為放大倍率，glow 為 0 到 1 的發光強度。
static func pose(time: float, duration: float, flare: Dictionary) -> Dictionary:
	var strength := _strength(time, duration)
	var frequency: Vector3 = flare.frequency
	var grow: float = Tween.interpolate_value(1.0, flare.scale - 1.0, minf(time, Config.ATTACK), Config.ATTACK, Tween.TRANS_BACK, Tween.EASE_OUT)
	var release := clampf((time - (duration - Config.RELEASE)) / Config.RELEASE, 0.0, 1.0)
	var back: float = Tween.interpolate_value(0.0, 1.0, release, 1.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	return {
		"position": flare.shake * strength * Vector2(sin(time * frequency.x), sin(time * frequency.y)),
		"rotation": flare.tilt * strength * sin(time * frequency.z),
		"scale": lerpf(grow, 1.0, back),
		"glow": Tween.interpolate_value(0.0, 1.0, minf(time, Config.GLOW_RISE), Config.GLOW_RISE, Tween.TRANS_CUBIC, Tween.EASE_OUT),
	}

# 震動強度：ATTACK 內增強到滿幅，結束前 RELEASE 內加速衰減，duration 時歸零。
static func _strength(time: float, duration: float) -> float:
	var attack := clampf(time / Config.ATTACK, 0.0, 1.0)
	var release := clampf((duration - time) / Config.RELEASE, 0.0, 1.0)
	return attack * release * release
