extends Panel

signal buy_pressed(slot: int)

const Config = preload("res://src/configs/shop/shop_view_config.gd")
const Palette = preload("res://src/configs/ui/ui_palette.gd")
const BoxStyle = preload("res://src/scripts/ui/box_style.gd")
const Slot = preload("res://src/scripts/shop/shop_slot.gd")

# section 為 SECTION_TITLES 的索引，-1 表示不顯示標題。
@export var section := -1

var slots: Array = []
var _rest := Vector2.ZERO

func _ready() -> void:
	_rest = position
	pivot_offset = size / 2
	add_theme_stylebox_override("panel", BoxStyle.flat(Palette.PANEL, Palette.PANEL_BORDER))
	if section >= 0:
		var title := Label.new()
		title.text = Config.SECTION_TITLES[section]
		title.size = Vector2(size.x, Config.SLOT_TOP)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", Config.SECTION_TITLE_SIZE)
		title.add_theme_color_override("font_color", Palette.TITLE)
		add_child(title)

# 建立 count 個商品格，水平置中排列。
func build(count: int) -> void:
	var width := count * Config.SLOT_SIZE.x + maxi(count - 1, 0) * Config.SLOT_GAP
	for index in count:
		var slot := Slot.new()
		slot.position = Vector2((size.x - width) / 2 + index * (Config.SLOT_SIZE.x + Config.SLOT_GAP), Config.SLOT_TOP)
		add_child(slot)
		slot.buy_pressed.connect(func(): buy_pressed.emit(index))
		slots.append(slot)

# 從下方衝入並帶傾角，衝過頭一點後煞回原位，落定時壓扁回彈，接著區內商品依序往上跳。
func enter(delay: float, phase_offset: float) -> void:
	position = _rest + Config.ENTER_OFFSET
	rotation = Config.ENTER_TILT
	scale = Vector2.ONE
	for index in slots.size():
		slots[index].phase = phase_offset + index * Config.IDLE_PHASE_STEP
		slots[index].set_idle(false)
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(self, "position", _rest + Vector2.UP * Config.BRAKE_OVERSHOOT, Config.ENTER_DURATION).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "rotation", 0.0, Config.ENTER_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_land)
	tween.tween_property(self, "position", _rest, Config.BRAKE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func exit(delay: float) -> Tween:
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(self, "position", _rest + Config.EXIT_OFFSET, Config.EXIT_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	return tween

func hop_goods() -> void:
	for index in slots.size():
		slots[index].hop(index * Config.HOP_STAGGER)

func _land() -> void:
	scale = Config.LAND_SQUASH
	create_tween().tween_property(self, "scale", Vector2.ONE, Config.LAND_DURATION).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	hop_goods()
	for slot in slots:
		slot.set_idle(true)
