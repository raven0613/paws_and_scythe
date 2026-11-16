extends Node

const Config = preload("res://src/configs/combo/combo_animation_config.gd")
const Displacement = preload("res://src/scripts/motion/displacement.gd")
const HoverPop = preload("res://src/scripts/motion/hover_pop.gd")
var _rows: Array[Control] = []
var _hovered: Control
var _enabled := true
var _phase := 0.0
var _resume_time := 0.0
var _resume_from: Dictionary = {}
var _tweens: Dictionary = {}
var _spacing_tween: Tween
var _speed := 1.0

func set_rows(rows: Array[Control]) -> void:
	_rows = rows.duplicate()
	_capture_offsets()

func forget(row: Control) -> void:
	_stop_tween(row)
	if _hovered == row:
		_hovered = null
	_rows.erase(row)
	_resume_from.erase(row)

func set_enabled(enabled: bool) -> void:
	if _enabled == enabled:
		return
	if not enabled:
		focus(null)
	_enabled = enabled
	if enabled:
		_capture_offsets()
		refresh_hover()

func _process(delta: float) -> void:
	if not _enabled:
		return
	refresh_hover()
	if _hovered != null:
		return
	_phase = fposmod(_phase + delta * TAU / Config.IDLE_PERIOD, TAU)
	_resume_time = minf(_resume_time + delta, Config.IDLE_RESUME_DURATION)
	var blend := smoothstep(0.0, Config.IDLE_RESUME_DURATION, _resume_time)
	for index in _rows.size():
		var row := _rows[index]
		var offset := Config.IDLE_AMPLITUDE * sin(_phase - index * Config.IDLE_PHASE_STEP)
		row.set_idle_offset(lerpf(_resume_from[row], offset, blend))

func _capture_offsets() -> void:
	_resume_time = 0.0
	_resume_from.clear()
	for row in _rows:
		_resume_from[row] = row.idle_offset()

func hovered_row() -> Control:
	var control := get_viewport().gui_get_hovered_control()
	for row in _rows:
		if row.visible and (control == row or (control != null and row.is_ancestor_of(control))):
			return row
	return null

func refresh_hover() -> void:
	if _enabled:
		focus(hovered_row())

func focus(row: Control) -> void:
	if _enabled:
		_speed = 1.0
		_set_focus(row)

# 結算亮相在波動停用期間直接驅動聚焦，沿用 Hover 的放大、抖動與推開鄰列；row 為 null 時收回。
func showcase(row: Control, speed: float) -> void:
	_speed = speed
	_set_focus(row)

# 立即回到靜止排列，供結算跳過與收尾使用。
func clear_focus() -> void:
	if _spacing_tween:
		_spacing_tween.kill()
	for row in _rows:
		_stop_tween(row)
		HoverPop.rest(row.hover_visual())
		row.spacing_visual().position = Vector2.ZERO
		row.spacing_visual().rotation = 0.0
	_hovered = null

func _set_focus(row: Control) -> void:
	if row == _hovered:
		return
	if _hovered != null:
		_release(_hovered)
	_hovered = row
	if row != null:
		_enter(row)
		_open_gap(row)
	else:
		_close_gap()

func _open_gap(selected: Control) -> void:
	if _spacing_tween:
		_spacing_tween.kill()
	_spacing_tween = create_tween().set_parallel().set_speed_scale(_speed)
	var selected_index := _rows.find(selected)
	var center := selected.position + Vector2(selected.size.x / 2, selected.idle_offset() + selected.size.y / 2)
	var half_height := selected.size.y * Config.HOVER_SCALE / 2
	var above := 0.0
	var below := 0.0
	if selected_index > 0:
		var neighbor := _rows[selected_index - 1]
		above = maxf(0.0, neighbor.position.y + neighbor.idle_offset() + neighbor.size.y + Config.HOVER_GAP - (center.y - half_height))
	if selected_index + 1 < _rows.size():
		var neighbor := _rows[selected_index + 1]
		below = maxf(0.0, center.y + half_height + Config.HOVER_GAP - (neighbor.position.y + neighbor.idle_offset()))
	var motions: Array[Dictionary] = []
	for index in _rows.size():
		var row := _rows[index]
		var spacing: Control = row.spacing_visual()
		if row == selected:
			_spacing_tween.tween_property(spacing, "position", Vector2.ZERO, Config.HOVER_SCALE_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			_spacing_tween.tween_property(spacing, "rotation", 0.0, Config.HOVER_SCALE_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			continue
		var target := Vector2(0.0, -above if index < selected_index else below)
		var offset := row.position + Vector2(row.size.x / 2, row.idle_offset() + row.size.y / 2) + target - center
		motions.append({"node": spacing, "origin": spacing.position, "target": target,
			"rotation": spacing.rotation, "direction": offset.normalized(), "index": index})
	Displacement.append(_spacing_tween, motions, selected_index, Config.HOVER_DISTURB_COUNT, Config.DISTURB_PROFILE)

func _close_gap() -> void:
	if _spacing_tween:
		_spacing_tween.kill()
	if _rows.is_empty():
		return
	_spacing_tween = create_tween().set_parallel().set_speed_scale(_speed).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for row in _rows:
		var spacing: Control = row.spacing_visual()
		_spacing_tween.tween_property(spacing, "position", Vector2.ZERO, Config.HOVER_RELEASE_DURATION)
		_spacing_tween.tween_property(spacing, "rotation", 0.0, Config.HOVER_RELEASE_DURATION)

func _stop_tween(row: Control) -> void:
	if _tweens.has(row):
		_tweens[row].kill()
		_tweens.erase(row)

func _enter(row: Control) -> void:
	_stop_tween(row)
	_tweens[row] = HoverPop.enter(self, row.hover_visual(), Config.HOVER_PROFILE, _speed)

func _release(row: Control) -> void:
	_stop_tween(row)
	_tweens[row] = HoverPop.release(self, row.hover_visual(), Config.HOVER_PROFILE, _speed)
