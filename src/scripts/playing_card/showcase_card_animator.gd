extends Node

const Config = preload("res://src/configs/score/showcase_config.gd")
const Motion = preload("res://src/service/score/showcase_motion.gd")
var _tracks: Array[Dictionary] = []
var _tween: Tween
var _speed := 1.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func set_playback_speed(value: float) -> void:
	_speed = value
	if _tween and _tween.is_running():
		_tween.set_speed_scale(value)

# groups 依亮相順序列出各組沿路徑排列的卡片；各組相隔 ROW_INTERVAL 開始，同一張牌由後一組從當下姿態接手。
func play(groups: Array) -> void:
	reset()
	var tracks := {}
	var entries: Array = []
	for order in groups.size():
		var cards: Array = groups[order]
		for index in cards.size():
			var card: Control = cards[index]
			if not tracks.has(card):
				var visual: Node2D = card.group_visual()
				tracks[card] = {"card": card, "visual": visual, "home": visual.position, "layer": card.z_index, "entries": []}
			var item := Motion.entry(order, index, cards.size(), _rng.randf_range(-1.0, 1.0))
			tracks[card].entries.append(item)
			entries.append(item)
	_tracks.assign(tracks.values())
	var duration := Motion.duration(entries)
	_tween = create_tween().set_speed_scale(_speed)
	_tween.tween_method(_progress, 0.0, duration, duration)
	_tween.tween_callback(reset)

# 卡片以自身中心旋轉，再沿旋轉後的上方位移；浮起期間的圖層依所屬組的亮相順序遞增。
func _progress(time: float) -> void:
	for track in _tracks:
		var pose := Motion.pose(track.entries, time)
		var pivot: Vector2 = track.card.pivot_offset
		var home: Vector2 = track.home
		var order := Motion.layer_order(track.entries, time)
		track.visual.rotation = pose.rotation
		track.visual.position = home + pose.offset + pivot - pivot.rotated(pose.rotation)
		track.card.z_index = track.layer if order < 0 else Config.CARD_LAYER + order

func reset() -> void:
	if _tween:
		_tween.kill()
	for track in _tracks:
		track.visual.position = track.home
		track.visual.rotation = 0.0
		track.card.z_index = track.layer
	_tracks.clear()
