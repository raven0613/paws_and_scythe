extends Node

const Config = preload("res://src/configs/playing_card/card_hover_config.gd")
const Breath = preload("res://src/service/motion/breath_pulse.gd")
var _board: Control
var _enabled := false
var _hovered: Control
var _pulses: Dictionary = {}

# 以滑鼠位置比對卡牌格位，固定介面遮住的位置不觸發；縮放作用於卡牌 visual 子節點，格位與輸入維持原狀。
func setup(board: Control) -> void:
	_board = board

# 盤面可操作時才回應 Hover；停用時立即恢復原尺寸，交給牌型回饋、結算與卡牌動作接手卡面。
func set_enabled(enabled: bool) -> void:
	if _enabled == enabled:
		return
	_enabled = enabled
	if not enabled:
		for card in _pulses.keys():
			_rest(card)
		_hovered = null

# 滑鼠進入時呼吸一次，移出後播完剩餘的部分。
func _process(delta: float) -> void:
	if not _enabled:
		return
	var card: Control = _board.card_at_point(get_viewport().get_mouse_position())
	if card != _hovered:
		_hovered = card
		if card != null:
			_start(card)
	for item in _pulses.keys():
		var pulse: Dictionary = _pulses[item]
		pulse.time += delta
		if Breath.finished(pulse.time):
			_rest(item)
		else:
			_apply(item, Breath.scale(pulse.time, pulse.from))

func _start(card: Control) -> void:
	var from: float = _pulses[card].scale if _pulses.has(card) else 1.0
	_pulses[card] = {"time": 0.0, "from": from, "scale": from}
	card.group_visual().z_index = Config.BREATH_LAYER

func _apply(card: Control, scale: float) -> void:
	var visual: Node2D = card.group_visual()
	visual.scale = Vector2.ONE * scale
	visual.position = Breath.offset(scale, card.pivot_offset)
	_pulses[card].scale = scale

func _rest(card: Control) -> void:
	var visual: Node2D = card.group_visual()
	visual.scale = Vector2.ONE
	visual.position = Vector2.ZERO
	visual.z_index = 0
	_pulses.erase(card)
