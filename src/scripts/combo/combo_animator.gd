extends Node

const Displacement = preload("res://src/scripts/motion/displacement.gd")
const Config = preload("res://src/configs/combo/combo_animation_config.gd")

func retire(rows: Array[Control]) -> void:
	if rows.is_empty():
		return
	var timeline := create_tween().set_parallel()
	for index in rows.size():
		var row := rows[index]
		var delay := index * Config.EXIT_INTERVAL
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		timeline.tween_property(row, "scale", Vector2.ONE * Config.EXIT_SCALE, Config.EXIT_RISE_DURATION).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		timeline.tween_property(row, "scale", Vector2.ZERO, Config.EXIT_SHRINK_DURATION).from(Vector2.ONE * Config.EXIT_SCALE).set_delay(delay + Config.EXIT_RISE_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await timeline.finished

func reflow(rows: Array[Control], targets: Array[Vector2]) -> void:
	var moving: Array[int] = []
	for index in rows.size():
		if rows[index].visible and not rows[index].position.is_equal_approx(targets[index]):
			moving.append(index)
		elif not rows[index].visible:
			rows[index].position = targets[index]
	if moving.is_empty():
		return
	var timeline := create_tween().set_parallel()
	for order in moving.size():
		var index := moving[order]
		var row := rows[index]
		var target := targets[index]
		var delay := order * Config.REFLOW_INTERVAL
		timeline.tween_property(row, "position", target, Config.REFLOW_DURATION).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		timeline.tween_method(_settle_progress.bind(row, target), 0.0, 1.0, Config.SETTLE_DURATION).set_delay(delay + Config.REFLOW_DURATION)
	await timeline.finished
	for index in moving:
		rows[index].position = targets[index]

func reveal(row: Control, rows: Array[Control], targets: Array[Vector2]) -> Tween:
	row.show()
	row.scale = Vector2.ZERO
	var origin := row.position
	var layer := row.z_index
	row.z_index = Config.POP_LAYER
	var timeline := create_tween().set_parallel()
	timeline.tween_method(_pop_progress.bind(row, origin), 0.0, 1.0, Config.POP_DURATION)
	var others: Array[Dictionary] = []
	var center := origin + row.size / 2
	var visible_rows := rows.filter(func(item): return item.visible)
	for index in rows.size():
		var other := rows[index]
		if other != row and other.visible:
			var offset := targets[index] + other.size / 2 - center
			others.append({"node": other, "origin": other.position, "target": targets[index], "rotation": other.rotation,
				"direction": offset.normalized(), "index": visible_rows.find(other)})
	Displacement.append(timeline, others, visible_rows.find(row), Config.INSERT_DISTURB_COUNT, Config.DISTURB_PROFILE)
	timeline.chain().tween_callback(func():
		row.position = origin
		row.scale = Vector2.ONE
		row.rotation = 0.0
		row.z_index = layer
		for other in others:
			other.node.position = other.target
			other.node.rotation = 0.0)
	return timeline

func _pop_progress(progress: float, row: Control, origin: Vector2) -> void:
	var pop: float = Tween.interpolate_value(0.0, 1.0, progress, 1.0, Tween.TRANS_BACK, Tween.EASE_OUT)
	var envelope := pow(1.0 - progress, Config.DECAY_POWER)
	var wave := sin(progress * TAU * Config.POP_CYCLES)
	var stretch := Config.POP_STRETCH * sin(PI * progress) * envelope
	row.scale = Vector2(1.0 + stretch, 1.0 - stretch) * pop
	row.rotation = Config.POP_TILT * wave * envelope
	row.position = origin + Config.POP_SHAKE * Vector2(wave, sin(progress * TAU * Config.POP_VERTICAL_CYCLES)) * envelope

func _settle_progress(progress: float, row: Control, target: Vector2) -> void:
	var wave := sin(progress * TAU * Config.SETTLE_CYCLES) * pow(1.0 - progress, Config.DECAY_POWER)
	row.position = target + Vector2.UP * Config.SETTLE_DISTANCE * wave
