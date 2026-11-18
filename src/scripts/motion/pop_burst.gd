extends RefCounted

const Shake = preload("res://src/service/motion/shake_motion.gd")

# 以 Back Out 放大到 peak，再以 Elastic 回到原尺寸，同時從中心播放衰減的旋轉抖動。
# profile：rise 放大時間、settle 回彈時間、shake 抖動時間、tilt 旋轉幅度、cycles 抖動次數、decay 衰減曲線。
# 進場時呼叫端先把 scale 設為零，即可從無到有彈出。
static func play(owner: Node, node: Control, peak: float, profile: Dictionary) -> void:
	node.pivot_offset = node.size / 2
	var grow := owner.create_tween()
	grow.tween_property(node, "scale", Vector2.ONE * peak, profile.rise).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	grow.tween_property(node, "scale", Vector2.ONE, profile.settle).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	owner.create_tween().tween_method(_shake.bind(node, profile), 0.0, 1.0, profile.shake)

static func _shake(progress: float, node: Control, profile: Dictionary) -> void:
	node.rotation = Shake.pose(progress, Vector2.ZERO, profile.tilt, profile.cycles, 0.0, profile.decay).rotation
