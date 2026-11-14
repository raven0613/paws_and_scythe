extends RefCounted

const Config = preload("res://src/configs/cat_cards/cat_activation_config.gd")

# 標籤到位時間，目標於此時開始跑數字。
static func arrival() -> float:
	return Config.BADGE_FLIGHT_DURATION + Config.BADGE_REBOUND_DURATION + Config.BADGE_SETTLE_DURATION

# 目標跑完並停留後開始收回。
static func release() -> float:
	return arrival() + Config.COUNT_DURATION + Config.RELEASE_HOLD

static func finish() -> float:
	return release() + maxf(Config.CARD_RETURN_DURATION, Config.BADGE_EXIT_DURATION)

# 收回進度，0 為發動姿態、1 為完全收回。
static func exit(time: float, duration: float) -> float:
	return clampf((time - release()) / duration, 0.0, 1.0)

static func ease_out(progress: float) -> float:
	return 1.0 - pow(1.0 - progress, 3.0)

static func back_out(progress: float, overshoot: float) -> float:
	var rest := progress - 1.0
	return 1.0 + (overshoot + 1.0) * pow(rest, 3.0) + overshoot * rest * rest

static func back_in(progress: float, overshoot: float) -> float:
	return (overshoot + 1.0) * pow(progress, 3.0) - overshoot * progress * progress
