@tool
extends Resource

const Config = preload("res://src/configs/action_buttons/action_button_config.gd")

@export var action_id: StringName
@export var caption: String
@export var frame: Texture2D
@export var icon: Texture2D
@export var caption_font_size: int = 12
@export var show_remaining: bool = true
@export var preview_remaining: int = 0
@export var count_font_size: int = 14
@export var count_color: Color = Config.COUNT_COLOR
@export var show_time_icon: bool = false
@export var wave_phase: float = 0.0
