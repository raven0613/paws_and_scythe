extends Node

const Config = preload("res://src/configs/playing_card/group_animation_config.gd")
var _poses: Array[Dictionary] = []
var _peak_time := 0.0

# 回傳時最後一張剛到最高點，排程在這一刻啟動 combo 冒出。
func lift(cards: Array[Control]) -> void:
	_poses.clear()
	for card in cards:
		var visual: Node2D = card.group_visual()
		_poses.append({"card": card, "visual": visual, "home": visual.position, "layer": card.z_index})
		card.z_index = Config.LAYER
	_peak_time = (cards.size() - 1) * Config.CARD_INTERVAL + Config.LIFT_DURATION
	var timeline := create_tween()
	timeline.tween_method(_wave_progress, 0.0, _peak_time, _peak_time)
	await timeline.finished

func settle() -> void:
	var timeline := create_tween()
	timeline.tween_method(_wave_progress, _peak_time, _peak_time + Config.REBOUND_DURATION, Config.REBOUND_DURATION)
	timeline.tween_interval(Config.HOLD_DURATION)
	timeline.tween_method(_return_progress, 0.0, 1.0, Config.RETURN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await timeline.finished
	for pose in _poses:
		pose.visual.position = pose.home
		pose.card.z_index = pose.layer
	_poses.clear()

func _wave_progress(time: float) -> void:
	for index in _poses.size():
		var local_time := maxf(0.0, time - index * Config.CARD_INTERVAL)
		var height: float
		if local_time <= Config.LIFT_DURATION:
			var rise: float = Tween.interpolate_value(0.0, 1.0, local_time, Config.LIFT_DURATION, Tween.TRANS_CUBIC, Tween.EASE_OUT)
			height = Config.LIFT_HEIGHT * rise
		else:
			var rebound: float = Tween.interpolate_value(0.0, 1.0, minf(local_time - Config.LIFT_DURATION, Config.REBOUND_DURATION), Config.REBOUND_DURATION, Tween.TRANS_BACK, Tween.EASE_OUT)
			height = Config.LIFT_HEIGHT - Config.REBOUND_DISTANCE * rebound
		var pose := _poses[index]
		pose.visual.position = pose.home + Vector2.UP * height

func _return_progress(progress: float) -> void:
	var height := (Config.LIFT_HEIGHT - Config.REBOUND_DISTANCE) * (1.0 - progress)
	for pose in _poses:
		pose.visual.position = pose.home + Vector2.UP * height
