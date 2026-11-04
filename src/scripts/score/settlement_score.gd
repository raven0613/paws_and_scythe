@tool
extends Control

const Config = preload("res://src/configs/score/score_feedback_config.gd")

func _ready() -> void:
	$number.layout_changed.connect(_layout_combo)
	$combo_counter.resized.connect(_layout_combo)
	_layout_combo()

func _layout_combo() -> void:
	$combo_counter.position.x = $number.layout_right() + Config.SCORE_COMBO_GAP + $combo_counter.left_pop_margin()
