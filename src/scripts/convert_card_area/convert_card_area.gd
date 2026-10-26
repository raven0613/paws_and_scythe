@tool
extends Control

const Config = preload("res://src/configs/convert_card_area/convert_card_area_config.gd")

@export_range(Config.MIN_CARD_COUNT, Config.MAX_CARD_COUNT, 1)
var card_count: int = Config.DEFAULT_CARD_COUNT:
	set(value):
		card_count = clampi(value, Config.MIN_CARD_COUNT, Config.MAX_CARD_COUNT)
		if is_node_ready():
			_update_layout()

@onready var _cards: Control = $cards


func _ready() -> void:
	_update_layout()


func _update_layout() -> void:
	var card_width := (_cards.get_child(0) as Control).get_combined_minimum_size().x
	for index in range(_cards.get_child_count()):
		var card := _cards.get_child(index) as Control
		card.visible = index < card_count
		card.position.x = Config.CARD_START_X + (card_width + Config.CARD_GAP) * index
