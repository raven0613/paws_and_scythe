extends RefCounted

const Config = preload("res://src/configs/score/high_card_config.gd")
const Shake = preload("res://src/service/motion/shake_motion.gd")

# 從跳出到彈簧停止的時間，中央在此時開始加上該張點數。
static func lead() -> float:
	return Config.GROW_DURATION + Config.SPRING_DURATION

# time 為該 +N 跳出後經過的秒數：先以 Cubic Out 從零放大到原尺寸，再上下衰減彈簧震動，
# 往上時拉高變窄、往下時壓扁變寬；offset 為相對定位點的位移，彈完後回到原位與原形。
static func pose(time: float) -> Dictionary:
	if time < Config.GROW_DURATION:
		var size: float = Tween.interpolate_value(0.0, 1.0, maxf(time, 0.0), Config.GROW_DURATION, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		return {"scale": Vector2.ONE * size, "offset": Vector2.ZERO}
	var progress := minf((time - Config.GROW_DURATION) / Config.SPRING_DURATION, 1.0)
	var spring := Shake.pose(progress, Vector2.UP * Config.SPRING_AMPLITUDE, 0.0, 0.0, Config.SPRING_CYCLES, Config.SPRING_DECAY_POWER)
	var stretch: float = -spring.position.y / Config.SPRING_AMPLITUDE * Config.SPRING_STRETCH
	return {"scale": Vector2(1.0 - stretch, 1.0 + stretch), "offset": spring.position}

# 收回進度 0 到 1 的縮放：以 Back In 先微微脹大再縮到消失。
static func shrink(progress: float) -> float:
	return Tween.interpolate_value(1.0, -1.0, clampf(progress, 0.0, 1.0), 1.0, Tween.TRANS_BACK, Tween.EASE_IN)
