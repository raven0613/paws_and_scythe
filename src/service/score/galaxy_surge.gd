extends RefCounted

const Config = preload("res://src/configs/score/galaxy_transition_config.gd")
const Feel = preload("res://src/configs/score/celebration_config.gd")

# 結算完成表演在撞擊前的蓄力長度，銀河等級才有蓄力。
static func lead(tier: int) -> float:
	return Config.CHARGE_DURATION if tier == Feel.Tier.GALAXY else 0.0

# 蓄力開始後 time 秒：flow 為彩虹流速倍率，brightness 為亮度提高比例，scale 為數字壓扁。
static func charge(time: float) -> Dictionary:
	var progress := clampf(time / Config.CHARGE_DURATION, 0.0, 1.0)
	return {
		"flow": lerpf(1.0, Config.CHARGE_FLOW, progress),
		"brightness": Config.CHARGE_BRIGHTNESS * progress,
		"scale": Vector2.ONE.lerp(Config.CHARGE_SQUASH, progress * (2.0 - progress)),
	}

# 撞頂後 since 秒：impact 為反轉幀，galaxy 為是否已換成銀河，fire 為火焰由彩虹組往銀河組的漸變比例。
static func pose(since: float) -> Dictionary:
	var galaxy := since >= Config.IMPACT_DURATION
	return {
		"impact": 0.0 if galaxy else 1.0,
		"galaxy": galaxy,
		"fire": smoothstep(0.0, 1.0, (since - Config.IMPACT_DURATION) / Config.FIRE_BLEND_DURATION),
	}
