extends RefCounted

const Config = preload("res://src/configs/playing_card/card_hover_config.gd")

# 呼吸一次的縮放：從 from 以 Quart Out 放大到 BREATH_SCALE，再以 Sine In Out 縮回 1；
# from 為開始時的縮放，呼吸途中重新進入時由當下尺寸接續。
static func scale(time: float, from: float) -> float:
	if time < Config.BREATH_UP:
		return Tween.interpolate_value(from, Config.BREATH_SCALE - from, time, Config.BREATH_UP, Tween.TRANS_QUART, Tween.EASE_OUT)
	var elapsed := minf(time - Config.BREATH_UP, Config.BREATH_DOWN)
	return Tween.interpolate_value(Config.BREATH_SCALE, 1.0 - Config.BREATH_SCALE, elapsed, Config.BREATH_DOWN, Tween.TRANS_SINE, Tween.EASE_IN_OUT)

static func finished(time: float) -> bool:
	return time >= Config.BREATH_UP + Config.BREATH_DOWN

# 左上角為原點的卡面以 pivot 為中心縮放時，visual 需要的位置偏移。
static func offset(scale: float, pivot: Vector2) -> Vector2:
	return pivot * (1.0 - scale)
