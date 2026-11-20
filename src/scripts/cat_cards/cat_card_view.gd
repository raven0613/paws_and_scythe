@tool
extends Control

signal drag_requested(card: Control, pointer: Vector2)
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
const DragConfig = preload("res://src/configs/cat_card_area/cat_drag_config.gd")
const Math = preload("res://src/service/playing_card/flight_math.gd")
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
var _pressing := false
var _press_origin := Vector2.ZERO
var _carried := false
var _move_tween: Tween
@onready var _visual: Control = $carry/visual
@onready var _shadow: Sprite2D = $carry/visual/shadow

func _ready() -> void:
	set_process(false)
	if Engine.is_editor_hint():
		return
	mouse_filter = Control.MOUSE_FILTER_STOP
	_tilt = CardTilt.new(_visual, Config.CARD_SIZE)
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	_shadow_rest = _shadow.position
	_badge = Badge.new()
	_badge.hide()
	add_child(_badge)
	HoverInfo.bind_source(self, _hover_content)

func _hover_content() -> Array:
	if cat_id.is_empty():
		return ["", ""]
	var definition: Dictionary = Catalog.CARDS[cat_id]
	return ["%s / %s" % [definition.name, definition.rarity], description_text]

# potency 為持有位置的效益倍數：說明與目前加成顯示調整後的數值，效果說明後方標示加倍或減半。
func configure(id: String, state: Dictionary, potency := 1.0) -> void:
	cat_id = id
	$carry/visual/artwork.texture = load(Catalog.art(id))
	var definition: Dictionary = Catalog.CARDS[id]
	var overrides := {}
	if definition.has("value"):
		overrides.value = Effects.boost(definition.op, definition.value, potency)
	description_text = Catalog.description(id, overrides) + _potency_tag(potency)
	if Config.CURRENT_AMOUNT_MEASURES.has(definition.get("measure")):
		var amount := Effects.amount(definition, state, -1, potency)
		description_text += "\n" + Config.CURRENT_AMOUNT_TEXT % Numbers.precise(amount)

static func _potency_tag(potency: float) -> String:
	if potency == 1.0:
		return ""
	var boosted := potency > 1.0
	var color: Color = Config.BOOST_TAG_COLOR if boosted else Config.REDUCE_TAG_COLOR
	return "[color=#%s]%s[/color]" % [color.to_html(), Config.BOOST_TAG if boosted else Config.REDUCE_TAG]

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

# 發動期間由發動姿態決定透視；拖曳期間由拖曳演出決定透視；其餘時間 Hover 中的卡片依滑鼠位置透視傾斜，大小與位置維持原樣。
func _process(delta: float) -> void:
	if _active:
		_clock += delta * _speed
		if CardMotion.finished(_clock):
			reset_feedback()
		else:
			_apply()
	elif _hovered and not _carried:
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
	if not _active and not _carried:
		_tilt.apply(value, Config.HOVER_PERSPECTIVE)

func _apply() -> void:
	var pose := CardMotion.pose(_clock)
	_visual.position = pose.offset
	_visual.scale = Vector2.ONE * pose.scale
	_visual.rotation = pose.rotation
	_shadow.position = CardMotion.shadow(_shadow_rest, _clock)
	_tilt.apply(pose.tilt, Activation.CARD_PERSPECTIVE)
	_badge.position = Config.CARD_SIZE / 2 + pose.anchor
	_badge.update(_clock)

# 發動結束後從平面卡面開始，Hover 中的卡片再平滑傾向滑鼠。
func reset_feedback() -> void:
	_active = false
	set_process(_hovered)
	_visual.position = Vector2.ZERO
	_visual.scale = Vector2.ONE
	_visual.rotation = 0.0
	_shadow.position = _shadow_rest
	_set_hover_tilt(Vector2.ZERO)
	z_index = 0
	_badge.hide()

# 新取得的貓牌從零彈出並抖動。
func play_arrival() -> void:
	_visual.scale = Vector2.ZERO
	PopBurst.play(self, _visual, Trade.ARRIVAL_POP_SCALE, Trade.POP)

func hide_for_arrival() -> void:
	_visual.scale = Vector2.ZERO

# 賣出時先往上彈起放大，再旋轉縮小消失。
func play_vanish() -> Tween:
	_visual.pivot_offset = Config.CARD_SIZE / 2
	var tween := create_tween()
	tween.tween_property(_visual, "scale", Vector2.ONE * Trade.VANISH_LIFT_SCALE, Trade.VANISH_LIFT_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_visual, "position:y", -Trade.VANISH_LIFT_HEIGHT, Trade.VANISH_LIFT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_visual, "scale", Vector2.ZERO, Trade.VANISH_SHRINK_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(_visual, "rotation", Trade.VANISH_SPIN, Trade.VANISH_SHRINK_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	return tween

# 拖曳與吸入期間由拖曳演出控制卡片姿態與透視，Hover 傾斜暫停；落定後從平面卡面依滑鼠位置恢復傾斜。
func set_carried(carried: bool) -> void:
	_carried = carried
	if _release_tween:
		_release_tween.kill()
	_hover_tilt = Vector2.ZERO
	_tilt.apply(Vector2.ZERO, Config.HOVER_PERSPECTIVE)
	set_process(_hovered and not carried)

# 拖曳形變作用於 carry 節點，卡面與陰影一起變形；發動、買賣與 Hover 的姿態作用於內層 visual。
func group_visual() -> Node2D:
	return $carry

func group_shadow() -> Node2D:
	return _shadow

func set_tilt(tilt: Vector2, perspective: float) -> void:
	_tilt.apply(tilt, perspective)

# 以臨界阻尼彈簧在 duration 秒內從目前位置移到 target；新的移動從當下位置接手前一段。
func move_to(target: Vector2, duration: float) -> void:
	if _move_tween:
		_move_tween.kill()
	_move_tween = create_tween()
	_move_tween.tween_method(_travel.bind(position, target), 0.0, 1.0, duration)

# 直接放到 target，停止進行中的移動。
func place(target: Vector2) -> void:
	if _move_tween:
		_move_tween.kill()
	position = target

func _travel(progress: float, from: Vector2, target: Vector2) -> void:
	position = from.lerp(target, Math.spring(progress))

# 左鍵按下後移動超過 START_DISTANCE 送出 drag_requested，未拖曳就放開視為點擊；吸入中的卡片落定後才能再次拿起。
func _gui_input(event: InputEvent) -> void:
	if not interaction_enabled or cat_id.is_empty() or _carried:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if event.pressed:
			_pressing = true
			_press_origin = event.position
		elif _pressing:
			_pressing = false
			clicked.emit(cat_id)
	elif event is InputEventMouseMotion and _pressing and event.position.distance_to(_press_origin) > DragConfig.START_DISTANCE:
		_pressing = false
		accept_event()
		drag_requested.emit(self, event.global_position)
