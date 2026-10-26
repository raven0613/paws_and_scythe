@tool
extends Control

const Config = preload("res://src/configs/cat_card_area/cat_card_area_config.gd")
const Layout = preload("res://src/service/cat_card_area/cat_card_layout.gd")

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
	var card_size := (_cards.get_child(0) as Control).get_combined_minimum_size()
	var positions := Layout.get_positions(card_count, card_size)
	for index in range(_cards.get_child_count()):
		var card := _cards.get_child(index) as Control
		card.visible = index < card_count
		if card.visible:
			card.position = positions[index]
