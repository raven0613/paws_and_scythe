extends RefCounted

const Config = preload("res://src/configs/board/board_config.gd")
const Layout = preload("res://src/service/board/board_layout.gd")
var points: Dictionary = {}
var _origin := Vector2.ZERO
var _can_tap := false

func press(index: int, position: Vector2) -> void:
	if points.is_empty():
		_origin = position
		_can_tap = true
	points[index] = position
	if points.size() > 1:
		_can_tap = false

func move(index: int, position: Vector2) -> Dictionary:
	var previous := points.values()
	points[index] = position
	if position.distance_to(_origin) > Config.TOUCH_TAP_DISTANCE:
		_can_tap = false
	if points.size() != 2:
		return {}
	var current := points.values()
	return {
		"from": (previous[0] + previous[1]) / 2,
		"to": (current[0] + current[1]) / 2,
		"factor": Layout.pinch_factor(previous[1] - previous[0], current[1] - current[0]),
	}

func release(index: int, position: Vector2, canceled: bool) -> bool:
	var tapped := _can_tap and not canceled and position.distance_to(_origin) <= Config.TOUCH_TAP_DISTANCE
	points.erase(index)
	return tapped

func clear() -> void:
	points.clear()
	_can_tap = false
