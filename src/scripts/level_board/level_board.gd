@tool
extends Control

const Config = preload("res://src/configs/level_board/level_board_config.gd")

@export var level: int = Config.PREVIEW_LEVEL:
	set(value):
		level = maxi(value, Config.MIN_LEVEL)
		_update_display()

@export var current_score: int = Config.PREVIEW_CURRENT_SCORE:
	set(value):
		current_score = value
		_update_display()

@export var target_score: int = Config.PREVIEW_TARGET_SCORE:
	set(value):
		target_score = maxi(value, Config.MIN_TARGET_SCORE)
		_update_display()

@onready var _level_label: Label = $level_label
@onready var _progress_label: Label = $progress_label
@onready var _progress_bar: ProgressBar = $progress_bar


func _ready() -> void:
	_update_display()


func _update_display() -> void:
	if not is_node_ready():
		return
	_level_label.text = Config.LEVEL_TEXT_FORMAT % level
	_progress_label.text = Config.PROGRESS_TEXT_FORMAT % [current_score, target_score]
	_progress_bar.max_value = target_score
	_progress_bar.value = current_score
