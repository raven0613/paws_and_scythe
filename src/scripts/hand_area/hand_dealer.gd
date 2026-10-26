extends Node

signal completed
signal card_emitted(remaining: int)

const Config = preload("res://src/configs/hand_area/deal_config.gd")
var _timeline: Tween
var _cards: Array[Control] = []
var _targets: Array[Vector2] = []

func play(events: Array, views: Dictionary, origin: Vector2) -> void:
	_cards.clear()
	_targets.clear()
	_timeline = create_tween().set_parallel()
	for index in events.size():
		var event: Dictionary = events[index]
		var card: Control = views[event.card]
		_cards.append(card)
		_targets.append(card.position)
		var target := card.position
		var local_origin: Vector2 = card.get_parent().get_global_transform().affine_inverse() * origin
		card.position = local_origin - card.pivot_offset
		card.scale = Vector2.ONE * Config.INITIAL_SCALE
		card.modulate.a = 0.0
		card.z_index = Config.FLIGHT_LAYER
		var delay := index * Config.CARD_INTERVAL
		_timeline.tween_callback(_emit_card.bind(card, event.remaining)).set_delay(delay)
		var grow := _timeline.tween_property(card, "scale", Vector2.ONE * Config.LAUNCH_SCALE, Config.GROW_DURATION)
		grow.set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		var flight := _timeline.tween_property(card, "position", target, Config.FLIGHT_DURATION)
		flight.set_delay(delay + Config.GROW_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		var scale_up := _timeline.tween_property(card, "scale", Vector2.ONE, Config.FLIGHT_DURATION)
		scale_up.set_delay(delay + Config.GROW_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_timeline.chain().tween_callback(_finish)

func _emit_card(card: Control, remaining: int) -> void:
	card.modulate.a = 1.0
	card_emitted.emit(remaining)

func _finish() -> void:
	for index in _cards.size():
		var card := _cards[index]
		card.position = _targets[index]
		card.scale = Vector2.ONE
		card.modulate.a = 1.0
		card.z_index = 0
	_cards.clear()
	_targets.clear()
	completed.emit()
