@tool
extends Control

signal reorder_requested(source: String, destination: String)

const Catalog = preload("res://src/configs/cat_cards/cat_catalog.gd")
const Config = preload("res://src/configs/cat_cards/cat_feedback_config.gd")
const Activation = preload("res://src/configs/cat_cards/cat_activation_config.gd")
const Numbers = preload("res://src/configs/gameplay/gameplay_ui_config.gd")
const Effects = preload("res://src/service/cat_cards/effect_rules.gd")
const CardMotion = preload("res://src/service/cat_cards/activation/card_motion.gd")
const Badge = preload("res://src/scripts/cat_cards/activation/activation_badge.gd")
const TILT_SHADER = preload("res://src/scripts/cat_cards/activation/card_tilt.gdshader")
var cat_id := ""
var description_text := ""
var interaction_enabled := false
var _badge: Node2D
var _tilt: ShaderMaterial
var _clock := 0.0
var _speed := 1.0
var _shadow_rest := Vector2.ZERO

func _ready() -> void:
	set_process(false)
	if Engine.is_editor_hint():
		return
	mouse_filter = Control.MOUSE_FILTER_STOP
	_tilt = ShaderMaterial.new()
	_tilt.shader = TILT_SHADER
	_tilt.set_shader_parameter("perspective", Activation.CARD_PERSPECTIVE)
	_tilt.set_shader_parameter("card_size", Config.CARD_SIZE)
	_tilt.set_shader_parameter("margin", Activation.CARD_TILT_MARGIN)
	$visual.material = _tilt
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
func begin_feedback(text: String) -> void:
	_clock = 0.0
	z_index = Activation.LAYER
	_badge.text = text
	_badge.visible = not text.is_empty()
	set_process(true)
	_apply()

func _process(delta: float) -> void:
	_clock += delta * _speed
	if CardMotion.finished(_clock):
		reset_feedback()
	else:
		_apply()

func _apply() -> void:
	var pose := CardMotion.pose(_clock)
	$visual.position = pose.offset
	$visual.scale = Vector2.ONE * pose.scale
	$visual.rotation = pose.rotation
	$visual/shadow.position = CardMotion.shadow(_shadow_rest, _clock)
	_tilt.set_shader_parameter("tilt", pose.tilt)
	_badge.position = Config.CARD_SIZE / 2 + pose.anchor
	_badge.update(_clock)

func reset_feedback() -> void:
	set_process(false)
	$visual.position = Vector2.ZERO
	$visual.scale = Vector2.ONE
	$visual.rotation = 0.0
	$visual/shadow.position = _shadow_rest
	_tilt.set_shader_parameter("tilt", Vector2.ZERO)
	z_index = 0
	_badge.hide()

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not interaction_enabled or cat_id.is_empty():
		return null
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
