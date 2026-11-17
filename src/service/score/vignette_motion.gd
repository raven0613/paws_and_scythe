extends RefCounted

const Config = preload("res://src/configs/score/galaxy_transition_config.gd")
const Slam = preload("res://src/service/score/slam_math.gd")

# 撞頂後 since 秒的暗角：由最緊處猛地彈開並閃爍，再依收尾設定散去或留下淡暗角。
static func pose(since: float) -> Dictionary:
	var opened := lerpf(Config.VIGNETTE_RADIUS, Config.VIGNETTE_BURST_RADIUS, _ease_out(since / Config.VIGNETTE_BURST_DURATION))
	var settle := smoothstep(0.0, 1.0, since / Config.VIGNETTE_FADE_DURATION)
	var flicker := 1.0 + Config.VIGNETTE_FLICKER * sin(TAU * Config.VIGNETTE_FLICKER_FREQUENCY * since) * Slam.fade(since, Config.VIGNETTE_FLICKER_DURATION)
	if Config.VIGNETTE_AFTERGLOW == Config.Afterglow.LINGER:
		return {"radius": lerpf(opened, Config.VIGNETTE_LINGER_RADIUS, settle),
			"intensity": lerpf(Config.VIGNETTE_INTENSITY, Config.VIGNETTE_LINGER_INTENSITY, settle) * flicker}
	return {"radius": opened, "intensity": Config.VIGNETTE_INTENSITY * (1.0 - settle) * flicker}

static func _ease_out(p: float) -> float:
	var clamped := clampf(p, 0.0, 1.0)
	return clamped * (2.0 - clamped)
