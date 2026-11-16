@tool
extends Control

signal selection_requested(card: Control)

const Config = preload("res://src/configs/playing_card/playing_card_config.gd")
const Rules = preload("res://src/configs/gameplay/game_rules.gd")
const Cards = preload("res://src/service/gameplay/cards.gd")
const CardTilt = preload("res://src/scripts/motion/card_tilt.gd")

@export var selection_enabled: bool = false:
	set(value):
		selection_enabled = value
		mouse_filter = Control.MOUSE_FILTER_STOP if value else Control.MOUSE_FILTER_IGNORE
		focus_mode = Control.FOCUS_ALL if value else Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if value else Control.CURSOR_ARROW
		if _marks:
			_marks.queue_redraw()

var card_id := -1
var description_text := ""
var selected := false
var mark_colors: Array = []
var target_selected := false
var _marks: Node2D
var _tilt: RefCounted

func _ready() -> void:
	_marks = Node2D.new()
	_marks.name = "highlights"
	$visual.add_child(_marks)
	_marks.draw.connect(_draw_marks)
	mouse_entered.connect(_marks.queue_redraw)
	mouse_exited.connect(_marks.queue_redraw)
	focus_entered.connect(_marks.queue_redraw)
	focus_exited.connect(_marks.queue_redraw)
	if not Engine.is_editor_hint():
		_tilt = CardTilt.new($visual, size)
		HoverInfo.bind_source(self, _hover_content)

func _hover_content() -> Array:
	return [Cards.caption(card_id), description_text] if card_id >= 0 else ["", ""]

func set_card(value: int) -> void:
	card_id = value
	var suit := Cards.suit(value)
	$visual/face.modulate = Rules.SUIT_COLORS[suit]
	$visual/face/big.animation = Rules.SUITS[suit]
	for corner in [$visual/face/top_left, $visual/face/bottom_right]:
		corner.get_node("rank").text = Rules.RANKS[Cards.rank(value) - 1]
		corner.get_node("small").animation = Rules.SUITS[suit]
	description_text = ""

func set_marks(colors: Array, target: bool = false) -> void:
	mark_colors = colors
	target_selected = target
	_marks.queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not selection_enabled:
		return
	var clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	if clicked or event.is_action_pressed("ui_accept"):
		accept_event()
		selection_requested.emit(self)

func _draw_marks() -> void:
	for index in mark_colors.size():
		var color: Color = mark_colors[index]
		color.a = Config.MARK_ALPHA
		_marks.draw_rect(Rect2(Vector2.ZERO, size).grow(-Config.OUTLINE_WIDTH * index), color, false, Config.OUTLINE_WIDTH)
	if target_selected:
		var color := Config.SELECTION_COLOR
		color.a = Config.HIGHLIGHT_ALPHA
		_marks.draw_rect(Rect2(Vector2.ZERO, size), color)
	elif selection_enabled and (has_focus() or Rect2(Vector2.ZERO, size).has_point(get_local_mouse_position())):
		_marks.draw_rect(Rect2(Vector2.ZERO, size), Config.HOVER_COLOR)

func group_visual() -> Node2D:
	return $visual

# 整張卡面依 tilt 透視傾斜，在 visual 位置更新後呼叫；零為原本的平面卡面。
func set_tilt(tilt: Vector2, perspective: float) -> void:
	_tilt.apply(tilt, perspective)
