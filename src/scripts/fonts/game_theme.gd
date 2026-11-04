@tool
extends Theme

const Config = preload("res://src/configs/fonts/font_config.gd")
const Fonts = preload("res://src/service/fonts/font_library.gd")

func _init() -> void:
	default_font = Fonts.get_font()
	default_font_size = Config.DEFAULT_FONT_SIZE
