extends SceneTree

const Config = preload("res://src/configs/board/board_config.gd")
const GameRules = preload("res://src/configs/gameplay/game_rules.gd")
const Rules = preload("res://src/service/board/board_rules.gd")
const Layout = preload("res://src/service/board/board_layout.gd")

var failures: int = 0


func _init() -> void:
	_check(Rules.get_placements([]) == [Config.INITIAL_CELL], "Empty boards start at the initial cell.")
	_check(not Rules.can_place([], Vector2i.ONE), "The first card must use the initial cell.")
	var occupied: Array[Vector2i] = [Config.INITIAL_CELL]
	var placements: Array[Vector2i] = Rules.get_placements(occupied)
	_check(placements.size() == Config.NEIGHBORS.size(), "One card exposes four neighbors.")
	for direction in Config.NEIGHBORS:
		_check(placements.has(Config.INITIAL_CELL + direction), "Every orthogonal neighbor must be offered.")
	_check(not placements.has(Vector2i.ONE), "Diagonal contact is insufficient.")
	_check(not placements.has(Config.INITIAL_CELL), "Occupied cells cannot be offered.")
	occupied.assign([Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN])
	placements = Rules.get_placements(occupied)
	_check(placements.count(Vector2i.ONE) == 1, "Shared empty neighbors must be deduplicated.")
	occupied.assign([Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN])
	_check(Rules.can_place(occupied, Vector2i.ZERO), "The hole inside a ring can be filled.")
	occupied.assign([Vector2i(-30, -20), Vector2i(40, 50)])
	for cell in occupied:
		for direction in Config.NEIGHBORS:
			_check(Rules.can_place(occupied, cell + direction), "Each island exposes neighbors at unrestricted coordinates.")
	_check(not Rules.can_place(occupied, Config.INITIAL_CELL), "An occupied board does not recreate an unrelated initial cell.")
	occupied.clear()
	for index in range(GameRules.BOARD_LIMIT + GameRules.MAX_PLAYS):
		occupied.append(Vector2i(index, 0))
	_check(Rules.can_place(occupied, Vector2i(occupied.size(), 0)), "Board capacity is decided at settlement, not by placement geometry.")
	var all_cells: Array[Vector2i] = occupied.duplicate()
	all_cells.append_array(Rules.get_placements(occupied))
	var bounds: Rect2 = Layout.get_bounds(all_cells)
	var view := Config.CARD_SIZE * Vector2(6, 5)
	var zoom: float = Layout.get_fit_zoom(bounds, view)
	_check(zoom <= Config.DEFAULT_ZOOM, "Auto-fit must not enlarge cards past their native scale.")
	_check(bounds.size.x * zoom <= view.x - Config.VIEW_PADDING * 2, "Wide boards and their placements must fit.")
	_check(bounds.size.y * zoom <= view.y - Config.VIEW_PADDING * 2, "Tall boards and their placements must fit.")
	var anchor := Config.CARD_SIZE * Vector2(3, 2)
	var position := -Config.CELL_STEP
	var before := (anchor - position) / Config.DEFAULT_ZOOM
	var after := Layout.zoom_position(position, Config.DEFAULT_ZOOM, Config.ZOOM_STEP, anchor)
	_check(((anchor - after) / Config.ZOOM_STEP).is_equal_approx(before), "Cursor world position is preserved when zooming")
	var restored := Layout.zoom_position(after, Config.ZOOM_STEP, Config.DEFAULT_ZOOM, anchor)
	_check(restored.is_equal_approx(position), "Zooming in and out at the same cursor restores position")
	var actual_bounds := Layout.get_bounds([Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP])
	var fit := Layout.get_fit_zoom(actual_bounds, view, Config.MAX_ZOOM)
	var centered := view / 2 - actual_bounds.get_center() * fit
	_check((centered + actual_bounds.get_center() * fit).is_equal_approx(view / 2), "Fit centers asymmetrical card groups")
	_check(actual_bounds.size.x * fit <= view.x - Config.VIEW_PADDING * 2, "Reset fit contains all card widths")
	_check(actual_bounds.size.y * fit <= view.y - Config.VIEW_PADDING * 2, "Reset fit contains all card heights")
	if failures == 0:
		print("Board rules passed: initial cell, neighbors, holes, islands, uniqueness and view fitting.")
	quit(int(failures > 0))


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
