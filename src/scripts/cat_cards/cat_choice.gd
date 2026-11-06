extends PanelContainer

signal selected(id: String, enabled: bool)

const Catalog = preload("res://src/configs/cat_cards/cat_catalog.gd")
const Config = preload("res://src/configs/cat_cards/cat_feedback_config.gd")
var cat_id := ""

func configure(id: String) -> void:
	cat_id = id
	custom_minimum_size = Config.CHOICE_SIZE
	$margin/content/check.text = "[ ] %s / %s" % [Catalog.CARDS[id].name, Catalog.CARDS[id].rarity]
	$margin/content/check.add_theme_font_size_override("font_size", Config.CHOICE_FONT_SIZE)
	$margin/content/description.text = Catalog.description(id)
	$margin/content/description.add_theme_font_size_override("font_size", Config.DESCRIPTION_FONT_SIZE)
	$margin/content/check.toggled.connect(func(enabled): selected.emit(cat_id, enabled))

func set_selection(enabled: bool, full: bool) -> void:
	$margin/content/check.text = "%s %s / %s" % ["[+]" if enabled else "[ ]", Catalog.CARDS[cat_id].name, Catalog.CARDS[cat_id].rarity]
	$margin/content/check.set_pressed_no_signal(enabled)
	$margin/content/check.disabled = full and not enabled
	modulate = Config.ACTIVE_COLOR if enabled else Color.WHITE
