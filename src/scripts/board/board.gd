@tool
extends Control

signal placement_requested(cell: Vector2i)

const Config = preload("res://src/configs/board/board_config.gd")
const Rules = preload("res://src/service/board/board_rules.gd")
const Layout = preload("res://src/service/board/board_layout.gd")
const PlacementScene = preload("res://src/scenes/card_placement/card_placement.tscn")
const Camera = preload("res://src/scripts/board/board_camera.gd")
const ViewArea = preload("res://src/scripts/board/board_view_area.gd")
var _cards: Dictionary = {}
var _placements: Dictionary = {}
var _input_enabled := false
var _camera: Node
var _show_initial := true
var _focus_tween: Tween
var _focused: Array[Control] = []
var _home: Dictionary = {}
var _view_area: RefCounted

func _ready() -> void:
	_camera = Camera.new()
	add_child(_camera)
	_camera.setup(self, $content)
	_refresh_placements()

func get_occupied_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	result.assign(_cards.keys())
	return result

func can_place(cell: Vector2i) -> bool:
	return Rules.can_place(get_occupied_cells(), cell)

func show_cards(cards: Dictionary) -> void:
	reset_focus()
	var previous_cells := get_occupied_cells()
	_cards = cards
	for cell in _cards:
		var card: Control = _cards[cell]
		if card.get_parent() != $content/cards:
			card.reparent($content/cards, false)
		card.selected = false
		card.position = Layout.cell_position(cell)
		card.visible = true
	var current_cells := get_occupied_cells()
	previous_cells.sort()
	current_cells.sort()
	if previous_cells != current_cells:
		_refresh_placements()

func set_input_enabled(enabled: bool, show_initial: bool = true) -> void:
	_input_enabled = enabled
	_show_initial = show_initial
	for placement in _placements.values():
		placement.set_input_enabled(enabled, enabled or (_cards.is_empty() and _show_initial))

func set_auto_follow(enabled: bool) -> void:
	_camera.set_auto_follow(enabled)

func reset_view() -> void:
	if _camera.auto_follow:
		_camera.fit_view()

func fit_all_cards() -> void:
	_camera.fit_view()

func zoom_center(direction: int) -> void:
	_camera.zoom_center(direction)

func configure_view(frame: Control, overlays: Array[Control]) -> void:
	_view_area = ViewArea.new()
	_view_area.setup(self, frame, overlays)
	reset_view()

func get_fit_rect() -> Rect2:
	return _view_area.fit_rect() if _view_area else Layout.get_clear_rect(size)

func allows_camera_at(point: Vector2) -> bool:
	return _view_area != null and _view_area.allows(point)

func set_camera_input_enabled(enabled: bool) -> void:
	_camera.input_enabled = enabled

func set_motion_paused(paused: bool) -> void:
	_camera.motion_paused = paused
	if paused:
		reset_focus()

func has_card_at(point: Vector2) -> bool:
	for card in _cards.values():
		if ViewArea.contains_point(card, point):
			return true
	return false

func has_active_placement_at(point: Vector2) -> bool:
	for placement in _placements.values():
		if not placement.disabled and ViewArea.contains_point(placement, point):
			return true
	return false

func tap_at(point: Vector2) -> void:
	for card in _cards.values():
		if card.selection_enabled and ViewArea.contains_point(card, point):
			card.selection_requested.emit(card)
			return
	for placement in _placements.values():
		if not placement.disabled and ViewArea.contains_point(placement, point):
			_on_placement_requested(placement.cell)
			return

func _refresh_placements() -> void:
	var cells := Rules.get_placements(get_occupied_cells())
	for cell in _placements.keys():
		if not cells.has(cell):
			_placements[cell].retire()
			_placements.erase(cell)
	for cell in cells:
		if not _placements.has(cell):
			var placement = PlacementScene.instantiate()
			placement.cell = cell
			placement.position = Layout.cell_position(cell)
			$content/placements.add_child(placement)
			placement.placement_requested.connect(_on_placement_requested)
			_placements[cell] = placement
		var placement: Control = _placements[cell]
		placement.state = placement.State.INITIAL if _cards.is_empty() else placement.State.AVAILABLE
		placement.set_input_enabled(_input_enabled, _input_enabled or (_cards.is_empty() and _show_initial))
	reset_view()

func _on_placement_requested(cell: Vector2i) -> void:
	if _input_enabled and can_place(cell):
		placement_requested.emit(cell)


func focus_group(cells: Array) -> void:
	if cells.is_empty() and _focused.is_empty():
		return
	if _focus_tween:
		_focus_tween.kill()
	_focus_tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var center := Vector2.ZERO
	if not cells.is_empty():
		var typed: Array[Vector2i] = []
		typed.assign(cells)
		center = Layout.get_bounds(typed).get_center()
	for cell in cells:
		var card: Control = _cards[cell]
		if not _home.has(card):
			_home[card] = Layout.cell_position(cell)
		if not _focused.has(card):
			_focused.append(card)
	for card in _focused:
		var active := false
		for cell in cells:
			if _cards[cell] == card:
				active = true
		var factor := Config.GROUP_HOVER_SCALE if active else 1.0
		var base: Vector2 = _home[card]
		var target := center + (base + card.pivot_offset - center) * factor - card.pivot_offset if active else base
		card.z_index = 1 if active else 0
		_focus_tween.tween_property(card, "position", target, Config.GROUP_HOVER_DURATION)
		_focus_tween.tween_property(card, "scale", Vector2.ONE * factor, Config.GROUP_HOVER_DURATION)

func reset_focus() -> void:
	if _focus_tween:
		_focus_tween.kill()
	for card in _focused:
		card.position = _home[card]
		card.scale = Vector2.ONE
		card.z_index = 0
	_focused.clear()
	_home.clear()
