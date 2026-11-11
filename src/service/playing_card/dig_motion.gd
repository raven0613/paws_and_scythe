extends RefCounted

const Config = preload("res://src/configs/playing_card/action_animation_config.gd")

static func offset(progress: float, size: Vector2, side: float, duration: float) -> Vector2:
	var apex_ratio := progress * duration / Config.DIG_APEX_TIME
	return Vector2(side * size.x * Config.DIG_SIDE_WIDTH * progress,
		size.y * Config.DIG_RISE_HEIGHT * (apex_ratio * apex_ratio - 2.0 * apex_ratio))

static func time_to_drop(distance: float, card_height: float) -> float:
	return Config.DIG_APEX_TIME * (1.0 + sqrt(1.0 + distance / (card_height * Config.DIG_RISE_HEIGHT)))
