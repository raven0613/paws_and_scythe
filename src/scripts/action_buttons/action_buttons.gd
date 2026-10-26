@tool
extends HBoxContainer

signal action_requested(action_id: StringName)


func _ready() -> void:
	minimum_size_changed.connect(reset_size)
	for button in get_children():
		button.pressed.connect(_on_action_pressed.bind(button.definition.action_id))
	reset_size()


func _on_action_pressed(action_id: StringName) -> void:
	action_requested.emit(action_id)
