extends RefCounted

const Config = preload("res://src/configs/cat_cards/cat_activation_config.gd")
const Feedback = preload("res://src/configs/cat_cards/cat_feedback_config.gd")
const Timing = preload("res://src/service/cat_cards/activation/activation_timing.gd")

# 卡片姿態，位置相對原本貓牌中心：offset 與 rotation 含抖動；anchor 為不含抖動的卡片右上角，作為標籤原點。
static func pose(time: float) -> Dictionary:
	var strength := _strength(time)
	var fade := pow(1.0 - clampf(time / Config.CARD_SHAKE_DURATION, 0.0, 1.0), 2.0) * (1.0 - _back(time))
	var frequency := Config.CARD_SHAKE_FREQUENCY
	var scale := lerpf(1.0, Config.CARD_SCALE, strength)
	var rotation := Config.CARD_ROTATION * strength
	var move := Config.CARD_OFFSET * strength
	return {
		"offset": move + Config.CARD_SHAKE_OFFSET * fade * Vector2(sin(time * frequency.x), sin(time * frequency.y)),
		"scale": scale,
		"rotation": rotation + Config.CARD_SHAKE_ANGLE * fade * sin(time * frequency.z),
		"tilt": Config.CARD_TILT * strength,
		"anchor": move + corner(scale, rotation),
	}

# 影子相對卡面的位置，隨放大由 rest 移到 CARD_SHADOW_OFFSET，收回時移回。
static func shadow(rest: Vector2, time: float) -> Vector2:
	return rest.lerp(Config.CARD_SHADOW_OFFSET, _strength(time))

# 發動強度，0 為原本姿態、1 為發動姿態，放大時衝過頭。
static func _strength(time: float) -> float:
	var pop := Timing.back_out(clampf(time / Config.CARD_POP_DURATION, 0.0, 1.0), Config.CARD_POP_OVERSHOOT)
	return pop * (1.0 - _back(time))

static func _back(time: float) -> float:
	return ease(Timing.exit(time, Config.CARD_RETURN_DURATION), Config.CARD_RETURN_EASE)

static func corner(scale: float, rotation: float) -> Vector2:
	return (Vector2(Feedback.CARD_SIZE.x, -Feedback.CARD_SIZE.y) / 2 * scale).rotated(rotation)

static func active_corner() -> Vector2:
	return corner(Config.CARD_SCALE, Config.CARD_ROTATION)

static func finished(time: float) -> bool:
	return time >= Timing.finish()
