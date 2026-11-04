extends Control

const Rules = preload("res://src/configs/gameplay/game_rules.gd")
const UI = preload("res://src/configs/gameplay/gameplay_ui_config.gd")
const Run = preload("res://src/service/gameplay/run_state.gd")
const Cards = preload("res://src/service/gameplay/cards.gd")
const Entry = preload("res://src/configs/combo/combo_entry.gd")
const CardScene = preload("res://src/scenes/playing_card.tscn")
const Dealer = preload("res://src/scripts/hand_area/hand_dealer.gd")
const Presenter = preload("res://src/scripts/gameplay/settlement_presenter.gd")

var game = Run.new()
var _views: Dictionary = {}
var _reserve := Node2D.new()
var _presenter := Presenter.new()
var _dealer := Dealer.new()
var _mode: StringName = &""
var _swap_first: Variant = null
var _busy := false
var _preview: Dictionary = {}

func _ready() -> void:
	_reserve.name = "card_reserve"
	_reserve.visible = false
	add_child(_reserve)
	add_child(_dealer)
	_dealer.completed.connect(_finish_deal)
	_dealer.card_emitted.connect($resources_display.set_deck_count)
	add_child(_presenter)
	_presenter.setup($settlement_score, $combo, $level_board, self)
	_presenter.completed.connect(_complete_settlement)
	$hand_area.clear_preview()
	$hand_area.selection_changed.connect(_on_hand_selection_changed)
	$board.placement_requested.connect(_place_selected_card)
	$action_buttons.action_requested.connect(_on_action_requested)
	$combo.group_hovered.connect(_on_group_hovered)
	$camera_controls.auto_changed.connect($board.set_auto_follow)
	$camera_controls.zoom_requested.connect($board.zoom_center)
	$camera_controls.reset_requested.connect($board.fit_all_cards)
	var camera_overlays: Array[Control] = [
		$level_board, $action_buttons, $combo, $cat_card_area, $hand_area,
		$convert_card_area, $boss, $camera_controls, $resources_display,
	]
	$board.configure_view($gameplay_frame, camera_overlays)
	$gameplay_hud.continue_requested.connect(_next_level)
	$gameplay_hud.restart_requested.connect(_start_run)
	_start_run()

func _start_run() -> void:
	_busy = true
	_clear_selection()
	game.start()
	$level_board.reset_score(game.score)
	$gameplay_hud.hide_outcome()
	$combo.clear_results()
	$combo.reroll_layout()
	_refresh_and_deal()
	$board.reset_view()

func _next_level() -> void:
	if game.advance():
		_busy = true
		$level_board.reset_score(game.score)
		_clear_selection()
		$gameplay_hud.hide_outcome()
		$combo.clear_results()
		_refresh_and_deal()
		$board.reset_view()

func _view(card_id: int) -> Control:
	if not _views.has(card_id):
		var card := CardScene.instantiate()
		_reserve.add_child(card)
		card.set_card(card_id)
		card.selection_requested.connect(_on_card_requested)
		_views[card_id] = card
	return _views[card_id]

func _refresh() -> void:
	$board.reset_focus()
	var active: Array = game.hand + game.board.values()
	for card_id in _views:
		if not active.has(card_id):
			var card: Control = _views[card_id]
			if card.get_parent() != _reserve:
				card.reparent(_reserve, false)
			card.selection_enabled = false
	var board_views := {}
	for cell in game.board:
		board_views[cell] = _view(game.board[cell])
	$board.show_cards(board_views)
	var hand_views: Array = []
	for card_id in game.hand:
		hand_views.append(_view(card_id))
	$hand_area.show_cards(hand_views)
	_preview = game.preview()
	var entries: Array[Entry] = []
	for group in _preview.groups:
		var entry := Entry.new()
		entry.hand_name = Rules.HAND_NAMES[group.kind]
		entry.score = int(group.score)
		entry.cells = group.cells
		entry.direction = group.direction
		entry.kind = group.kind
		entries.append(entry)
	$combo.entries = entries
	$level_board.level = game.level
	$level_board.current_score = game.score
	$level_board.target_score = game.target()
	_update_input()
	_refresh_marks()

func _on_card_requested(card: Control) -> void:
	if _busy or game.status != Run.Status.PLAYING:
		return
	if game.hand.has(card.card_id):
		$hand_area.select_card(card)
		return
	var cell: Vector2i = game.board.find_key(card.card_id)
	if _mode == &"remove":
		if game.dig(cell):
			_refresh()
	elif _mode == &"swap":
		if _swap_first == null:
			_swap_first = cell
		elif _swap_first == cell:
			_swap_first = null
		else:
			game.swap(_swap_first, cell)
			_swap_first = null
		_refresh()

func _on_hand_selection_changed() -> void:
	_mode = &""
	_swap_first = null
	if not _preview.is_empty():
		_update_input()
		_refresh_marks()

func _clear_selection() -> void:
	_mode = &""
	_swap_first = null
	$hand_area.clear_selection()

func _place_selected_card(cell: Vector2i) -> void:
	var selected: Array = $hand_area.get_selected_ids()
	if _busy or selected.size() != 1 or _mode != &"":
		return
	if game.place(selected[0], cell):
		_clear_selection()
		_refresh()

func _on_action_requested(action_id: StringName) -> void:
	if _busy or game.status != Run.Status.PLAYING:
		return
	match action_id:
		&"done":
			if game.can_settle():
				_busy = true
				_clear_selection()
				_update_input()
				_presenter.play(_preview, game.score)
		&"discard":
			if game.discard($hand_area.get_selected_ids()):
				_busy = true
				_clear_selection()
				_refresh_and_deal()
		&"undo":
			if game.undo():
				_clear_selection()
				_refresh()
		&"remove", &"swap":
			if (action_id == &"remove" and not game.can_dig()) or (action_id == &"swap" and not game.can_swap()):
				return
			var next_mode: StringName = &"" if _mode == action_id else action_id
			_clear_selection()
			_mode = next_mode
			_update_input()
			_refresh_marks()

func _complete_settlement() -> void:
	game.settle()
	$combo.reroll_layout()
	_refresh_and_deal()

func _refresh_and_deal() -> void:
	_busy = true
	_refresh()
	$resources_display.update_values(game.deck.draw_pile.size(), game.money)
	if game.last_draw.is_empty():
		_finish_deal()
	else:
		$resources_display.set_deck_count(game.last_draw[0].remaining + 1)
		_dealer.play(game.last_draw, _views, $resources_display.deal_origin())

func _finish_deal() -> void:
	_busy = false
	$resources_display.update_values(game.deck.draw_pile.size(), game.money)
	_update_input()
	$gameplay_hud.show_outcome(game)

func _update_input() -> void:
	var active: bool = not _busy and game.status == Run.Status.PLAYING
	if (_mode == &"remove" and not game.can_dig()) or (_mode == &"swap" and not game.can_swap()):
		_mode = &""
		_swap_first = null
	var selected: Array = $hand_area.get_selected_ids()
	$board.set_camera_input_enabled(active)
	$camera_controls.set_controls_enabled(active)
	$hand_area.set_selection_enabled(active)
	var can_place: bool = active and _mode == &"" and selected.size() == 1 and game.played.size() < Rules.MAX_PLAYS
	$board.set_input_enabled(can_place, game.status == Run.Status.PLAYING)
	for cell in game.board:
		var card: Control = _views[game.board[cell]]
		card.selection_enabled = active and _mode in [&"swap", &"remove"]
		card.tooltip_text = Cards.caption(card.card_id)
		if _mode == &"remove":
			card.tooltip_text += "\n挖牌 −%d 分 · 剩餘 %d 次" % [Rules.DIG_COST, game.digs_left()]
		elif _mode == &"swap":
			card.tooltip_text += "\n交換 −%d 分 · 剩餘 %d 次" % [game.next_swap_cost(), game.swaps_left()]
	var actions := $action_buttons
	actions.get_node("done").remaining_count = game.turns_left
	actions.get_node("remove").remaining_count = game.digs_left()
	actions.get_node("swap").remaining_count = game.swaps_left()
	actions.get_node("discard").remaining_count = game.discards_left
	actions.get_node("done").disabled = not active or not game.can_settle()
	actions.get_node("remove").disabled = not active or not game.can_dig()
	actions.get_node("swap").disabled = not active or not game.can_swap()
	actions.get_node("discard").disabled = not active or not game.can_discard(selected)
	actions.get_node("undo").disabled = not active or game.history.is_empty()
	for action in [&"swap", &"remove"]:
		actions.get_node(NodePath(action)).modulate = Color("ffe28a") if _mode == action else Color.WHITE

func _on_group_hovered(cells: Array) -> void:
	if not _busy:
		$board.focus_group(cells)

func _refresh_marks() -> void:
	$board.focus_group([])
	var marks := {}
	for group in _preview.get("groups", []):
		if UI.GROUP_COLORS.has(group.kind):
			for cell in group.cells:
				if not marks.has(cell):
					marks[cell] = []
				marks[cell].append(UI.GROUP_COLORS[group.kind])
	for cell in game.board:
		_views[game.board[cell]].set_marks(marks.get(cell, []), _swap_first == cell)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _busy:
		_clear_selection()
		get_viewport().set_input_as_handled()
