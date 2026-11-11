extends RefCounted

const Config = preload("res://src/configs/combo/combo_animation_config.gd")

# 索引採目前可見清單的順序，中心列由出場或 Hover 動畫自行處理。
static func plan(indices: Array[int], center: int, reach: int) -> Dictionary:
	var result := {}
	var affected: Array[int] = []
	for index in indices:
		var distance := absi(index - center)
		result[index] = {"strength": 0.0, "delay": 0.0}
		if distance > 0 and distance <= reach:
			affected.append(index)
	affected.sort_custom(func(a, b):
		var first := absi(a - center)
		var second := absi(b - center)
		return first < second if first != second else a < b)
	for order in affected.size():
		var index := affected[order]
		result[index] = {
			"strength": pow(Config.DISTURB_FALLOFF, absi(index - center) - 1),
			"delay": order * Config.DISTURB_INTERVAL,
		}
	return result

static func duration(cue: Dictionary) -> float:
	if cue.strength > 0.0:
		return maxf(Config.INSERT_PUSH_DURATION, cue.delay + Config.DISTURB_DURATION)
	return Config.INSERT_PUSH_DURATION

# x 為排列進度，y 為帶方向的擾動振幅；排列從共同起點即刻開始。
static func sample(time: float, cue: Dictionary) -> Vector2:
	var progress := clampf(time / Config.INSERT_PUSH_DURATION, 0.0, 1.0)
	var travel := 1.0 - pow(1.0 - progress, 3.0)
	var disturbance := clampf((time - cue.delay) / Config.DISTURB_DURATION, 0.0, 1.0)
	var wave := sin(disturbance * TAU * Config.DISTURB_CYCLES) * pow(1.0 - disturbance, Config.DECAY_POWER)
	return Vector2(travel, wave * cue.strength)
