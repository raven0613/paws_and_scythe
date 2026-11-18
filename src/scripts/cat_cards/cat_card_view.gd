@tool
extends Control

signal reorder_requested(source: String, destination: String)
signal clicked(id: String)

const Catalog = preload("res://src/configs/cat_cards/cat_catalog.gd")
const Config = preload("res://src/configs/cat_cards/cat_feedback_config.gd")
const Activation = preload("res://src/configs/cat_cards/cat_activation_config.gd")
const Numbers = preload("res://src/configs/gameplay/gameplay_ui_config.gd")
const Effects = preload("res://src/service/cat_cards/effect_rules.gd")
const CardMotion = preload("res://src/service/cat_cards/activation/card_motion.gd")
const Badge = preload("res://src/scripts/cat_cards/activation/activation_badge.gd")
const CardTilt = preload("res://src/scripts/motion/card_tilt.gd")
const HoverTilt = preload("res://src/service/motion/hover_tilt.gd")
const Trade = preload("res://src/configs/cat_cards/cat_trade_config.gd")
const PopBurst = preload("res://src/scripts/motion/pop_burst.gd")
var cat_id := ""
var description_text := ""
var interaction_enabled := false
var _badge: Node2D
var _tilt: RefCounted
var _active := false
var _hovered := false
var _hover_tilt := Vector2.ZERO
var _release_tween: Tween
var _clock := 0.0
var _speed := 1.0
var _shadow_rest := Vector2.ZERO
var _dragged := false

func _ready() -> void:
	set_process(false)
	if Engine.is_editor_hint():
		return
	mouse_filter = Control.MOUSE_FILTER_STOP
	_tilt = CardTilt.new($visual, Config.CARD_SIZE)
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	_shadow_rest = $visual/shadow.position
	_badge = Badge.new()
	_badge.hide()
	add_child(_badge)
	HoverInfo.bind_source(self, _hover_content)

func _hover_content() -> Array:
	if cat_id.is_empty():
		return ["", ""]
	var definition: Dictionary = Catalog.CARDS[cat_id]
	return ["%s / %s" % [definition.name, definition.rarity], description_text]

func configure(id: String, state: Dictionary) -> void:
	cat_id = id
	$visual/artwork.texture = load(Catalog.art(id))
	description_text = Catalog.description(id)
	var definition: Dictionary = Catalog.CARDS[id]
	if Config.CURRENT_AMOUNT_MEASURES.has(definition.measure):
		var amount := Effects.amount(definition, state, -1)
		description_text += "\n" + Config.CURRENT_AMOUNT_TEXT % Numbers.precise(amount)

func set_playback_speed(value: float) -> void:
	_speed = value

# 發動後依自身時鐘播放卡片與標籤動作，到收回完成自動復原；text 為空時只播放卡片動作。
# fills 為標籤主體與尾巴的填色色標，依主體、第一節、第二節排列。
func begin_feedback(text: String, fills: Array[PackedColorArray]) -> void:
	_clock = 0.0
	_active = true
	z_index = Activation.LAYER
	_badge.text = text
	_badge.paint(fills)
	_badge.visible = not text.is_empty()
	set_process(true)
	_apply()

# 發動期間由發動姿態決定透視；其餘時間 Hover 中的卡片依滑鼠位置透視傾斜，大小與位置維持原樣。
func _process(delta: float) -> void:
	if _active:
		_clock += delta * _speed
		if CardMotion.finished(_clock):
			reset_feedback()
		else:
			_apply()
	elif _hovered:
		var target := HoverTilt.target(get_local_mouse_position(), size, Config.HOVER_TILT)
		_set_hover_tilt(HoverTilt.follow(_hover_tilt, target, delta, Config.HOVER_TILT_FOLLOW))
	else:
		set_process(false)

# 離開時以 Quad Out 補間回正。
func _set_hovered(hovered: bool) -> void:
	_hovered = hovered
	if _release_tween:
		_release_tween.kill()
	if hovered:
		set_process(true)
	else:
		_release_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_release_tween.tween_method(_set_hover_tilt, _hover_tilt, Vector2.ZERO, Config.HOVER_RELEASE_DURATION)

func _set_hover_tilt(value: Vector2) -> void:
	_hover_tilt = value
	if not _active:
		_tilt.apply(value, Config.HOVER_PERSPECTIVE)

func _apply() -> void:
	var pose := CardMotion.pose(_clock)
	$visual.position = pose.offset
	$visual.scale = Vector2.ONE * pose.scale
	$visual.rotation = pose.rotation
	$visual/shadow.position = CardMotion.shadow(_shadow_rest, _clock)
	_tilt.apply(pose.tilt, Activation.CARD_PERSPECTIVE)
	_badge.position = Config.CARD_SIZE / 2 + pose.anchor
	_badge.update(_clock)

# 發動結束後從平面卡面開始，Hover 中的卡片再平滑傾向滑鼠。
func reset_feedback() -> void:
	_active = false
	set_process(_hovered)
	$visual.position = Vector2.ZERO
	$visual.scale = Vector2.ONE
	$visual.rotation = 0.0
	$visual/shadow.position = _shadow_rest
	_set_hover_tilt(Vector2.ZERO)
	z_index = 0
	_badge.hide()

# 新取得的貓牌從零彈出並抖動。
func play_arrival() -> void:
	$visual.scale = Vector2.ZERO
	PopBurst.play(self, $visual, Trade.ARRIVAL_POP_SCALE, Trade.POP)

func hide_for_arrival() -> void:
	$visual.scale = Vector2.ZERO

# 賣出時先往上彈起放大，再旋轉縮小消失。
func play_vanish() -> Tween:
	$visual.pivot_offset = Config.CARD_SIZE / 2
	var tween := create_tween()
	tween.tween_property($visual, "scale", Vector2.ONE * Trade.VANISH_LIFT_SCALE, Trade.VANISH_LIFT_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property($visual, "position:y", -Trade.VANISH_LIFT_HEIGHT, Trade.VANISH_LIFT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property($visual, "scale", Vector2.ZERO, Trade.VANISH_SHRINK_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property($visual, "rotation", Trade.VANISH_SPIN, Trade.VANISH_SHRINK_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	return tween

# 按下後未拖曳即放開視為點擊；拖曳排序維持原本的拖放流程。
func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if event.pressed:
		_dragged = false
	elif not _dragged and interaction_enabled and not cat_id.is_empty():
		clicked.emit(cat_id)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not interaction_enabled or cat_id.is_empty():
		return null
	_dragged = true
	var preview := TextureRect.new()
	preview.texture = $visual/artwork.texture
	preview.custom_minimum_size = Config.CARD_SIZE
	preview.modulate.a = 0.85
	set_drag_preview(preview)
	return {"type": "cat_card", "id": cat_id}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return interaction_enabled and data is Dictionary and data.get("type") == "cat_card" and data.id != cat_id

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	reorder_requested.emit(data.id, cat_id)
