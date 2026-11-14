extends RefCounted

const Config = preload("res://src/configs/score/score_feedback_config.gd")

# 依序入帳的時間表：各條依發射間隔出發，中央在粒子抵達時開始該段跑分；
# 中間各段長度等於發射間隔，使前一段跑完的同時下一條抵達，最後一段使用完整跑分時間。
static func build(count: int) -> Array:
	var schedule: Array = []
	for index in count:
		var launch := index * Config.AWARD_INTERVAL
		var seconds: float = Config.COUNT_DURATION if index == count - 1 else Config.AWARD_INTERVAL
		schedule.append({
			"launch": launch,
			"landing": launch + Config.AWARD_FLIGHT_DURATION,
			"seconds": seconds,
			"combo_seconds": minf(seconds, Config.COMBO_POP_UP + Config.COMBO_POP_DOWN),
		})
	return schedule

static func duration(schedule: Array) -> float:
	var last: Dictionary = schedule[-1]
	return last.landing + last.seconds

# 該時間已抵達中央的最後一條，尚未抵達時為 -1。
static func landed(schedule: Array, time: float) -> int:
	var result := -1
	for index in schedule.size():
		if time >= schedule[index].landing:
			result = index
	return result

static func progress(entry: Dictionary, time: float, seconds: float) -> float:
	return clampf((time - entry.landing) / seconds, 0.0, 1.0)
