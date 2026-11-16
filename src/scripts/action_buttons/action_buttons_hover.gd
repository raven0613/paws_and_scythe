extends Node

const Config = preload("res://src/configs/action_buttons/action_button_motion_config.gd")
const Displacement = preload("res://src/scripts/motion/displacement.gd")
const Math = preload("res://src/service/motion/displacement_math.gd")
const HoverPop = preload("res://src/scripts/motion/hover_pop.gd")
var _buttons: Array[Control] = []
var _hovered: Control
var _gap_center := -1
var _tweens: Dictionary = {}
var _spacing_tween: Tween

# 按鈕根節點固定在排列中負責輸入，spacing 承接推開，visual 承接放大與抖動，邊界判定因此保持穩定。
func setup(buttons: Array[Control]) -> void:
	_buttons = buttons

func _process(_delta: float) -> void:
	var button := _hovered_button()
	if button != _hovered:
		_set_focus(button)

# 停用的按鈕不回應 Hover，仍會被鄰近按鈕推開。
func _hovered_button() -> Control:
	var control := get_viewport().gui_get_hovered_control()
	if control == null:
		return null
	for button in _buttons:
		if not button.disabled and (control == button or button.is_ancestor_of(control)):
			return button
	return null

func _set_focus(button: Control) -> void:
	if _hovered != null:
		_stop_tween(_hovered)
		_tweens[_hovered] = HoverPop.release(self, _hovered.hover_visual(), Config.HOVER_PROFILE)
		_hovered.slosh(-Config.SLOSH_RELEASE_KICK)
	_hovered = button
	if button != null:
		_stop_tween(button)
		_tweens[button] = HoverPop.enter(self, button.hover_visual(), Config.HOVER_PROFILE)
		button.slosh(Config.SLOSH_ENTER_KICK)
		_open_gap(button)
	else:
		_close_gap()

# 左右按鈕依放大後的寬度讓出間隙，範圍內的按鈕接續擾動，水面在擾動開始時順著推開方向甩一下。
func _open_gap(selected: Control) -> void:
	if _spacing_tween:
		_spacing_tween.kill()
	_spacing_tween = create_tween().set_parallel()
	_gap_center = _buttons.find(selected)
	var center := selected.position + selected.size / 2
	var half_width := selected.size.x * Config.HOVER_SCALE / 2
	var left := 0.0
	var right := 0.0
	if _gap_center > 0:
		var neighbor := _buttons[_gap_center - 1]
		left = maxf(0.0, neighbor.position.x + neighbor.size.x + Config.HOVER_GAP - (center.x - half_width))
	if _gap_center + 1 < _buttons.size():
		right = maxf(0.0, center.x + half_width + Config.HOVER_GAP - _buttons[_gap_center + 1].position.x)
	var motions: Array[Dictionary] = []
	for index in _buttons.size():
		var spacing: Control = _buttons[index].spacing_visual()
		if index == _gap_center:
			_spacing_tween.tween_property(spacing, "position", Vector2.ZERO, Config.HOVER_SCALE_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			_spacing_tween.tween_property(spacing, "rotation", 0.0, Config.HOVER_SCALE_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			continue
		var side := signf(index - _gap_center)
		motions.append({"node": spacing, "origin": spacing.position, "target": Vector2(right if side > 0 else -left, 0.0),
			"rotation": spacing.rotation, "direction": Vector2(side, 0.0), "index": index})
	var cues := Displacement.append(_spacing_tween, motions, _gap_center, Config.HOVER_DISTURB_COUNT, Config.DISTURB_PROFILE)
	_append_neighbor_slosh(cues, 1.0)

# 收回間距時鄰居朝反方向回位，水面再甩一下。
func _close_gap() -> void:
	if _spacing_tween:
		_spacing_tween.kill()
	_spacing_tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for button in _buttons:
		var spacing: Control = button.spacing_visual()
		_spacing_tween.tween_property(spacing, "position", Vector2.ZERO, Config.HOVER_RELEASE_DURATION)
		_spacing_tween.tween_property(spacing, "rotation", 0.0, Config.HOVER_RELEASE_DURATION)
	var indices: Array[int] = []
	indices.assign(range(_buttons.size()))
	_append_neighbor_slosh(Math.plan(indices, _gap_center, Config.HOVER_DISTURB_COUNT, Config.DISTURB_PROFILE), -1.0)

func _append_neighbor_slosh(cues: Dictionary, outward: float) -> void:
	for index in cues:
		var cue: Dictionary = cues[index]
		if cue.strength > 0.0:
			var impulse: float = outward * signf(index - _gap_center) * Config.SLOSH_NEIGHBOR_KICK * cue.strength
			_spacing_tween.tween_callback(_buttons[index].slosh.bind(impulse)).set_delay(cue.delay)

func _stop_tween(button: Control) -> void:
	if _tweens.has(button):
		_tweens[button].kill()
		_tweens.erase(button)
