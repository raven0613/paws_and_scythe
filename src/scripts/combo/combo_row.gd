@tool
extends Control

const Numbers = preload("res://src/configs/gameplay/gameplay_ui_config.gd")
const Motion = preload("res://src/service/score/number_motion.gd")
const Feedback = preload("res://src/configs/score/score_feedback_config.gd")
const Config = preload("res://src/configs/combo/combo_config.gd")
var _count = Motion.new()
var description_text := ""

@export var hand_name: String = "":
	set(value):
		hand_name = value
		_refresh()
@export var score: float = 0.0:
	get:
		return _count.current
	set(value):
		_count.reset(value)
		_refresh_score()
@export_enum("01", "02", "03") var frame_index: int = 0:
	set(value):
		frame_index = value
		_refresh()
@export var frame_color: Color = Config.FRAME_COLOR:
	set(value):
		frame_color = value
		_refresh()
@export var text_color: Color = Config.TEXT_COLOR:
	set(value):
		text_color = value
		_refresh()
@export var score_color: Color = Config.SCORE_COLOR:
	set(value):
		score_color = value
		_refresh()
@export var shadow_color: Color = Config.SHADOW_COLOR:
	set(value):
		shadow_color = value
		_refresh()


func _ready() -> void:
	$spacing/idle/visual/caption.z_index = Feedback.NUMBER_LAYER
	$spacing/idle/visual/caption/hand.minimum_size_changed.connect(_fit_text)
	$spacing/idle/visual/caption/score.minimum_size_changed.connect(_fit_text)
	_refresh()
	if not Engine.is_editor_hint():
		HoverInfo.bind_source(self, _hover_content)

func _hover_content() -> Array:
	return [Config.DETAILS_TITLE_FORMAT % [tr(hand_name), get_meta("cells", []).size()], description_text]


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_refresh()


func _refresh() -> void:
	if not is_node_ready():
		return
	var texture := load(Config.FRAME_PATHS[frame_index]) as Texture2D
	for patch in [$spacing/idle/visual/frame, $spacing/idle/visual/shadow]:
		patch.texture = texture
		patch.patch_margin_left = Config.SLICE_MARGIN
		patch.patch_margin_right = Config.SLICE_MARGIN
		patch.patch_margin_top = Config.SLICE_MARGIN
		patch.patch_margin_bottom = Config.SLICE_MARGIN
	$spacing/idle/visual/frame.self_modulate = frame_color
	$spacing/idle/visual/shadow.self_modulate = shadow_color
	$spacing/idle/visual/caption/hand.text = tr(hand_name)
	$spacing/idle/visual/caption/score.text = "+" + Numbers.number(score)
	$spacing/idle/visual/caption/hand.add_theme_color_override("font_color", text_color)
	$spacing/idle/visual/caption/score.add_theme_color_override("font_color", score_color)
	for label in [$spacing/idle/visual/caption/hand, $spacing/idle/visual/caption/score]:
		label.add_theme_font_size_override("font_size", Config.FONT_SIZE)
	_fit_text()


func _fit_text() -> void:
	if not is_node_ready() or $spacing/idle/visual/frame.texture == null:
		return
	var text_size: Vector2 = $spacing/idle/visual/caption.get_combined_minimum_size()
	custom_minimum_size = $spacing/idle/visual/frame.texture.get_size().max(text_size + Config.TEXT_PADDING * 2)
	size = custom_minimum_size
	pivot_offset = size / 2
	$spacing.size = size
	$spacing.pivot_offset = size / 2
	$spacing/idle/visual.size = size
	$spacing/idle/visual.pivot_offset = size / 2
	$spacing/idle/visual/frame.position = Vector2.ZERO
	$spacing/idle/visual/frame.size = size
	$spacing/idle/visual/shadow.position = Config.SHADOW_OFFSET
	$spacing/idle/visual/shadow.size = size
	$spacing/idle/visual/caption.position = Config.TEXT_PADDING
	$spacing/idle/visual/caption.size = size - Config.TEXT_PADDING * 2


func prepare_settlement() -> void:
	pivot_offset = size / 2

func score_origin() -> Vector2:
	return $spacing/idle/visual/caption/score.get_global_rect().get_center()

func _refresh_score() -> void:
	if is_node_ready():
		$spacing/idle/visual/caption/score.text = "+" + Numbers.number(score)

func begin_count(target: float) -> void:
	_count.begin(target)
	_refresh_score()
	$spacing/idle/visual/caption/score.scale = Vector2.ONE
	$spacing/idle/visual/caption/score.pivot_offset = $spacing/idle/visual/caption/score.size / 2

func count_progress(progress: float) -> void:
	_count.advance(progress)
	_refresh_score()
	$spacing/idle/visual/caption/score.pivot_offset = $spacing/idle/visual/caption/score.size / 2
	$spacing/idle/visual/caption/score.scale = Motion.scale_at(progress)

func finish_count() -> void:
	_count.finish()
	_refresh_score()
	$spacing/idle/visual/caption/score.scale = Vector2.ONE

func reset_feedback() -> void:
	scale = Vector2.ONE
	$spacing/idle/visual/caption/score.scale = Vector2.ONE

func idle_offset() -> float:
	return $spacing/idle.position.y

func set_idle_offset(value: float) -> void:
	$spacing/idle.position.y = value

func hover_visual() -> Control:
	return $spacing/idle/visual

func spacing_visual() -> Control:
	return $spacing
