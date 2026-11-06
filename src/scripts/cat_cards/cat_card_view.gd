@tool
extends Control

signal reorder_requested(source: String, destination: String)

const Catalog = preload("res://src/configs/cat_cards/cat_catalog.gd")
const Config = preload("res://src/configs/cat_cards/cat_feedback_config.gd")
const Numbers = preload("res://src/configs/gameplay/gameplay_ui_config.gd")
const Effects = preload("res://src/service/cat_cards/effect_rules.gd")
var cat_id := ""
var description_text := ""
var interaction_enabled := false
var _effect: Label

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	mouse_filter = Control.MOUSE_FILTER_STOP
	_effect = _label(Config.EFFECT_RECT, Config.EFFECT_FONT_SIZE)
	_effect.add_theme_color_override("font_color", Config.ACTIVE_COLOR)
	_effect.hide()
	HoverInfo.bind_source(self, _hover_content)

func _hover_content() -> Array:
	if cat_id.is_empty():
		return ["", ""]
	var definition: Dictionary = Catalog.CARDS[cat_id]
	return ["%s / %s" % [definition.name, definition.rarity], description_text]

func configure(id: String, state: Dictionary) -> void:
	cat_id = id
	$artwork.texture = load(Catalog.art(id))
	description_text = Catalog.description(id)
	var definition: Dictionary = Catalog.CARDS[id]
	if Config.CURRENT_AMOUNT_MEASURES.has(definition.measure):
		var amount := Effects.amount(definition, state, -1)
		description_text += "\n" + Config.CURRENT_AMOUNT_TEXT % Numbers.precise(amount)

func _label(rect: Rect2, font_size: int) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Config.TEXT_OUTLINE)
	label.add_theme_constant_override("outline_size", Config.OUTLINE_SIZE)
	add_child(label)
	return label

func begin_feedback(text: String) -> void:
	_effect.text = text
	_effect.show()
	z_index = Config.SOURCE_LAYER
	feedback_progress(0)

func feedback_progress(progress: float) -> void:
	var phase := progress / Config.POP_PEAK if progress < Config.POP_PEAK else (1 - progress) / (1 - Config.POP_PEAK)
	var strength := sin(phase * PI / 2)
	scale = Vector2.ONE * lerpf(1.0, Config.SOURCE_SCALE, strength)
	rotation = sin(progress * TAU) * Config.SOURCE_TILT * (1 - progress)
	$artwork.modulate = Color.WHITE.lerp(Config.ACTIVE_COLOR, strength)
	_effect.modulate.a = 1.0 - pow(progress, 4)
	if progress >= 1:
		reset_feedback()

func reset_feedback() -> void:
	scale = Vector2.ONE
	rotation = 0
	z_index = 0
	$artwork.modulate = Color.WHITE
	_effect.hide()

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not interaction_enabled or cat_id.is_empty():
		return null
	var preview := TextureRect.new()
	preview.texture = $artwork.texture
	preview.custom_minimum_size = Config.CARD_SIZE
	preview.modulate.a = 0.85
	set_drag_preview(preview)
	return {"type": "cat_card", "id": cat_id}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return interaction_enabled and data is Dictionary and data.get("type") == "cat_card" and data.id != cat_id

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	reorder_requested.emit(data.id, cat_id)
