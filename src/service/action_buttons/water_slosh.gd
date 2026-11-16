extends RefCounted

const Config = preload("res://src/configs/action_buttons/action_button_motion_config.gd")
# tilt 為水面斜率，正值代表左側較高；velocity 為斜率變化速度；chop 為碎浪能量。
const REST = {"tilt": 0.0, "velocity": 0.0, "chop": 0.0}

# impulse 為帶方向的甩動強度，正值代表箱子向右甩，水因慣性往左側堆高；強度 1 的擺盪峰值約為 SLOSH_TILT。
static func kick(state: Dictionary, impulse: float) -> Dictionary:
	return {
		"tilt": state.tilt,
		"velocity": state.velocity + impulse * Config.SLOSH_TILT * _omega(),
		"chop": minf(Config.SLOSH_CHOP_MAX, state.chop + absf(impulse)),
	}

# 斜率以阻尼彈簧擺盪回到水平，碎浪能量依時間常數指數衰減；固定子步長讓不同幀率呈現相同的擺盪。
static func step(state: Dictionary, delta: float) -> Dictionary:
	var omega := _omega()
	var tilt: float = state.tilt
	var velocity: float = state.velocity
	var remaining := delta
	while remaining > 0.0:
		var dt := minf(remaining, Config.SLOSH_STEP)
		velocity += (-omega * omega * tilt - 2.0 * Config.SLOSH_DAMPING * omega * velocity) * dt
		tilt += velocity * dt
		remaining -= dt
	return {"tilt": tilt, "velocity": velocity, "chop": state.chop * exp(-delta / Config.SLOSH_CHOP_CALM)}

static func is_calm(state: Dictionary) -> bool:
	return absf(state.tilt) < Config.SLOSH_REST_EPSILON and absf(state.velocity) < Config.SLOSH_REST_EPSILON * _omega() \
		and state.chop < Config.SLOSH_REST_EPSILON

static func _omega() -> float:
	return TAU * Config.SLOSH_FREQUENCY
