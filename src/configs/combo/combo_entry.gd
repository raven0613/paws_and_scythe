@tool
extends Resource

@export var hand_name: String = "":
	set(value):
		hand_name = value
		emit_changed()

@export var score: int = 0:
	set(value):
		score = value
		emit_changed()

var cells: Array = []
var direction := Vector2i.RIGHT
var kind := ""
