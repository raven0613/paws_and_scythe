@tool
extends Control

const Config = preload("res://src/configs/boss/reaper_card_config.gd")
const Fonts = preload("res://src/service/fonts/font_library.gd")

@export var card_title: String = Config.DEFAULT_TITLE:
	set(value):
		card_title = value
		_update_card()

@export_range(-180.0, 180.0, 0.1) var card_angle: float = 0.0:
	set(value):
		card_angle = value
		_update_card()

@export var artwork: Texture2D:
	set(value):
		artwork = value
		_update_card()

@onready var _viewport: SubViewport = $pixel_viewport
@onready var _card: Control = $pixel_viewport/card
@onready var _output: Sprite2D = $pixel_output


func _ready() -> void:
	_viewport.size = Config.PIXEL_CANVAS_SIZE
	_output.texture = _viewport.get_texture()
	for title in [_card.get_node("top_left/title"), _card.get_node("bottom_right/title")]:
		title.add_theme_font_override("font", Fonts.get_pixel_font())
	_update_card()


func _update_card() -> void:
	if not is_node_ready():
		return
	var vertical_title := "\n".join(card_title.split(""))
	_card.get_node("top_left/title").text = vertical_title
	_card.get_node("bottom_right/title").text = vertical_title
	_card.get_node("artwork").texture = artwork
	_card.rotation = deg_to_rad(card_angle)
