@tool
extends Control

signal skill_changed(skill_index: int, skill_text: String)
signal transition_finished

const Config = preload("res://src/configs/boss/boss_skill_config.gd")
const Cycle = preload("res://src/service/boss/boss_skill_cycle.gd")

@export var skill_texts: PackedStringArray = Config.PREVIEW_SKILLS:
	set(value):
		skill_texts = value
		if is_node_ready() and not _processing:
			_restore_panels()

@export_tool_button("預覽：通過一個等級", "Play") var preview_level: Callable = complete_level

@onready var _lights: Node2D = $lights
@onready var _panels: Array[Control] = [$panels/front, $panels/back, $panels/reserve]

var _cycle := Cycle.new()
var _pending_levels: int = 0
var _processing: bool = false
var _tween: Tween


func _ready() -> void:
	_restore_panels()
	_set_lights(_cycle.completed_levels)


# 遊戲每完成一個等級呼叫一次；切換中收到的事件會依序處理。
func complete_level() -> void:
	_pending_levels += 1
	if not _processing:
		_process_levels()


func _process_levels() -> void:
	_processing = true
	while _pending_levels > 0:
		_pending_levels -= 1
		if _cycle.complete_level():
			_set_lights(Config.LEVELS_PER_SKILL)
			_tween = create_tween()
			_tween.tween_interval(Config.FULL_LIGHT_HOLD)
			await _tween.finished
			await _rotate_panels()
			_set_lights(_cycle.completed_levels)
			skill_changed.emit(_cycle.skill_index, _skill_text(_cycle.skill_index))
			transition_finished.emit()
		else:
			_set_lights(_cycle.completed_levels)
	_processing = false


func _rotate_panels() -> void:
	var outgoing := _panels[0]
	var incoming := _panels[1]
	var reserve := _panels[2]
	outgoing.z_index = 3
	incoming.z_index = 2
	reserve.z_index = 1
	reserve.visible = true
	_tween = create_tween().set_parallel(true)
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(outgoing, "position", Config.EXIT_POSITION, Config.EXIT_DURATION)
	_tween.tween_property(outgoing, "rotation", Config.EXIT_ROTATION, Config.EXIT_DURATION)
	_tween.tween_property(outgoing, "modulate:a", 0.0, Config.EXIT_DURATION)
	_tween.tween_property(incoming, "position", Config.FRONT_POSITION, Config.SWITCH_DURATION)
	_tween.tween_property(incoming, "rotation", Config.FRONT_ROTATION, Config.SWITCH_DURATION)
	_tween.tween_property(incoming, "modulate", Color.WHITE, Config.SWITCH_DURATION)
	var entry_duration := Config.SWITCH_DURATION - Config.ENTRY_DELAY
	_tween.tween_property(reserve, "position", Config.BACK_POSITION, entry_duration).set_delay(Config.ENTRY_DELAY)
	_tween.tween_property(reserve, "rotation", Config.BACK_ROTATION, entry_duration).set_delay(Config.ENTRY_DELAY)
	_tween.tween_property(reserve, "modulate", _back_tint(), entry_duration).set_delay(Config.ENTRY_DELAY)
	await _tween.finished
	_panels.assign([incoming, reserve, outgoing])
	_restore_panels()


func _restore_panels() -> void:
	_set_panel(_panels[0], Config.FRONT_POSITION, Config.FRONT_ROTATION, Color.WHITE, 2)
	_set_panel(_panels[1], Config.BACK_POSITION, Config.BACK_ROTATION, _back_tint(), 1)
	_set_panel(_panels[2], Config.ENTRY_POSITION, Config.ENTRY_ROTATION, Config.HIDDEN_COLOR, 0)
	_panels[2].visible = false
	for index in range(_panels.size()):
		_panels[index].get_node("caption").text = _skill_text(_cycle.skill_index + index)


func _set_panel(panel: Control, point: Vector2, angle: float, tint: Color, depth: int) -> void:
	panel.position = point
	panel.rotation = angle
	panel.modulate = tint
	panel.z_index = depth
	panel.visible = true
	panel.get_node("background").self_modulate = Config.FRONT_COLOR


func _back_tint() -> Color:
	return Color(
		Config.BACK_COLOR.r / Config.FRONT_COLOR.r,
		Config.BACK_COLOR.g / Config.FRONT_COLOR.g,
		Config.BACK_COLOR.b / Config.FRONT_COLOR.b
	)


func _skill_text(index: int) -> String:
	if skill_texts.is_empty():
		return ""
	return skill_texts[index % skill_texts.size()]


func _set_lights(count: int) -> void:
	for index in range(_lights.get_child_count()):
		var light := _lights.get_child(index)
		light.get_node("body").color = Config.LIGHT_ON if index < count else Config.LIGHT_OFF
		light.get_node("highlight").color = Config.LIGHT_HIGHLIGHT
		light.get_node("highlight").visible = index < count


func _exit_tree() -> void:
	if _tween != null:
		_tween.kill()
