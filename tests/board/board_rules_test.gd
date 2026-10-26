extends SceneTree

const Config = preload("res://src/configs/board/board_config.gd")
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
	for index in range(Config.MAX_PLAYS_PER_TURN * Config.NEIGHBORS.size()):
		occupied.append(Vector2i(index, 0))
	_check(Rules.can_place(occupied, Vector2i(occupied.size(), 0)), "Board capacity is decided at settlement, not by placement geometry.")
	for count in range(Config.MAX_PLAYS_PER_TURN + 1):
		_check(Rules.can_play_this_turn(count) == (count < Config.MAX_PLAYS_PER_TURN), "The turn placement limit must follow config.")
	var all_cells: Array[Vector2i] = occupied.duplicate()
	all_cells.append_array(Rules.get_placements(occupied))
	var bounds: Rect2 = Layout.get_bounds(all_cells)
	var view := Config.CARD_SIZE * Vector2(6, 5)
	var zoom: float = Layout.get_fit_zoom(bounds, view)
	_check(zoom <= Config.DEFAULT_ZOOM, "Auto-fit must not enlarge cards past their native scale.")
	_check(bounds.size.x * zoom <= view.x - Config.VIEW_PADDING * 2, "Wide boards and their placements must fit.")
	_check(bounds.size.y * zoom <= view.y - Config.VIEW_PADDING * 2, "Tall boards and their placements must fit.")
	if failures == 0:
		print("Board rules passed: initial cell, neighbors, holes, islands, uniqueness, turn limit and view fitting.")
	quit(int(failures > 0))


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
