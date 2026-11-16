extends RefCounted

# 排列推移與 DISTURB 擾動的純計算，combo 清單與操作按鈕各自提供 profile：
# falloff 每遠一層的強度倍率、interval 接續間隔、push_duration 推移時間、disturb_duration 擾動時間、
# cycles 擾動次數、decay_power 衰減曲線。
# 索引採目前可見清單的順序，中心項目由自身的出場或 Hover 動畫處理。
static func plan(indices: Array[int], center: int, reach: int, profile: Dictionary) -> Dictionary:
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
			"strength": pow(profile.falloff, absi(index - center) - 1),
			"delay": order * profile.interval,
		}
	return result

static func duration(cue: Dictionary, profile: Dictionary) -> float:
	if cue.strength > 0.0:
		return maxf(profile.push_duration, cue.delay + profile.disturb_duration)
	return profile.push_duration

# x 為排列進度，y 為帶方向的擾動振幅；排列從共同起點即刻開始。
static func sample(time: float, cue: Dictionary, profile: Dictionary) -> Vector2:
	var progress := clampf(time / profile.push_duration, 0.0, 1.0)
	var travel := 1.0 - pow(1.0 - progress, 3.0)
	var disturbance := clampf((time - cue.delay) / profile.disturb_duration, 0.0, 1.0)
	var wave := sin(disturbance * TAU * profile.cycles) * pow(1.0 - disturbance, profile.decay_power)
	return Vector2(travel, wave * cue.strength)
