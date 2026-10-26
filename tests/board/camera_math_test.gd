extends SceneTree

const Config = preload("res://src/configs/board/board_config.gd")
const Frame = preload("res://src/configs/gameplay/gameplay_frame_config.gd")
const Game = preload("res://src/configs/gameplay/game_rules.gd")
const Layout = preload("res://src/service/board/board_layout.gd")
const Rules = preload("res://src/service/board/board_rules.gd")
const Touch = preload("res://src/service/board/board_touch.gd")
var failures := 0

func _init() -> void:
	_test_fit()
	_test_zoom()
	_test_touch()
	if failures == 0:
		print("Camera math passed: safe framing, placement bounds, anchored zoom and multitouch lifecycle.")
	quit(int(failures > 0))

func _test_fit() -> void:
	var occupied: Array[Vector2i] = [Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]
	var bounds := Layout.get_fit_bounds(occupied)
	for cell in occupied + Rules.get_placements(occupied):
		_check(bounds.encloses(Rect2(Layout.cell_position(cell), Config.CARD_SIZE)), "Fit includes every card and possible placement.")
	_check(Layout.get_fit_bounds([]) == Layout.get_bounds([Config.INITIAL_CELL]), "An empty board fits the initial placement.")
	var one: Array[Vector2i] = [Config.INITIAL_CELL]
	_check(Layout.get_fit_bounds(one).size == Config.CARD_SIZE + Config.CELL_STEP * 2, "Single-card fit includes all four placement neighbors.")
	for ratio in [Vector2.ONE, Vector2(0.5, 0.75), Vector2(1.5, 1.25)]:
		var clear := Layout.get_clear_rect(Frame.REFERENCE_SIZE * ratio)
		_check(clear.position.is_equal_approx(Frame.CLEAR_RECT.position * ratio), "Safe area scales with the frame position.")
		_check(clear.size.is_equal_approx(Frame.CLEAR_RECT.size * ratio), "Safe area scales with the frame dimensions.")
		var obstacles: Array[Rect2] = [
			Rect2(clear.position, clear.size * Vector2(0.2, 0.6)),
			Rect2(clear.position + clear.size * Vector2(0, 0.8), clear.size * Vector2(0.6, 0.2)),
		]
		var safe := Layout.get_free_rect(clear, obstacles)
		_check(safe.has_area() and clear.grow(0.001).encloses(safe), "Fit stays inside the black frame's clear area.")
		for obstacle in obstacles:
			_check(not safe.intersects(obstacle), "Fit excludes fixed interface areas.")
		var zoom := Layout.get_fit_zoom(bounds, safe.size)
		var position := safe.get_center() - bounds.get_center() * zoom
		var screen_bounds := Rect2(position + bounds.position * zoom, bounds.size * zoom)
		_check(safe.grow(-Config.VIEW_PADDING).grow(0.001).encloses(screen_bounds), "Cards and hidden placements retain a gap from every safe edge.")
		_check(screen_bounds.get_center().is_equal_approx(safe.get_center()), "Fit centers the complete layout in the safe area.")
	var distant: Array[Vector2i] = [Vector2i.LEFT * Game.BOARD_LIMIT * Game.MAX_PLAYS, Vector2i.RIGHT * Game.BOARD_LIMIT * Game.MAX_PLAYS]
	var wide := Layout.get_fit_bounds(distant)
	var tiny_view := Config.CARD_SIZE * 2
	var small_zoom := Layout.get_fit_zoom(wide, tiny_view)
	_check(small_zoom < Config.MIN_ZOOM, "Automatic fit can go below the manual limit to preserve full visibility.")
	_check(wide.size.x * small_zoom <= tiny_view.x - Config.VIEW_PADDING * 2 + 0.001, "Separated islands remain fully framed.")

func _test_zoom() -> void:
	_check(Layout.scroll_factor(-1) > 1, "Upward trackpad scrolling zooms in.")
	_check(Layout.scroll_factor(1) < 1, "Downward trackpad scrolling zooms out.")
	_check(is_equal_approx(Layout.scroll_factor(1) * Layout.scroll_factor(-1), 1), "Reverse scrolling cancels the zoom factor.")
	var anchor := Frame.CLEAR_RECT.get_center()
	var position := Config.CELL_STEP
	var zoom := Config.DEFAULT_ZOOM
	var world := (anchor - position) / zoom
	for step in range(1, Game.TEST_SAMPLES + 1):
		var next := lerpf(Config.DEFAULT_ZOOM, Config.ZOOM_STEP, float(step) / Game.TEST_SAMPLES)
		position = Layout.zoom_position(position, zoom, next, anchor)
		zoom = next
		_check(((anchor - position) / zoom).is_equal_approx(world), "Every intermediate zoom step preserves the anchor.")
	_check(Layout.pinch_factor(Config.CARD_SIZE, Config.CARD_SIZE * 2) == 2, "Spreading two touches doubles scale at double distance.")
	_check(Layout.pinch_factor(Vector2.ZERO, Config.CARD_SIZE) == 1, "Coincident touch origins produce a neutral factor.")

func _test_touch() -> void:
	var touch := Touch.new()
	var origin := Config.CARD_SIZE
	touch.press(0, origin)
	_check(touch.release(0, origin, false), "A single stationary touch commits a tap on release.")
	touch.press(0, origin)
	touch.move(0, origin + Vector2.RIGHT * Config.TOUCH_TAP_DISTANCE * 2)
	touch.move(0, origin)
	_check(not touch.release(0, origin, false), "Dragging out and back remains a gesture rather than a tap.")
	touch.press(0, origin)
	touch.press(1, origin * 2)
	var gesture := touch.move(1, origin * 3)
	_check(is_equal_approx(gesture.factor, 2), "Two-finger distance controls the pinch factor.")
	var position := Vector2.ZERO
	var world: Vector2 = gesture.from
	position = Layout.zoom_position(position, 1, gesture.factor, gesture.from) + gesture.to - gesture.from
	_check(((gesture.to - position) / gesture.factor).is_equal_approx(world), "The point under the old midpoint follows the new midpoint.")
	_check(not touch.release(1, origin * 3, false), "Lifting the first pinch finger never taps a placement.")
	_check(not touch.release(0, origin, false), "Lifting the remaining pinch finger never taps a card.")
	touch.press(0, origin)
	_check(not touch.release(0, origin, true), "Canceled touches never commit actions.")
	touch.press(0, origin)
	touch.clear()
	_check(touch.points.is_empty(), "Disabling input or losing focus clears tracked fingers.")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
