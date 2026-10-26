@tool
extends Control

signal group_hovered(cells: Array)

const Config = preload("res://src/configs/combo/combo_config.gd")
const Entry = preload("res://src/configs/combo/combo_entry.gd")
const Sequence = preload("res://src/service/combo/combo_sequence.gd")
const RowScene = preload("res://src/scenes/combo/combo_row.tscn")

@export var preview_entries: Array[Entry] = []:
	set(value):
		if Engine.is_editor_hint():
			_watch_entries(preview_entries, value)
		preview_entries = value
		_rebuild_rows()

var entries: Array[Entry] = []:
	set(value):
		_watch_entries(entries, value)
		entries = value
		_rebuild_rows()
@export var frame_color: Color = Config.FRAME_COLOR:
	set(value):
		frame_color = value
		_rebuild_rows()
@export var text_color: Color = Config.TEXT_COLOR:
	set(value):
		text_color = value
		_rebuild_rows()
@export var shadow_color: Color = Config.SHADOW_COLOR:
	set(value):
		shadow_color = value
		_rebuild_rows()
@export_tool_button("重新抽取框形與偏移", "Reload") var reroll_preview: Callable = reroll_layout

var _sequence = Sequence.new()


func _ready() -> void:
	_sequence.reset(Config.EDITOR_SEED if Engine.is_editor_hint() else randi())
	_rebuild_rows()
	clip_contents = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


# 正式結算完成後呼叫；一般牌型或分數更新保留目前序列。
func reroll_layout() -> void:
	_sequence.reset(randi())
	_rebuild_rows()


func add_result(hand_name: String, score: int) -> void:
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
		if entry != null and entry.changed.is_connected(_rebuild_rows):
			entry.changed.disconnect(_rebuild_rows)
	for entry in current:
		if entry != null and not entry.changed.is_connected(_rebuild_rows):
			entry.changed.connect(_rebuild_rows)


func _rebuild_rows() -> void:
	if not is_node_ready():
		return
	var displayed_entries: Array[Entry] = preview_entries if Engine.is_editor_hint() else entries
	displayed_entries = displayed_entries.filter(func(entry): return entry != null)
	while $rows.get_child_count() > displayed_entries.size():
		var removed := $rows.get_child($rows.get_child_count() - 1)
		$rows.remove_child(removed)
		removed.queue_free()
	for index in displayed_entries.size():
		var entry: Entry = displayed_entries[index]
		var fresh := index >= $rows.get_child_count()
		var row = RowScene.instantiate() if fresh else $rows.get_child(index)
		var layout: Dictionary = _sequence.get_layout(index)
		var changed_group: bool = fresh or row.get_meta("cells", []) != entry.cells or row.hand_name != entry.hand_name
		row.hand_name = entry.hand_name
		row.score = entry.score
		row.frame_index = layout.frame_index
		row.frame_color = frame_color
		row.text_color = text_color
		row.shadow_color = shadow_color
		row.set_meta("cells", entry.cells)
		row.tooltip_text = "%s · %s · %d 張\n%s" % [entry.hand_name, "橫向" if entry.direction == Vector2i.RIGHT else "直向", entry.cells.size(), str(entry.cells)]
		if fresh:
			row.position.x = layout.offset_x
			$rows.add_child(row)
			row.minimum_size_changed.connect(_layout_rows)
			row.mouse_filter = Control.MOUSE_FILTER_PASS
			row.mouse_entered.connect(func(): group_hovered.emit(row.get_meta("cells")))
			row.mouse_exited.connect(func(): group_hovered.emit([]))
		if changed_group and not Engine.is_editor_hint():
			row.enter_from_right(layout.offset_x)
		else:
			row.set_layout_offset(layout.offset_x)
	_layout_rows()


func _layout_rows() -> void:
	var bottom := 0.0
	var width := 0.0
	for row in $rows.get_children():
		row.position.y = bottom
		bottom += row.size.y + Config.ROW_GAP
		width = maxf(width, row.size.x + Config.OFFSET_MAX + Config.SHADOW_OFFSET.x)
	var content_size := Vector2(width, maxf(0.0, bottom - Config.ROW_GAP))
	var fit := minf(1.0, minf(Config.AVAILABLE_SIZE.x / maxf(width, 1), Config.AVAILABLE_SIZE.y / maxf(content_size.y, 1)))
	$rows.scale = Vector2.ONE * fit
	$rows.size = content_size
	custom_minimum_size = content_size * fit
	size = custom_minimum_size


func get_row(index: int) -> Control:
	return $rows.get_child(index)


func reset_feedback() -> void:
	for row in $rows.get_children():
		row.scale = Vector2.ONE
