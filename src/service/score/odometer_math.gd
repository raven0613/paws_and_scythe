extends RefCounted

const Config = preload("res://src/configs/score/odometer_config.gd")
const Feedback = preload("res://src/configs/score/score_feedback_config.gd")
const Motion = preload("res://src/service/score/number_motion.gd")

static func decimals(from: float, target: float, multiplier: bool) -> int:
	if not multiplier:
		return 0
	var factor := pow(Config.RADIX, Config.MULTIPLIER_MIN_DECIMALS)
	if is_equal_approx(from * factor, round(from * factor)) and is_equal_approx(target * factor, round(target * factor)):
		return Config.MULTIPLIER_MIN_DECIMALS
	return Config.MULTIPLIER_MAX_DECIMALS

static func units(value: float, precision: int) -> int:
	return roundi(value * pow(Config.RADIX, precision))

static func format_units(value: int, precision: int) -> String:
	var digits := str(absi(value)).pad_zeros(precision + 1)
	if precision > 0:
		digits = digits.insert(digits.length() - precision, ".")
	return ("-" if value < 0 else "") + digits

static func visible_places(value: float, precision: int) -> int:
	var whole := floori(absf(value))
	var incoming := whole + 1 if wheel(value, 0).y > 0.0 else whole
	return maxi(str(incoming).length(), precision + 1)

# 高位僅在低位即將進位時轉動，回退時沿同一輪軌跡反向播放。
static func wheel(value: float, place: int) -> Vector2:
	var magnitude := absf(value)
	var divisor := pow(Config.RADIX, place)
	var whole := floori(magnitude)
	var digit := int(whole / divisor) % Config.RADIX
	var remainder := fmod(magnitude, divisor)
	var phase := fmod(magnitude, 1.0) if place == 0 else maxf(0.0, remainder - (divisor - 1.0))
	var travel := smoothstep(Config.ROLL_START, 1.0, phase)
	return Vector2(digit, travel)

# 該位數平均轉速超過可讀速度的最後進度；前段與尾段各自等速，因此交接點落在段落邊界。
static func handoff(from: float, target: float, seconds: float, place: int) -> float:
	var scale := pow(Config.RADIX, place) * seconds
	if Motion.rate(from, target, 1.0) / scale > Config.READABLE_RATE:
		return 1.0
	if Motion.rate(from, target, 0.0) / scale > Config.READABLE_RATE:
		return Feedback.COUNT_MAIN_RATIO
	return 0.0

# 交接點前沿計數方向等速捲動，位置由交接點的實際輪位倒推，兩者在交接點精確相接。
static func reel(from: float, target: float, progress: float, seconds: float, place: int) -> Vector2:
	var handover := handoff(from, target, seconds, place)
	if progress >= handover:
		return wheel(Motion.value(from, target, progress), place)
	var anchor := wheel(Motion.value(from, target, handover), place)
	var direction := signf(absf(target) - absf(from))
	var position := anchor.x + anchor.y - direction * Config.SPIN_RATE * seconds * (handover - progress)
	return Vector2(fposmod(floorf(position), Config.RADIX), position - floorf(position))

static func detent(phase: float) -> Vector2:
	var snap := sin(clampf(phase / Config.DETENT_PORTION, 0.0, 1.0) * PI)
	return Vector2.ONE + Config.DETENT_SCALE * snap

static func wheel_detent(value: float, place: int, reverse: bool) -> Vector2:
	var phase := fposmod(absf(value) * (-1.0 if reverse else 1.0), pow(Config.RADIX, place))
	return detent(phase)
