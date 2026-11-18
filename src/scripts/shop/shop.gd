extends Control

signal buy_requested(slot: int)
signal reroll_requested
signal next_requested

const Config = preload("res://src/configs/shop/shop_view_config.gd")
const Palette = preload("res://src/configs/ui/ui_palette.gd")
const Catalog = preload("res://src/configs/cat_cards/cat_catalog.gd")
const Market = preload("res://src/service/shop/cat_market.gd")
const Rules = preload("res://src/configs/shop/shop_config.gd")
const BoxStyle = preload("res://src/scripts/ui/box_style.gd")
const PopBurst = preload("res://src/scripts/motion/pop_burst.gd")

@onready var _cat_box: Panel = $cat_box
@onready var _boxes: Array = [$cat_box, $item_box, $pack_box, $action_box]
@onready var _reroll: Button = $action_box/reroll
@onready var _next: Button = $action_box/next
@onready var _owned: Label = $action_box/owned

func _ready() -> void:
	z_index = Config.LAYER
	$shade.color = Palette.SHADE
	_cat_box.build(Rules.CAT_SLOTS)
	$item_box.build(Rules.ITEM_SLOTS)
	$pack_box.build(Rules.PACK_SLOTS)
	BoxStyle.apply_button(_reroll, Config.ACTION_BUTTON_SIZE)
	BoxStyle.apply_button(_next, Config.ACTION_BUTTON_SIZE)
	_next.text = Config.NEXT_TEXT
	_owned.add_theme_font_size_override("font_size", Config.OWNED_SIZE)
	_owned.add_theme_color_override("font_color", Palette.TEXT)
	_cat_box.buy_pressed.connect(func(slot: int): buy_requested.emit(slot))
	_reroll.pressed.connect(func(): reroll_requested.emit())
	_next.pressed.connect(func(): next_requested.emit())

# 三區依序衝入並煞停，各區商品接著依序跳動，之後以波浪相位持續浮動。
func open(game: RefCounted) -> void:
	show()
	_fill(game)
	refresh(game)
	for slot in $item_box.slots + $pack_box.slots:
		slot.show_empty()
	$shade.modulate.a = 0.0
	create_tween().tween_property($shade, "modulate:a", 1.0, Config.ENTER_DURATION)
	var phase := 0.0
	for index in _boxes.size():
		_boxes[index].enter(index * Config.ENTER_STAGGER, phase)
		phase += _boxes[index].slots.size() * Config.IDLE_PHASE_STEP

# 依目前金錢與持有數更新購買按鈕、重骰費用與持有張數。
func refresh(game: RefCounted) -> void:
	for index in _cat_box.slots.size():
		var id: String = game.shop.offers[index]
		if not id.is_empty():
			_cat_box.slots[index].set_purchase(Market.price(id), game.money >= Market.price(id), game.cats.is_full())
	_reroll.text = Config.REROLL_TEXT % game.shop.reroll_cost()
	_reroll.disabled = not game.can_reroll()
	_owned.text = Config.OWNED_TEXT % [game.cats.ids.size(), Catalog.MAX_EQUIPPED]

func slot_center(slot: int) -> Vector2:
	return _cat_box.slots[slot].card_rect().get_center()

func reroll_center() -> Vector2:
	return _reroll.get_global_rect().get_center()

# 買下的卡片放大後沿弧線旋轉飛到 target，原格同時顯示已售出。
func play_buy(slot: int, target: Rect2) -> void:
	var source: Control = _cat_box.slots[slot]
	var rect: Rect2 = source.card_rect()
	var flyer := TextureRect.new()
	flyer.texture = source.card_texture()
	flyer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flyer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flyer.z_as_relative = false
	flyer.z_index = Config.FLIGHT_LAYER
	add_child(flyer)
	flyer.size = rect.size
	flyer.pivot_offset = rect.size / 2
	flyer.global_position = rect.position
	source.show_sold()
	PopBurst.play(self, source, Config.BUTTON_POP_SCALE, Config.POP)
	var flight := create_tween()
	flight.tween_property(flyer, "scale", Vector2.ONE * Config.LIFT_SCALE, Config.LIFT_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	flight.tween_method(_fly.bind(flyer, rect.position, target.position), 0.0, 1.0, Config.FLIGHT_DURATION)
	await flight.finished
	flyer.queue_free()

# 貓牌翻面收起，換上新貨後翻回並依序跳動，重骰按鈕同時彈跳。
func play_reroll(game: RefCounted) -> void:
	PopBurst.play(self, _reroll, Config.BUTTON_POP_SCALE, Config.POP)
	var closing: Tween
	for slot in _cat_box.slots:
		closing = slot.flip(true)
	await closing.finished
	_fill(game)
	refresh(game)
	var opening: Tween
	for slot in _cat_box.slots:
		opening = slot.flip(false)
	_cat_box.hop_goods()
	await opening.finished

func close() -> void:
	var last: Tween
	for index in _boxes.size():
		last = _boxes[index].exit(index * Config.EXIT_STAGGER)
	create_tween().tween_property($shade, "modulate:a", 0.0, Config.EXIT_DURATION + Config.EXIT_STAGGER * _boxes.size())
	await last.finished
	hide()

func _fill(game: RefCounted) -> void:
	for index in _cat_box.slots.size():
		var id: String = game.shop.offers[index]
		if id.is_empty():
			_cat_box.slots[index].show_sold()
		else:
			_cat_box.slots[index].show_offer(id, game.cat_state(), Market.price(id))

# 飛行以 Cubic In Out 沿高於兩端中點 FLIGHT_ARC 的弧線前進，途中旋轉一圈並從抬起尺寸縮回。
func _fly(progress: float, flyer: Control, start: Vector2, end: Vector2) -> void:
	var eased: float = Tween.interpolate_value(0.0, 1.0, progress, 1.0, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	var control := (start + end) / 2 + Vector2.UP * Config.FLIGHT_ARC
	flyer.global_position = start.lerp(control, eased).lerp(control.lerp(end, eased), eased)
	flyer.rotation = Config.FLIGHT_SPIN * eased
	flyer.scale = Vector2.ONE * lerpf(Config.LIFT_SCALE, 1.0, eased)
