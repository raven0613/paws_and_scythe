@tool
extends Control

signal group_hovered(cells: Array)

const Config = preload("res://src/configs/combo/combo_config.gd")
const Entry = preload("res://src/configs/combo/combo_entry.gd")
const Sequence = preload("res://src/service/combo/combo_sequence.gd")
const Transition = preload("res://src/service/combo/group_transition.gd")
const Animator = preload("res://src/scripts/combo/combo_animator.gd")
const IdleAnimator = preload("res://src/scripts/combo/combo_idle_animator.gd")
const RowScene = preload("res://src/scenes/combo/combo_row.tscn")

@export var preview_entries: Array[Entry] = []:
	set(value):
		preview_entries = value
		if Engine.is_editor_hint() and is_node_ready():
			_sync_entries(value)

var entries: Array[Entry]:
	get:
		return _entries
	set(value):
		_sync_entries(value)

@export var frame_color: Color = Config.FRAME_COLOR:
	set(value):
		frame_color = value
		_refresh_rows()
@export var text_color: Color = Config.TEXT_COLOR:
	set(value):
		text_color = value
		_refresh_rows()
@export var score_color: Color = Config.SCORE_COLOR:
	set(value):
		score_color = value
		_refresh_rows()
@export var shadow_color: Color = Config.SHADOW_COLOR:
	set(value):
		shadow_color = value
		_refresh_rows()

var _sequence = Sequence.new()
var _layouts: Array[Dictionary] = []
var _animator = Animator.new()
var _idle: Node
var _entries: Array[Entry] = []
var _rows: Array[Control] = []
var _transitioning := false
var _updating := false


func _ready() -> void:
	add_child(_animator)
	if not Engine.is_editor_hint():
		_idle = IdleAnimator.new()
		add_child(_idle)
	_sequence.reset(Config.EDITOR_SEED if Engine.is_editor_hint() else randi())
	if Engine.is_editor_hint():
		_sync_entries(preview_entries)
	else:
		var initial := _entries
		_entries = []
		_sync_entries(initial)
	clip_contents = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func add_result(hand_name: String, score: float) -> void:
	var entry := Entry.new()
	entry.hand_name = hand_name
	entry.score = score
	var updated := entries.duplicate()
	updated.append(entry)
	entries = updated


func clear_results() -> void:
	var empty: Array[Entry] = []
	entries = empty


func _watch_entries(previous: Array[Entry], current: Array[Entry]) -> void:
	for entry in previous:
		if entry != null and entry.changed.is_connected(_refresh_rows):
			entry.changed.disconnect(_refresh_rows)
	for entry in current:
		if entry != null and not entry.changed.is_connected(_refresh_rows):
			entry.changed.connect(_refresh_rows)


# 即時同步供開局、換關與結算更新使用；盤面操作由 transition_to 排程。
func _sync_entries(value: Array[Entry]) -> void:
	if not is_node_ready():
		_entries = value
		return
	var next: Array[Entry] = value.filter(func(entry): return entry != null)
	var plan := Transition.compare(_entries, next)
	_remove_rows(plan.removed)
	_adopt_entries(next, plan.previous, false)
	_layout_rows()

func transition_to(value: Array[Entry]) -> Array:
	_transitioning = true
	var plan := Transition.compare(_entries, value)
	var retiring: Array[Control] = []
	for index in plan.removed:
		retiring.append(_rows[index])
	await _animator.retire(retiring)
	_remove_rows(plan.removed)
	_adopt_entries(value, plan.previous, true)
	await _animator.reflow(_rows, _layout_targets())
	_transitioning = false
	_layout_rows()
	return plan.added

func reveal(index: int) -> Tween:
	_transitioning = true
	_rows[index].show()
	_refresh_rows()
	var targets := _layout_targets()
	_rows[index].position = targets[index]
	var motion: Tween = _animator.reveal(_rows[index], _rows, targets)
	motion.finished.connect(_finish_reveal)
	return motion

func _finish_reveal() -> void:
	_transitioning = false
	_layout_rows()

func _remove_rows(indices: Array) -> void:
	for index in indices:
		var row := _rows[index]
		if not Engine.is_editor_hint():
			_idle.forget(row)
		$rows.remove_child(row)
		row.queue_free()

func _adopt_entries(value: Array[Entry], previous: Array, hide_new: bool) -> void:
	_updating = true
	var old_rows := _rows.duplicate()
	_watch_entries(_entries, value)
	_entries = value
	_rows.clear()
	_layouts = _sequence.resolve(_layouts, previous)
	for index in value.size():
		var row: Control
		if previous[index] >= 0:
			row = old_rows[previous[index]]
		else:
			row = RowScene.instantiate()
			$rows.add_child(row)
			row.visible = not hide_new
			row.minimum_size_changed.connect(_layout_rows)
			row.mouse_filter = Control.MOUSE_FILTER_PASS
			row.mouse_entered.connect(_on_row_entered.bind(row))
			row.mouse_exited.connect(_on_row_exited)
		_rows.append(row)
		$rows.move_child(row, index)
		_configure_row(row, value[index], index)
	_updating = false
	if not Engine.is_editor_hint():
		_idle.set_rows(_rows)

func _configure_row(row: Control, entry: Entry, index: int) -> void:
	var layout: Dictionary = _layouts[index]
	row.hand_name = entry.hand_name
	row.score = entry.score
	row.modulate = Color.WHITE
	row.frame_index = layout.frame_index
	row.frame_color = frame_color
	row.text_color = text_color
	row.score_color = score_color
	row.shadow_color = shadow_color
	row.set_meta("cells", entry.cells)
	row.description_text = entry.breakdown

func _refresh_rows() -> void:
	if not is_node_ready():
		return
	_updating = true
	for index in _rows.size():
		_configure_row(_rows[index], _entries[index], index)
	_updating = false
	_layout_rows()

func _layout_targets() -> Array[Vector2]:
	var targets: Array[Vector2] = []
	var bottom := 0.0
	var width := 0.0
	for index in _rows.size():
		var row := _rows[index]
		var layout: Dictionary = _layouts[index]
		targets.append(Vector2(layout.offset_x, bottom))
		if row.visible:
			bottom += row.size.y + Config.ROW_GAP
			width = maxf(width, row.size.x + Config.OFFSET_MAX + Config.SHADOW_OFFSET.x)
	var content_size := Vector2(width, maxf(0.0, bottom - Config.ROW_GAP))
	$rows.size = content_size
	custom_minimum_size = content_size
	size = content_size
	return targets

func _layout_rows() -> void:
	if _transitioning or _updating:
		return
	var targets := _layout_targets()
	for index in _rows.size():
		_rows[index].position = targets[index]

func get_row(index: int) -> Control:
	return _rows[index]

func hovered_cells() -> Array:
	var row: Control = _idle.hovered_row()
	return row.get_meta("cells", []) if row != null else []

func set_idle_enabled(enabled: bool) -> void:
	_idle.set_enabled(enabled)

func _on_row_entered(row: Control) -> void:
	if not Engine.is_editor_hint():
		_idle.focus(row)
	group_hovered.emit(row.get_meta("cells"))

func _on_row_exited() -> void:
	if not Engine.is_editor_hint():
		_idle.refresh_hover.call_deferred()
	group_hovered.emit([])

func showcase_row(index: int, speed: float) -> void:
	_idle.showcase(_rows[index], speed)

func end_showcase(speed: float) -> void:
	_idle.showcase(null, speed)

func reset_feedback() -> void:
	_idle.clear_focus()
	for row in _rows:
		row.reset_feedback()
