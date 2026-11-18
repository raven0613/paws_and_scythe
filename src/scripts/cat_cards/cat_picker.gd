extends Control

signal confirmed(ids: Array)
signal cancelled

const Catalog = preload("res://src/configs/cat_cards/cat_catalog.gd")
const Config = preload("res://src/configs/cat_cards/cat_feedback_config.gd")
const Choice = preload("res://src/scenes/cat_cards/cat_choice.tscn")
var _selected: Array = []
var _choices := {}
@onready var _content: VBoxContainer = $center/panel/margin/content

func _ready() -> void:
	$center/panel.custom_minimum_size = Config.PICKER_SIZE
	_content.get_node("title").text = Config.PICKER_TITLE
	_content.get_node("title").add_theme_font_size_override("font_size", Config.TITLE_FONT_SIZE)
	_content.get_node("description").text = Config.PICKER_DESCRIPTION.format({"limit": Catalog.MAX_EQUIPPED})
	var grid: GridContainer = _content.get_node("scroll/grid")
	grid.columns = Config.CHOICE_COLUMNS
	for id in Catalog.CARDS:
		var choice := Choice.instantiate()
		grid.add_child(choice)
		choice.configure(id)
		choice.selected.connect(_toggle)
		_choices[id] = choice
	_content.get_node("footer/start").text = Config.START_TEXT
	_content.get_node("footer/start").pressed.connect(_confirm)
	_content.get_node("footer/cancel").text = Config.CANCEL_TEXT
	_content.get_node("footer/cancel").pressed.connect(_cancel)
	_update_choices()

func open(selected: Array) -> void:
	_selected = selected.duplicate()
	_update_choices()
	show()
	_content.get_node("footer/start").grab_focus()

func _toggle(id: String, selected: bool) -> void:
	if selected:
		_selected.append(id)
	else:
		_selected.erase(id)
	_update_choices()

func _update_choices() -> void:
	for id in _choices:
		_choices[id].set_selection(_selected.has(id), _selected.size() >= Catalog.MAX_EQUIPPED)
	_content.get_node("footer/count").text = Config.PICKER_COUNT.format({"count": _selected.size(), "limit": Catalog.MAX_EQUIPPED})

func _confirm() -> void:
	hide()
	confirmed.emit(_selected.duplicate())

func _cancel() -> void:
	hide()
	cancelled.emit()
