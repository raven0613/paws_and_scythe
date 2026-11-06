@tool
extends Button

const Config = preload("res://src/configs/action_buttons/action_button_config.gd")
const Definition = preload("res://src/configs/action_buttons/action_button_definition.gd")
const FrameFill = preload("res://src/scripts/action_buttons/frame_fill.gd")

@export var definition: Definition:
	set(value):
		definition = value
		if definition != null:
			remaining_count = definition.preview_remaining
		_apply_definition()

@export var remaining_count: int = 0:
	set(value):
		remaining_count = maxi(value, 0)
		_update_counter()

@onready var _waves: NinePatchRect = $waves
@onready var _frame: NinePatchRect = $frame
@onready var _content: HBoxContainer = $center/content
@onready var _icon: TextureRect = $center/content/icon
@onready var _caption: Label = $center/content/caption
@onready var _counter: HBoxContainer = $counter
@onready var _time_icon: TextureRect = $counter/time_icon
@onready var _count_label: Label = $counter/number

var _wave_material: ShaderMaterial


func _ready() -> void:
	_wave_material = _waves.material.duplicate() as ShaderMaterial
	_waves.material = _wave_material
	_content.minimum_size_changed.connect(_refresh_minimum_size)
	_counter.minimum_size_changed.connect(_position_counter)
	resized.connect(_layout_visuals)
	_apply_definition()
	if not Engine.is_editor_hint():
		HoverInfo.bind_source(self, func(): return [definition.caption, ""])


func _apply_definition() -> void:
	if not is_node_ready() or definition == null:
		return
	_frame.texture = definition.frame
	_waves.texture = FrameFill.create_texture(definition.frame)
	for panel in [_frame, _waves]:
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			panel.set_patch_margin(side, Config.FRAME_SLICE_MARGIN)
	_wave_material.set_shader_parameter("phase", definition.wave_phase)
	_icon.texture = definition.icon
	_caption.text = definition.caption
	_caption.add_theme_font_size_override("font_size", definition.caption_font_size)
	_caption.add_theme_color_override("font_color", Config.TEXT_COLOR)
	_content.add_theme_constant_override("separation", Config.ICON_TEXT_GAP)
	_counter.add_theme_constant_override("separation", Config.COUNTER_ICON_GAP)
	_counter.visible = definition.show_remaining
	_time_icon.visible = definition.show_time_icon
	_count_label.add_theme_font_size_override("font_size", definition.count_font_size)
	_count_label.add_theme_color_override("font_color", definition.count_color)
	_count_label.add_theme_color_override("font_outline_color", Config.COUNT_OUTLINE_COLOR)
	_count_label.add_theme_constant_override("outline_size", Config.COUNT_OUTLINE_SIZE)
	_update_counter()
	_refresh_minimum_size()
	queue_redraw()


func _update_counter() -> void:
	if not is_node_ready():
		return
	_count_label.text = str(remaining_count)
	_position_counter.call_deferred()


func _refresh_minimum_size() -> void:
	if not is_node_ready() or definition == null:
		return
	var content_size := _content.get_combined_minimum_size()
	custom_minimum_size = Vector2(
		maxf(definition.frame.get_width(), content_size.x + Config.CONTENT_PADDING * 2),
		maxf(definition.frame.get_height(), content_size.y)
	)
	reset_size()
	_layout_visuals()


func _layout_visuals() -> void:
	if not is_node_ready():
		return
	_wave_material.set_shader_parameter("panel_size", size)
	_position_counter()


func _position_counter() -> void:
	if not is_node_ready():
		return
	_counter.reset_size()
	_counter.position = Vector2(
		size.x - Config.COUNTER_RIGHT_MARGIN - _counter.size.x,
		Config.COUNTER_TOP
	)


func _draw() -> void:
	if not is_node_ready():
		return
	var tint := Color.WHITE
	match get_draw_mode():
		DRAW_HOVER:
			tint = Config.HOVER_TINT
		DRAW_PRESSED, DRAW_HOVER_PRESSED:
			tint = Config.PRESSED_TINT
		DRAW_DISABLED:
			tint = Config.DISABLED_TINT
	if has_focus() and not disabled:
		tint = Config.HOVER_TINT
	_frame.modulate = tint
	_waves.modulate = tint
	_content.modulate = tint
