extends RefCounted

const Math = preload("res://src/service/motion/displacement_math.gd")

# 推移同時開始，範圍內的擾動依列距接續疊加；profile 的 distance、tilt 為最近一層的擾動位移與旋轉，
# lean_axis 決定旋轉跟隨位移方向的哪個分量。回傳各項的擾動排程，供呼叫端銜接其他回饋。
static func append(timeline: Tween, motions: Array[Dictionary], center: int, reach: int, profile: Dictionary) -> Dictionary:
	var indices: Array[int] = []
	for motion in motions:
		indices.append(motion.index)
	var cues := Math.plan(indices, center, reach, profile)
	for motion in motions:
		var cue: Dictionary = cues[motion.index]
		var duration := Math.duration(cue, profile)
		timeline.tween_method(_progress.bind(motion, cue, profile), 0.0, duration, duration)
	return cues

static func _progress(time: float, motion: Dictionary, cue: Dictionary, profile: Dictionary) -> void:
	var sample := Math.sample(time, cue, profile)
	var origin: Vector2 = motion.origin
	var direction: Vector2 = motion.direction
	motion.node.position = origin.lerp(motion.target, sample.x) + direction * profile.distance * sample.y
	motion.node.rotation = motion.rotation * (1.0 - sample.x) + profile.tilt * direction.dot(profile.lean_axis) * sample.y
