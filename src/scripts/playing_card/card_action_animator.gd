extends Node

const Config = preload("res://src/configs/playing_card/action_animation_config.gd")
const FlightConfig = preload("res://src/configs/playing_card/flight_animation_config.gd")
const Flight = preload("res://src/scripts/playing_card/flight/card_flight.gd")
const Math = preload("res://src/service/playing_card/flight_math.gd")
const DigMotion = preload("res://src/service/playing_card/dig_motion.gd")
var _dig_paths: Dictionary = {}
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func clear_paths() -> void:
	_dig_paths.clear()

func play_place(card: Control, destination: Transform2D, undo := false) -> void:
	var pose := _capture(card)
	var target: Transform2D = card.get_parent().get_global_transform_with_canvas().affine_inverse() * destination
	var target_position := target * card.pivot_offset - card.pivot_offset
	var duration: float = Config.UNDO_PLACE_DURATION if undo else Config.PLACE_FLIGHT_DURATION
	var enabled: bool = FlightConfig.UNDO_PLACE_ENABLED if undo else FlightConfig.PLACE_ENABLED
	var landing: Dictionary = FlightConfig.LIGHT_LANDING if undo else FlightConfig.PLACE_LANDING
	var flight := Flight.new(card, duration, enabled, landing)
	var timeline := create_tween().set_parallel()
	var move := _place_progress.bind(card, pose, target_position, target.get_scale(), target.get_rotation(), flight)
	timeline.tween_method(move, 0.0, 1.0, duration)
	flight.land(timeline, duration)
	await timeline.finished
	flight.finish()
	# 控制器在同一幀移交原卡牌，由目標容器排版。
	_restore(card, pose)

# 拖曳放開後從放開時的高度 lift 與擺動角度 tilt 接續：落入待放格時加速拍下並播放放牌落地回彈，
# returning 為飛回手牌槽位並播放輕量回彈。第一幀在呼叫當下套用，與拖曳最後的姿態無縫銜接。
func play_drop(card: Control, destination: Transform2D, lift: float, tilt: float, returning := false) -> void:
	var pose := _capture(card)
	var target: Transform2D = card.get_parent().get_global_transform_with_canvas().affine_inverse() * destination
	var target_position := target * card.pivot_offset - card.pivot_offset
	var duration: float = Config.DRAG_RETURN_DURATION if returning else Config.DROP_DURATION
	var landing: Dictionary = FlightConfig.LIGHT_LANDING if returning else FlightConfig.PLACE_LANDING
	var flight := Flight.new(card, duration, FlightConfig.DROP_ENABLED, landing)
	var move := _drop_progress.bind(card, pose, target_position, target.get_scale(), target.get_rotation(), lift, tilt, flight)
	move.call(0.0)
	var timeline := create_tween().set_parallel()
	timeline.tween_method(move, 0.0, 1.0, duration)
	flight.land(timeline, duration)
	await timeline.finished
	flight.finish()
	_restore(card, pose)

func play_swap(first: Control, second: Control, undo := false) -> void:
	var first_pose := _capture(first)
	var second_pose := _capture(second)
	var enabled: bool = FlightConfig.UNDO_SWAP_ENABLED if undo else FlightConfig.SWAP_ENABLED
	var duration: float = Config.UNDO_SWAP_DURATION if undo else Config.SWAP_DURATION
	var first_flight := Flight.new(first, duration, enabled, FlightConfig.LIGHT_LANDING)
	var second_flight := Flight.new(second, duration, enabled, FlightConfig.LIGHT_LANDING)
	first.z_index += 1
	var timeline := create_tween().set_parallel()
	var move := _swap_progress.bind(first, second, first_pose.position, second_pose.position,
		-1.0 if undo else 1.0, first_flight, second_flight)
	timeline.tween_method(move, 0.0, 1.0, duration)
	first_flight.land(timeline, duration)
	second_flight.land(timeline, duration)
	await timeline.finished
	first_flight.finish()
	second_flight.finish()
	_restore(first, first_pose)
	_restore(second, second_pose)

func play_dig(card: Control) -> void:
	var pose := _capture(card)
	var side := -1.0 if _rng.randi_range(0, 1) == 0 else 1.0
	var duration := _dig_duration(card, pose.position, side)
	_dig_paths[card.card_id] = {"side": side, "duration": duration}
	var timeline := create_tween().set_speed_scale(Config.DIG_SPEED)
	timeline.tween_method(_shake_progress.bind(card, pose.position), 0.0, 1.0, Config.DIG_SHAKE_DURATION)
	timeline.tween_method(_dig_progress.bind(card, pose.position, side, duration), 0.0, 1.0, duration / Config.DIG_EJECT_SPEED)
	await timeline.finished
	card.hide()
	_restore(card, pose)

func play_undo_dig(card: Control) -> void:
	var pose := _capture(card)
	var path: Dictionary = _dig_paths[card.card_id]
	_dig_paths.erase(card.card_id)
	# 鏡頭可在兩次操作之間移動；沿同一拋物線延伸起點至目前畫面下方。
	var parent_transform: Transform2D = card.get_parent().get_global_transform_with_canvas()
	var bottom := parent_transform.affine_inverse() * Vector2(0.0, card.get_viewport_rect().end.y)
	var top_at_origin: float = pose.position.y + card.pivot_offset.y - card.size.length() / 2.0
	var distance: float = bottom.y + Config.DIG_EXIT_MARGIN - top_at_origin
	var start := maxf(1.0, DigMotion.time_to_drop(maxf(distance, 0.0), card.size.y) / path.duration)
	_dig_progress(start, card, pose.position, path.side, path.duration)
	card.show()
	var duration: float = path.duration * start / Config.DIG_EJECT_SPEED / Config.DIG_SPEED / Config.UNDO_DIG_SPEED
	var flight := Flight.new(card, duration, FlightConfig.UNDO_DIG_ENABLED, FlightConfig.LIGHT_LANDING)
	var timeline := create_tween().set_parallel()
	timeline.tween_method(_undo_dig_progress.bind(card, pose.position, path, start, flight), 0.0, 1.0, duration)
	flight.land(timeline, duration)
	await timeline.finished
	flight.finish()
	_restore(card, pose)

func play_discard(cards: Array[Control]) -> void:
	var poses: Array[Dictionary] = []
	var flights: Array[RefCounted] = []
	var timeline := create_tween().set_parallel()
	for index in cards.size():
		var card := cards[index]
		var pose := _capture(card)
		poses.append(pose)
		var margin := card.size.length()
		var destination := Vector2(-margin, card.get_viewport_rect().end.y + margin)
		var parent_transform: Transform2D = card.get_parent().get_global_transform_with_canvas()
		var target: Vector2 = parent_transform.affine_inverse() * destination - card.pivot_offset
		var flight := Flight.new(card, Config.DISCARD_DURATION, FlightConfig.DISCARD_ENABLED)
		flights.append(flight)
		var move := _discard_progress.bind(card, pose.position, target, flight)
		timeline.tween_method(move, 0.0, 1.0, Config.DISCARD_DURATION).set_delay(index * Config.DISCARD_INTERVAL)
	await timeline.finished
	for index in cards.size():
		flights[index].finish()
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

func _place_progress(progress: float, card: Control, pose: Dictionary, target: Vector2,
		target_scale: Vector2, target_rotation: float, flight: RefCounted) -> void:
	var travel := Math.spring(progress)
	var lift := Math.lift(progress, Config.PLACE_APEX)
	card.position = pose.position.lerp(target, travel) + Vector2.UP * card.size.y * Config.PLACE_ARC_HEIGHT * lift
	card.scale = pose.scale.lerp(target_scale, travel)
	card.rotation = lerp_angle(pose.rotation, target_rotation, travel)
	flight.update(progress, lift)

# 高度由放開時的 lift 以二次曲線加速降到桌面，抵達時以最快速度觸地。
func _drop_progress(progress: float, card: Control, pose: Dictionary, target: Vector2, target_scale: Vector2,
		target_rotation: float, lift: float, tilt: float, flight: RefCounted) -> void:
	var travel := Math.spring(progress)
	card.position = pose.position.lerp(target, travel)
	card.scale = pose.scale.lerp(target_scale, travel)
	card.rotation = lerp_angle(tilt, target_rotation, travel)
	flight.update(progress, lift * (1.0 - progress * progress))

func _swap_progress(progress: float, first: Control, second: Control, from: Vector2, to: Vector2,
		side: float, first_flight: RefCounted, second_flight: RefCounted) -> void:
	var travel := Math.spring(progress)
	var normal := (to - from).normalized().orthogonal() * side
	var arc := normal * first.size.y * Config.SWAP_ARC_HEIGHT * sin(PI * travel)
	first.position = from.lerp(to, travel) + arc
	second.position = to.lerp(from, travel) - arc
	first.rotation = Config.SWAP_TILT * sin(PI * travel)
	second.rotation = -first.rotation
	first_flight.update(progress)
	second_flight.update(progress)

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
	# 以旋轉後牌面的上緣越過視窗底部為終點，解出拋物線的下落時間。
	return DigMotion.time_to_drop(distance, card.size.y)

func _dig_progress(progress: float, card: Control, origin: Vector2, side: float, duration: float) -> void:
	# 定加速度拋物線：頂點為原位上方牌高的 1/3，水平方向維持速度。
	card.position = origin + DigMotion.offset(progress, card.size, side, duration)
	card.rotation = side * Config.DIG_TILT * progress

func _undo_dig_progress(progress: float, card: Control, origin: Vector2, path: Dictionary,
		start: float, flight: RefCounted) -> void:
	_dig_progress((1.0 - progress) * start, card, origin, path.side, path.duration)
	flight.update(progress)

func _discard_progress(progress: float, card: Control, origin: Vector2, target: Vector2, flight: RefCounted) -> void:
	card.position = origin.lerp(target, progress * progress)
	card.rotation = Config.DISCARD_TILT * progress
	card.modulate.a = 1.0 - smoothstep(Config.DISCARD_FADE_START, 1.0, progress)
	flight.update(progress)
