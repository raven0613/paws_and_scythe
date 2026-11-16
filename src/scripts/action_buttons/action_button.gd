@tool
extends Button

const Config = preload("res://src/configs/action_buttons/action_button_config.gd")
const Definition = preload("res://src/configs/action_buttons/action_button_definition.gd")
const FrameFill = preload("res://src/scripts/action_buttons/frame_fill.gd")
const Motion = preload("res://src/configs/action_buttons/action_button_motion_config.gd")
const Slosh = preload("res://src/service/action_buttons/water_slosh.gd")

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

@onready var _spacing: Control = $spacing
@onready var _visual: Control = $spacing/visual
@onready var _waves: NinePatchRect = $spacing/visual/waves
@onready var _frame: NinePatchRect = $spacing/visual/frame
@onready var _content: HBoxContainer = $spacing/visual/center/content
@onready var _icon: TextureRect = $spacing/visual/center/content/icon
@onready var _caption: Label = $spacing/visual/center/content/caption
@onready var _counter: HBoxContainer = $spacing/visual/counter
@onready var _time_icon: TextureRect = $spacing/visual/counter/time_icon
@onready var _count_label: Label = $spacing/visual/counter/number

var _wave_material: ShaderMaterial
var _slosh: Dictionary = Slosh.REST


func _ready() -> void:
	_wave_material = _waves.material.duplicate() as ShaderMaterial
	_waves.material = _wave_material
	_content.minimum_size_changed.connect(_refresh_minimum_size)
	_counter.minimum_size_changed.connect(_position_counter)
	resized.connect(_layout_visuals)
	_apply_definition()
	set_process(false)
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
	_wave_material.set_shader_parameter("chop_wavelength", Motion.SLOSH_CHOP_WAVELENGTH)
	_wave_material.set_shader_parameter("chop_speed", Motion.SLOSH_CHOP_SPEED)
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
	_spacing.pivot_offset = size / 2
	_visual.pivot_offset = size / 2
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
		DRAW_PRESSED, DRAW_HOVER_PRESSED:
			tint = Config.PRESSED_TINT
		DRAW_DISABLED:
			tint = Config.DISABLED_TINT
	_frame.modulate = tint
	_waves.modulate = tint
	_content.modulate = tint


func hover_visual() -> Control:
	return _visual


func spacing_visual() -> Control:
	return _spacing


# 外框被甩動時水面跟著晃，impulse 正值代表向右甩；擺盪平靜後停止更新。
func slosh(impulse: float) -> void:
	_slosh = Slosh.kick(_slosh, impulse)
	set_process(true)


func _process(delta: float) -> void:
	_slosh = Slosh.step(_slosh, delta)
	if Slosh.is_calm(_slosh):
		_slosh = Slosh.REST
		set_process(false)
	_wave_material.set_shader_parameter("slosh_tilt", _slosh.tilt)
	_wave_material.set_shader_parameter("slosh_chop", _slosh.chop * Motion.SLOSH_CHOP_AMPLITUDE)
