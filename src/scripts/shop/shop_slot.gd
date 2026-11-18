extends Control

signal buy_pressed

const Config = preload("res://src/configs/shop/shop_view_config.gd")
const Palette = preload("res://src/configs/ui/ui_palette.gd")
const Catalog = preload("res://src/configs/cat_cards/cat_catalog.gd")
const Feedback = preload("res://src/configs/cat_cards/cat_feedback_config.gd")
const CardScene = preload("res://src/scenes/cat_card.tscn")
const BoxStyle = preload("res://src/scripts/ui/box_style.gd")

var phase := 0.0
var idle := false
# 商品的跳動與浮動作用於 goods，購買按鈕維持在原位。
var _goods := Control.new()
var _placeholder := Panel.new()
var _rarity := Label.new()
var _sold := Label.new()
var _buy := Button.new()
var _card: Control
var _hop := 0.0
var _time := 0.0
var _idle_weight := 0.0

func _ready() -> void:
	size = Config.SLOT_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_goods.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_goods.size = Config.SLOT_SIZE
	_goods.pivot_offset = Config.SLOT_SIZE / 2
	add_child(_goods)
	var card_position := Vector2((Config.SLOT_SIZE.x - Feedback.CARD_SIZE.x) / 2, Config.RARITY_HEIGHT)
	_placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_placeholder.position = card_position
	_placeholder.size = Feedback.CARD_SIZE
	_placeholder.add_theme_stylebox_override("panel", BoxStyle.flat(Palette.SLOT, Palette.SLOT_BORDER))
	_goods.add_child(_placeholder)
	_card = CardScene.instantiate()
	_card.position = card_position
	_goods.add_child(_card)
	_rarity.size = Vector2(Config.SLOT_SIZE.x, Config.RARITY_HEIGHT)
	_rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rarity.add_theme_font_size_override("font_size", Config.RARITY_SIZE)
	_goods.add_child(_rarity)
	_sold.position = card_position
	_sold.size = Feedback.CARD_SIZE
	_sold.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sold.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_sold.add_theme_font_size_override("font_size", Config.BUTTON_SIZE)
	_sold.add_theme_color_override("font_color", Palette.DETAIL)
	_sold.text = Config.SOLD_TEXT
	_goods.add_child(_sold)
	_buy.position = Vector2(0, Config.RARITY_HEIGHT + Feedback.CARD_SIZE.y + Config.BUTTON_GAP)
	_buy.size = Vector2(Config.SLOT_SIZE.x, Config.BUTTON_HEIGHT)
	BoxStyle.apply_button(_buy, Config.BUTTON_SIZE)
	_buy.pressed.connect(func(): buy_pressed.emit())
	add_child(_buy)
	show_empty()

func show_offer(id: String, state: Dictionary, price: int) -> void:
	_card.configure(id, state)
	_card.show()
	_rarity.text = Catalog.CARDS[id].rarity
	_rarity.add_theme_color_override("font_color", Config.RARITY_COLORS[Catalog.CARDS[id].rarity])
	_rarity.show()
	_sold.hide()
	_buy.show()
	_buy.text = Config.BUY_TEXT % price

func show_sold() -> void:
	_card.hide()
	_rarity.hide()
	_sold.show()
	_buy.hide()

# 尚未開放的區塊只顯示空卡位。
func show_empty() -> void:
	show_sold()
	_sold.hide()

# 錢不夠時按鈕停用並以警示色顯示價格；貓牌已滿時顯示已達上限。
func set_purchase(price: int, affordable: bool, full: bool) -> void:
	_buy.text = Config.FULL_TEXT if full else Config.BUY_TEXT % price
	_buy.disabled = full or not affordable
	_buy.add_theme_color_override("font_disabled_color", Palette.BUTTON_DISABLED_TEXT if full else Palette.WARNING)

func card_rect() -> Rect2:
	return _card.get_global_rect()

func card_texture() -> Texture2D:
	return _card.get_node("visual/artwork").texture

func hide_card() -> void:
	_card.hide()
	_rarity.hide()

func hop(delay: float) -> void:
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_method(_set_hop, 0.0, 1.0, Config.HOP_DURATION)

func flip(closing: bool) -> Tween:
	var tween := create_tween()
	tween.tween_property(_goods, "scale:x", 0.0 if closing else 1.0, Config.FLIP_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN if closing else Tween.EASE_OUT)
	return tween

func set_idle(enabled: bool) -> void:
	idle = enabled
	set_process(true)

# 跳動以半個正弦往上再落回；停留時依相位上下浮動形成波浪，浮動幅度在 IDLE_FADE 內漸入漸出。
func _set_hop(progress: float) -> void:
	_hop = -sin(progress * PI) * Config.HOP_HEIGHT

func _process(delta: float) -> void:
	_time += delta
	_idle_weight = move_toward(_idle_weight, 1.0 if idle else 0.0, delta / Config.IDLE_FADE)
	_goods.position.y = _hop + sin(_time / Config.IDLE_PERIOD * TAU + phase) * Config.IDLE_AMPLITUDE * _idle_weight
