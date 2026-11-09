extends Node

const Config = preload("res://src/configs/playing_card/action_animation_config.gd")
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func play_place(card: Control, destination: Transform2D) -> void:
	var pose := _capture(card)
	# 在手牌座標系內完成飛行，保留選取抬高的位置及其餘手牌槽位。
	var target: Transform2D = card.get_parent().get_global_transform_with_canvas().affine_inverse() * destination
	var target_position := target * card.pivot_offset - card.pivot_offset
	var timeline := create_tween()
	timeline.tween_method(_place_progress.bind(card, pose, target_position, target.get_scale(), target.get_rotation()), 0.0, 1.0, Config.PLACE_FLIGHT_DURATION)
	timeline.tween_property(card, "scale", target.get_scale() * Config.PLACE_PRESS_SCALE, Config.PLACE_PRESS_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	timeline.tween_property(card, "scale", target.get_scale(), Config.PLACE_RELEASE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await timeline.finished
	# 控制器在同一幀將原卡牌移交盤面，沿用盤面的正常局部尺寸。
	_restore(card, pose)

func play_swap(first: Control, second: Control) -> void:
	var first_pose := _capture(first)
	var second_pose := _capture(second)
	first.z_index += 1
	var timeline := create_tween()
	timeline.tween_method(_swap_progress.bind(first, second, first_pose.position, second_pose.position), 0.0, 1.0, Config.SWAP_DURATION)
	await timeline.finished
	_restore(first, first_pose)
	_restore(second, second_pose)

func play_dig(card: Control) -> void:
	var pose := _capture(card)
	var side := -1.0 if _rng.randi_range(0, 1) == 0 else 1.0
	var duration := _dig_duration(card, pose.position, side)
	var timeline := create_tween()
	timeline.tween_method(_shake_progress.bind(card, pose.position), 0.0, 1.0, Config.DIG_SHAKE_DURATION)
	timeline.tween_method(_dig_progress.bind(card, pose.position, side, duration), 0.0, 1.0, duration)
	await timeline.finished
	card.hide()
	_restore(card, pose)

func play_discard(cards: Array[Control]) -> void:
	var poses: Array[Dictionary] = []
	var timeline := create_tween().set_parallel()
	for index in cards.size():
		var card := cards[index]
		var pose := _capture(card)
		poses.append(pose)
		var margin := card.size.length()
		var destination := Vector2(-margin, card.get_viewport_rect().end.y + margin)
		var target: Vector2 = card.get_parent().get_global_transform_with_canvas().affine_inverse() * destination
		timeline.tween_method(_discard_progress.bind(card, pose.position, target), 0.0, 1.0, Config.DISCARD_DURATION).set_delay(index * Config.DISCARD_INTERVAL)
	await timeline.finished
	for index in cards.size():
		cards[index].hide()
		_restore(cards[index], poses[index])

func _capture(card: Control) -> Dictionary:
	var pose := {"position": card.position, "rotation": card.rotation,
		"scale": card.scale, "modulate": card.modulate, "z_index": card.z_index}
	card.selection_enabled = false
	card.set_marks([])
	card.z_index = Config.FLIGHT_LAYER
	return pose

func _restore(card: Control, pose: Dictionary) -> void:
	card.position = pose.position
	card.rotation = pose.rotation
	card.scale = pose.scale
	card.modulate = pose.modulate
	card.z_index = pose.z_index

func _place_progress(progress: float, card: Control, pose: Dictionary, target: Vector2, target_scale: Vector2, target_rotation: float) -> void:
	var travel := 1.0 - pow(1.0 - progress, 3.0)
	var arc := Vector2.UP * card.size.y * Config.PLACE_ARC_HEIGHT * sin(PI * travel)
	card.position = pose.position.lerp(target, travel) + arc
	card.scale = pose.scale.lerp(target_scale, travel)
	card.rotation = lerp_angle(pose.rotation, target_rotation, travel)

func _swap_progress(progress: float, first: Control, second: Control, from: Vector2, to: Vector2) -> void:
	var travel := smoothstep(0.0, 1.0, progress)
	var normal := (to - from).normalized().orthogonal()
	var arc := normal * first.size.y * Config.SWAP_ARC_HEIGHT * sin(PI * travel)
	first.position = from.lerp(to, travel) + arc
	second.position = to.lerp(from, travel) - arc
	first.rotation = Config.SWAP_TILT * sin(PI * travel)
	second.rotation = -first.rotation

func _shake_progress(progress: float, card: Control, origin: Vector2) -> void:
	var shake := sin(progress * TAU * Config.DIG_SHAKE_CYCLES) * (1.0 - progress)
	card.position = origin + Vector2(card.size.x * Config.DIG_SHAKE_WIDTH * shake, 0.0)
	card.rotation = Config.DIG_SHAKE_TILT * shake

func _dig_duration(card: Control, origin: Vector2, side: float) -> float:
	var parent_transform: Transform2D = card.get_parent().get_global_transform_with_canvas()
	var bottom := parent_transform.affine_inverse() * Vector2(0.0, card.get_viewport_rect().end.y)
	var final_transform := Transform2D(side * Config.DIG_TILT, card.scale, 0.0, Vector2.ZERO)
	var bounds := final_transform * Rect2(-card.pivot_offset, card.size)
	var distance := bottom.y + Config.DIG_EXIT_MARGIN - (origin.y + card.pivot_offset.y + bounds.position.y)
	var height := card.size.y * Config.DIG_RISE_HEIGHT
	# 以旋轉後牌面的上緣越過視窗底部為終點，解出拋物線的下落時間。
	return Config.DIG_APEX_TIME * (1.0 + sqrt(1.0 + distance / height))

func _dig_progress(progress: float, card: Control, origin: Vector2, side: float, duration: float) -> void:
	# 定加速度拋物線：頂點為原位上方牌高的 1/3，水平方向維持速度。
	var time := progress * duration
	var apex_ratio := time / Config.DIG_APEX_TIME
	var height := card.size.y * Config.DIG_RISE_HEIGHT
	var offset := Vector2(side * card.size.x * Config.DIG_SIDE_WIDTH * progress,
		height * (apex_ratio * apex_ratio - 2.0 * apex_ratio))
	card.position = origin + offset
	card.rotation = side * Config.DIG_TILT * progress

func _discard_progress(progress: float, card: Control, origin: Vector2, target: Vector2) -> void:
	card.position = origin.lerp(target, progress * progress)
	card.rotation = Config.DISCARD_TILT * progress
	card.modulate.a = 1.0 - smoothstep(Config.DISCARD_FADE_START, 1.0, progress)
