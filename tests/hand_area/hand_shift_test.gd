extends SceneTree

const Shift = preload("res://src/service/hand_area/hand_shift.gd")
const Config = preload("res://src/configs/hand_area/hand_area_config.gd")
var failures := 0

func _init() -> void:
	var hand := [10, 11, 12, 13, 14, 15]
	var played := Shift.plan(hand, [10, 11, 13, 14, 15], Config.SHIFT_INTERVAL)
	_check(played.map(func(m): return m.id) == [13, 14, 15], "Cards right of the gap shift left")
	_check(played.map(func(m): return m.to) == [2, 3, 4], "Each card fills the slot to its left")
	_check(played.map(func(m): return m.delay) == [0.0, Config.SHIFT_INTERVAL, 2 * Config.SHIFT_INTERVAL], "The card nearest the gap leads and the rest follow one by one")
	_check(is_equal_approx(Shift.edge_delay(played), 2 * Config.SHIFT_INTERVAL), "The background edge follows the last moving card")
	var last := Shift.plan(hand, hand.slice(0, -1), Config.SHIFT_INTERVAL)
	_check(last.is_empty() and Shift.edge_delay(last) == 0.0, "Playing the rightmost card moves nothing and shrinks the background at once")
	var replaced := Shift.plan(hand, [10, 20, 12, 21, 14, 15], Config.SHIFT_INTERVAL)
	_check(replaced.is_empty(), "Discards refilled in place keep every other card in its slot")
	var depleted := Shift.plan(hand, [10, 12, 14, 15], Config.SHIFT_INTERVAL)
	_check(depleted.map(func(m): return [m.id, m.to]) == [[12, 1], [14, 2], [15, 3]], "Several gaps close from left to right")
	var undo := Shift.plan([10, 11, 13, 14], [10, 11, 12, 13, 14], 0.0)
	_check(undo.map(func(m): return [m.id, m.to]) == [[13, 3], [14, 4]] and undo.all(func(m): return m.delay == 0.0), "Undo opens the slot with every card moving together")
	print("Hand shift: %d failures" % failures)
	quit(1 if failures else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
