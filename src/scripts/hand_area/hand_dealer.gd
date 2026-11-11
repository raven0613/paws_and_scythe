extends Node

signal completed
signal card_emitted(remaining: int)

const Config = preload("res://src/configs/hand_area/deal_config.gd")
const FlightConfig = preload("res://src/configs/playing_card/flight_animation_config.gd")
const Flight = preload("res://src/scripts/playing_card/flight/card_flight.gd")
const Math = preload("res://src/service/playing_card/flight_math.gd")
var _timeline: Tween
var _cards: Array[Control] = []
var _targets: Array[Vector2] = []
var _flights: Array[RefCounted] = []

func play(events: Array, views: Dictionary, origin: Vector2) -> void:
	_cards.clear()
	_targets.clear()
	_flights.clear()
	_timeline = create_tween().set_parallel()
	for index in events.size():
		var event: Dictionary = events[index]
		var card: Control = views[event.card]
		_cards.append(card)
		_targets.append(card.position)
		var target := card.position
		var parent_transform: Transform2D = card.get_parent().get_global_transform_with_canvas()
		var local_origin: Vector2 = parent_transform.affine_inverse() * origin - card.pivot_offset
		card.position = local_origin
		card.scale = Vector2.ONE * Config.INITIAL_SCALE
		card.modulate.a = 0.0
		card.z_index = Config.FLIGHT_LAYER
		var flight := Flight.new(card, parent_transform * (target + card.pivot_offset), FlightConfig.DRAW_ENABLED)
		_flights.append(flight)
		var delay := index * Config.CARD_INTERVAL
		_timeline.tween_callback(_emit_card.bind(card, event.remaining)).set_delay(delay)
		var grow := _timeline.tween_property(card, "scale", Vector2.ONE * Config.LAUNCH_SCALE, Config.GROW_DURATION)
		grow.set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		var travel := _timeline.tween_method(_fly.bind(card, local_origin, target, flight), 0.0, 1.0, Config.FLIGHT_DURATION)
		travel.set_delay(delay + Config.GROW_DURATION)
		flight.land(_timeline, delay + Config.GROW_DURATION + Config.FLIGHT_DURATION)
	_timeline.chain().tween_callback(_finish)

func _fly(progress: float, card: Control, origin: Vector2, target: Vector2, flight: RefCounted) -> void:
	var travel := Math.spring(progress)
	card.position = origin.lerp(target, travel)
	card.scale = Vector2.ONE * lerpf(Config.LAUNCH_SCALE, 1.0, travel)
	flight.update(progress)

func _emit_card(card: Control, remaining: int) -> void:
	card.modulate.a = 1.0
	card_emitted.emit(remaining)

func _finish() -> void:
	for index in _cards.size():
		var card := _cards[index]
		_flights[index].finish()
		card.position = _targets[index]
		card.scale = Vector2.ONE
		card.modulate.a = 1.0
		card.z_index = 0
	_cards.clear()
	_targets.clear()
	_flights.clear()
	completed.emit()
