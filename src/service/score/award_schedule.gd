extends RefCounted

const Config = preload("res://src/configs/score/score_feedback_config.gd")

# 依序入帳的時間表：各項每隔 interval 出發，經過 lead 後抵達，中央在抵達時開始該段跑分；
# 中間各段長度等於出發間隔，使前一段跑完的同時下一項抵達，最後一段使用完整跑分時間。
# Combo 條入帳使用粒子發射間隔與飛行時間，高牌保底使用 +N 的跳出間隔與彈出時間。
static func build(count: int, interval: float, lead: float) -> Array:
	var schedule: Array = []
	for index in count:
		var launch := index * interval
		schedule.append({
			"launch": launch,
			"landing": launch + lead,
			"seconds": Config.COUNT_DURATION if index == count - 1 else interval,
		})
	return schedule

static func duration(schedule: Array) -> float:
	var last: Dictionary = schedule[-1]
	return last.landing + last.seconds

# Combo 組數的推進回饋在該段跑分內完成。
static func combo_seconds(entry: Dictionary) -> float:
	return minf(entry.seconds, Config.COMBO_POP_UP + Config.COMBO_POP_DOWN)

# 該時間已抵達中央的最後一項，尚未抵達時為 -1。
static func landed(schedule: Array, time: float) -> int:
	var result := -1
	for index in schedule.size():
		if time >= schedule[index].landing:
			result = index
	return result

static func progress(entry: Dictionary, time: float, seconds: float) -> float:
	return clampf((time - entry.landing) / seconds, 0.0, 1.0)
