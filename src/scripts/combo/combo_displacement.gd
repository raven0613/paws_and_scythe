extends RefCounted

const Config = preload("res://src/configs/combo/combo_animation_config.gd")
const Math = preload("res://src/service/combo/displacement_math.gd")

# 推移同時開始，範圍內的擾動依可見列距接續疊加。
static func append(timeline: Tween, motions: Array[Dictionary], center: int, reach: int) -> void:
	var indices: Array[int] = []
	for motion in motions:
		indices.append(motion.index)
	var cues := Math.plan(indices, center, reach)
	for motion in motions:
		var cue: Dictionary = cues[motion.index]
		var duration := Math.duration(cue)
		timeline.tween_method(_progress.bind(motion, cue), 0.0, duration, duration)

static func _progress(time: float, motion: Dictionary, cue: Dictionary) -> void:
	var sample := Math.sample(time, cue)
	var origin: Vector2 = motion.origin
	motion.node.position = origin.lerp(motion.target, sample.x) + motion.direction * Config.DISTURB_DISTANCE * sample.y
	motion.node.rotation = motion.rotation * (1.0 - sample.x) + Config.DISTURB_TILT * motion.direction.y * sample.y
