@tool
extends HBoxContainer

signal action_requested(action_id: StringName)

const Hover = preload("res://src/scripts/action_buttons/action_buttons_hover.gd")


func _ready() -> void:
	minimum_size_changed.connect(reset_size)
	var buttons: Array[Control] = []
	for button in get_children():
		buttons.append(button)
		button.pressed.connect(_on_action_pressed.bind(button.definition.action_id))
	if not Engine.is_editor_hint():
		var hover := Hover.new()
		hover.setup(buttons)
		add_child(hover)
	reset_size()


func _on_action_pressed(action_id: StringName) -> void:
	action_requested.emit(action_id)
