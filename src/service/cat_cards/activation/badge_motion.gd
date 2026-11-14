extends RefCounted

const Config = preload("res://src/configs/cat_cards/cat_activation_config.gd")
const Timing = preload("res://src/service/cat_cards/activation/activation_timing.gd")
const Card = preload("res://src/service/cat_cards/activation/card_motion.gd")

# 標籤主體姿態，位置以卡片右上角為原點；spin 為相對到位角度的轉動，文字與尾巴的靜止方向跟隨它。
static func body(time: float) -> Dictionary:
	var angle := rotation(time)
	return {
		"position": path(time) + _landing_shake(time),
		"scale": scale(time),
		"rotation": angle,
		"spin": angle - Config.BADGE_ROTATION,
	}

# 起點為發動姿態的卡片中央。
static func origin() -> Vector2:
	return -Card.active_corner()

# 拋物線飛向牆面，撞牆後等速彈向左下，再彈向左上減速到位。
static func path(time: float) -> Vector2:
	var wall_time := Config.BADGE_FLIGHT_DURATION
	if time < wall_time:
		var flight := maxf(time, 0.0) / wall_time
		var arc := Vector2.UP * Config.BADGE_LAUNCH_ARC * 4.0 * flight * (1.0 - flight)
		return origin().lerp(Config.BADGE_WALL, flight) + arc
	var rebound_time := wall_time + Config.BADGE_REBOUND_DURATION
	if time < rebound_time:
		return Config.BADGE_WALL.lerp(Config.BADGE_REBOUND, (time - wall_time) / Config.BADGE_REBOUND_DURATION)
	var settle := Timing.ease_out(clampf((time - rebound_time) / Config.BADGE_SETTLE_DURATION, 0.0, 1.0))
	return Config.BADGE_REBOUND.lerp(Config.BADGE_REST, settle)

static func scale(time: float) -> float:
	var grow := Timing.ease_out(clampf(time / Config.BADGE_FLIGHT_DURATION, 0.0, 1.0))
	var landing := 1.0 + (Config.BADGE_LANDING_SCALE - 1.0) * _landing_lift(_landing(time))
	var exit := Timing.back_in(Timing.exit(time, Config.BADGE_EXIT_DURATION), Config.BADGE_EXIT_OVERSHOOT)
	return grow * landing * (1.0 - exit)

static func rotation(time: float) -> float:
	var flight := Timing.ease_out(clampf(time / Config.BADGE_FLIGHT_DURATION, 0.0, 1.0))
	return lerpf(Config.BADGE_LAUNCH_ROTATION, Config.BADGE_ROTATION, flight) + swing(time)

# 到位時的來回旋轉，逐漸衰減；尾巴依此擺動。
static func swing(time: float) -> float:
	var landing := _landing(time)
	return Config.BADGE_LANDING_ANGLE * _decay(landing) * sin(landing * Config.BADGE_LANDING_SWINGS * TAU)

# 到位後的進度，到位前為 0、結束後為 1。
static func _landing(time: float) -> float:
	return clampf((time - Timing.arrival()) / Config.BADGE_LANDING_DURATION, 0.0, 1.0)

static func _landing_lift(landing: float) -> float:
	if landing <= 0.0 or landing >= 1.0:
		return 0.0
	var peak := Config.BADGE_LANDING_PEAK
	if landing < peak:
		return sin(landing / peak * PI / 2)
	return 1.0 - Timing.ease_out((landing - peak) / (1.0 - peak))

static func _landing_shake(time: float) -> Vector2:
	var landing := _landing(time)
	var frequency := Config.BADGE_LANDING_FREQUENCY
	var local := time - Timing.arrival()
	return Config.BADGE_LANDING_SHAKE * _decay(landing) * Vector2(sin(local * frequency.x), sin(local * frequency.y))

static func _decay(landing: float) -> float:
	return pow(1.0 - landing, 2.0) if landing > 0.0 else 0.0
