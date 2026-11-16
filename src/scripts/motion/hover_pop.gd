extends RefCounted

const Shake = preload("res://src/service/motion/shake_motion.gd")

# Hover 放大與抖動，combo 條與操作按鈕各自提供 profile：scale 放大倍率、scale_duration 放大時間、
# shake_duration 抖動時間、shake 位移幅度、tilt 旋轉幅度、cycles／vertical_cycles 橫縱抖動次數、
# decay_power 衰減曲線、release_duration 恢復時間、layer 停留圖層。visual 以自身 pivot 縮放與旋轉。

# 進入時以 Back Out 放大，同時從目前姿態播放衰減的位移與旋轉抖動；停留時維持放大。
static func enter(owner: Node, visual: Control, profile: Dictionary, speed := 1.0) -> Tween:
	visual.z_index = profile.layer
	var timeline := owner.create_tween().set_parallel().set_speed_scale(speed)
	timeline.tween_property(visual, "scale", Vector2.ONE * profile.scale, profile.scale_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	timeline.tween_method(_shake.bind(visual, visual.position, visual.rotation, profile), 0.0, 1.0, profile.shake_duration)
	return timeline

# 離開時平滑恢復尺寸、位置與角度，完成後回到原圖層。
static func release(owner: Node, visual: Control, profile: Dictionary, speed := 1.0) -> Tween:
	var timeline := owner.create_tween().set_parallel().set_speed_scale(speed).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	timeline.tween_property(visual, "scale", Vector2.ONE, profile.release_duration)
	timeline.tween_property(visual, "position", Vector2.ZERO, profile.release_duration)
	timeline.tween_property(visual, "rotation", 0.0, profile.release_duration)
	timeline.chain().tween_callback(func(): visual.z_index = 0)
	return timeline

static func rest(visual: Control) -> void:
	visual.scale = Vector2.ONE
	visual.position = Vector2.ZERO
	visual.rotation = 0.0
	visual.z_index = 0

static func _shake(progress: float, visual: Control, from: Vector2, rotation_from: float, profile: Dictionary) -> void:
	var pose := Shake.pose(progress, profile.shake, profile.tilt, profile.cycles, profile.vertical_cycles, profile.decay_power)
	visual.position = from * pose.decay + pose.position
	visual.rotation = rotation_from * pose.decay + pose.rotation
