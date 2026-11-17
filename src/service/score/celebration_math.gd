extends RefCounted

const Config = preload("res://src/configs/score/celebration_config.gd")
const Slam = preload("res://src/service/score/slam_math.gd")
const Surge = preload("res://src/service/score/galaxy_surge.gd")

# 依最終分數相對關卡目標的倍數決定表演等級，forced 為至少使用的等級。
static func tier(total: float, level_target: float, forced: int = Config.FORCE_HIGH_SCORE) -> int:
	var earned := Config.Tier.NORMAL
	if total >= level_target * Config.GALAXY_SCORE_RATIO:
		earned = Config.Tier.GALAXY
	elif total >= level_target * Config.HIGH_SCORE_RATIO:
		earned = Config.Tier.HOLOGRAPHIC
	return maxi(earned, forced)

static func central_change(event: Dictionary) -> bool:
	var central: bool = event.kind in ["high", "group_award", "combo_apply"] or (event.kind == "effect" and event.get("target", "") in ["subtotal", "total"])
	return central and event.before != event.after

static func last_central_event(events: Array) -> int:
	for index in range(events.size() - 1, -1, -1):
		if central_change(events[index]):
			return index
	return -1

static func energy(value: float, total: float) -> float:
	return smoothstep(Config.ENERGY_START, Config.ENERGY_FULL, value / total) if total > 0.0 else 0.0

# 高分的結算完成表演為撞擊時間軸，銀河等級在撞擊前加上蓄力。
static func duration(tier: int, final: bool) -> float:
	var high := tier != Config.Tier.NORMAL
	if final and high:
		return Surge.lead(tier) + Slam.duration()
	return Config.FINAL_DURATION if final else (Config.HIGH_STEP_DURATION if high else Config.STEP_DURATION)

static func impact(progress: float, high: bool, final: bool) -> Dictionary:
	var amplitude: float = Config.FINAL_SCALE if final else (Config.HIGH_STEP_SCALE if high else Config.STEP_SCALE)
	var tilt: float = Config.FINAL_TILT if final else (Config.HIGH_STEP_TILT if high else Config.STEP_TILT)
	var shake: Vector2 = Config.FINAL_SHAKE if final else (Config.HIGH_STEP_SHAKE if high else Config.STEP_SHAKE)
	var pop := sin(clampf(progress / Config.IMPACT_PEAK, 0.0, 1.0) * PI / 2) if progress < Config.IMPACT_PEAK else pow((1.0 - progress) / (1.0 - Config.IMPACT_PEAK), Config.IMPACT_DECAY)
	var wave := sin(progress * TAU * Config.IMPACT_CYCLES) * pow(1.0 - progress, Config.IMPACT_DECAY)
	return {"position": shake * Vector2(wave, -wave), "scale": Vector2.ONE * lerpf(1.0, amplitude, pop), "rotation": tilt * wave}
