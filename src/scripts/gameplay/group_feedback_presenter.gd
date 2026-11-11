extends Node

signal started
signal completed

const Entry = preload("res://src/configs/combo/combo_entry.gd")
const CardAnimator = preload("res://src/scripts/playing_card/group_card_animator.gd")
var _combo: Control
var _cards = CardAnimator.new()

func setup(combo: Control) -> void:
	_combo = combo
	add_child(_cards)

func play(entries: Array[Entry], board_cards: Dictionary) -> void:
	started.emit()
	var added: Array = await _combo.transition_to(entries)
	for index in added:
		var cards: Array[Control] = []
		for cell in entries[index].cells:
			cards.append(board_cards[cell])
		await _cards.lift(cards)
		var combo_motion: Tween = _combo.reveal(index)
		await _cards.settle()
		if combo_motion.is_running():
			await combo_motion.finished
	completed.emit()
