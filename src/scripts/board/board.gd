@tool
extends Control

signal placement_requested(cell: Vector2i)

const Config = preload("res://src/configs/board/board_config.gd")
const Rules = preload("res://src/service/board/board_rules.gd")
const Layout = preload("res://src/service/board/board_layout.gd")
const PlacementScene = preload("res://src/scenes/card_placement/card_placement.tscn")

var _cards: Dictionary = {}
var _input_enabled := false
var _fit_tween: Tween


func _ready() -> void:
	resized.connect(_fit_view)
	_refresh_placements()


func get_occupied_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	result.assign(_cards.keys())
	return result


func can_place(cell: Vector2i) -> bool:
	return Rules.can_place(get_occupied_cells(), cell)


func place_card(card: Control, cell: Vector2i) -> bool:
	if not can_place(cell):
		return false
	_cards[cell] = card
	if card.get_parent():
		card.reparent($content/cards, false)
	else:
		$content/cards.add_child(card)
	card.selection_enabled = false
	card.selected = false
	card.position = Layout.cell_position(cell)
	card.visible = true
	_refresh_placements()
	return true


func take_card(cell: Vector2i) -> Control:
	if not _cards.has(cell):
		return null
	var card: Control = _cards[cell]
	_cards.erase(cell)
	$content/cards.remove_child(card)
	_refresh_placements()
	return card


func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled
	for placement in $content/placements.get_children():
		placement.set_input_enabled(enabled)


func _refresh_placements() -> void:
	for placement in $content/placements.get_children():
		$content/placements.remove_child(placement)
		placement.queue_free()
	for cell in Rules.get_placements(get_occupied_cells()):
		var placement = PlacementScene.instantiate()
		placement.cell = cell
		placement.state = placement.State.INITIAL if _cards.is_empty() else placement.State.AVAILABLE
		placement.position = Layout.cell_position(cell)
		$content/placements.add_child(placement)
		placement.set_input_enabled(_input_enabled)
		placement.placement_requested.connect(_on_placement_requested)
	_fit_view()


func _on_placement_requested(cell: Vector2i) -> void:
	if _input_enabled and can_place(cell):
		placement_requested.emit(cell)


func _fit_view() -> void:
	if not is_node_ready():
		return
	var cells := get_occupied_cells()
	cells.append_array(Rules.get_placements(cells))
	var bounds := Layout.get_bounds(cells)
	var zoom := Layout.get_fit_zoom(bounds, size)
	var target := (size / 2.0 - bounds.get_center() * zoom).round()
	if _fit_tween:
		_fit_tween.kill()
	if Engine.is_editor_hint() or _cards.is_empty():
		$content.position = target
		$content.scale = Vector2.ONE * zoom
	else:
		_fit_tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_fit_tween.tween_property($content, "position", target, Config.FIT_DURATION)
		_fit_tween.tween_property($content, "scale", Vector2.ONE * zoom, Config.FIT_DURATION)


func _exit_tree() -> void:
	if _fit_tween:
		_fit_tween.kill()
