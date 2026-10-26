extends Control

signal card_placed(card: Control, cell: Vector2i)
signal placement_undone(card: Control, cell: Vector2i)

const Rules = preload("res://src/service/board/board_rules.gd")

var _history: Array[Dictionary] = []


func _ready() -> void:
	$hand_area.card_selected.connect(_on_card_selected)
	$board.placement_requested.connect(_place_selected_card)
	$action_buttons.action_requested.connect(_on_action_requested)
	_update_input()


func get_cards_played() -> int:
	return _history.size()


# 正式結算完成後，由關卡流程呼叫；場上的牌繼續保留。
func begin_next_turn() -> void:
	_history.clear()
	$hand_area.clear_selection()
	_update_input()


func _on_card_selected(card: Control) -> void:
	$board.set_input_enabled(card != null and Rules.can_play_this_turn(get_cards_played()))


func _place_selected_card(cell: Vector2i) -> void:
	var card: Control = $hand_area.get_selected_card()
	if card == null or not Rules.can_play_this_turn(get_cards_played()) or not $board.can_place(cell):
		return
	var entry := {"cell": cell, "index": card.get_index(), "y": card.position.y}
	card = $hand_area.take_selected_card()
	$board.place_card(card, cell)
	_history.append(entry)
	_update_input()
	card_placed.emit(card, cell)


func undo_placement() -> void:
	if _history.is_empty():
		return
	$hand_area.clear_selection()
	var entry: Dictionary = _history.pop_back()
	var card: Control = $board.take_card(entry.cell)
	$hand_area.restore_card(card, entry.index, entry.y)
	_update_input()
	placement_undone.emit(card, entry.cell)


func _on_action_requested(action_id: StringName) -> void:
	if action_id == &"undo":
		undo_placement()


func _update_input() -> void:
	$hand_area.set_selection_enabled(Rules.can_play_this_turn(get_cards_played()))
	$board.set_input_enabled($hand_area.get_selected_card() != null and Rules.can_play_this_turn(get_cards_played()))
	$action_buttons/undo.disabled = _history.is_empty()
