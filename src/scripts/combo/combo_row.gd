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
	$caption.z_index = Feedback.NUMBER_LAYER
	$caption/hand.minimum_size_changed.connect(_fit_text)
	$caption/score.minimum_size_changed.connect(_fit_text)
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
	for patch in [$frame, $shadow]:
		patch.texture = texture
		patch.patch_margin_left = Config.SLICE_MARGIN
		patch.patch_margin_right = Config.SLICE_MARGIN
		patch.patch_margin_top = Config.SLICE_MARGIN
		patch.patch_margin_bottom = Config.SLICE_MARGIN
	$frame.self_modulate = frame_color
	$shadow.self_modulate = shadow_color
	$caption/hand.text = tr(hand_name)
	$caption/score.text = "+" + Numbers.number(score)
	$caption/hand.add_theme_color_override("font_color", text_color)
	$caption/score.add_theme_color_override("font_color", score_color)
	for label in [$caption/hand, $caption/score]:
		label.add_theme_font_size_override("font_size", Config.FONT_SIZE)
	_fit_text()


func _fit_text() -> void:
	if not is_node_ready() or $frame.texture == null:
		return
	var text_size: Vector2 = $caption.get_combined_minimum_size()
	custom_minimum_size = $frame.texture.get_size().max(text_size + Config.TEXT_PADDING * 2)
	size = custom_minimum_size
	pivot_offset = size / 2
	$frame.position = Vector2.ZERO
	$frame.size = size
	$shadow.position = Config.SHADOW_OFFSET
	$shadow.size = size
	$caption.position = Config.TEXT_PADDING
	$caption.size = size - Config.TEXT_PADDING * 2


var _enter_tween: Tween
var _target_x := 0.0

func enter_from_right(target_x: float) -> void:
	if _enter_tween:
		_enter_tween.kill()
	_target_x = target_x
	position.x = target_x + Config.ENTER_OFFSET
	modulate.a = 0.0
	_enter_tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_enter_tween.tween_property(self, "position:x", target_x, Config.ENTER_DURATION)
	_enter_tween.tween_property(self, "modulate:a", 1.0, Config.FADE_DURATION)

func set_layout_offset(target_x: float) -> void:
	if target_x == _target_x and _enter_tween and _enter_tween.is_running():
		return
	if _enter_tween:
		_enter_tween.kill()
	_target_x = target_x
	position.x = target_x
	modulate.a = 1.0


func prepare_settlement() -> void:
	if _enter_tween:
		_enter_tween.kill()
	position.x = _target_x
	modulate.a = 1.0
	pivot_offset = size / 2

func score_origin() -> Vector2:
	return $caption/score.get_global_rect().get_center()

func _refresh_score() -> void:
	if is_node_ready():
		$caption/score.text = "+" + Numbers.number(score)

func begin_count(target: float) -> void:
	_count.begin(target)
	_refresh_score()
	$caption/score.scale = Vector2.ONE
	$caption/score.pivot_offset = $caption/score.size / 2

func count_progress(progress: float) -> void:
	_count.advance(progress)
	_refresh_score()
	$caption/score.pivot_offset = $caption/score.size / 2
	$caption/score.scale = Motion.scale_at(progress)

func finish_count() -> void:
	_count.finish()
	_refresh_score()
	$caption/score.scale = Vector2.ONE

func reset_feedback() -> void:
	scale = Vector2.ONE
	$caption/score.scale = Vector2.ONE
