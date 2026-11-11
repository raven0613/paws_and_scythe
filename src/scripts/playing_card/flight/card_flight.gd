extends RefCounted

const Config = preload("res://src/configs/playing_card/flight_animation_config.gd")
const Math = preload("res://src/service/playing_card/flight_math.gd")
const CornerShader = preload("res://src/scripts/playing_card/flight/front_corner.gdshader")

var _card: Control
var _material: ShaderMaterial
var _direction: Vector2
var _amount: float
var _original_materials: Dictionary = {}

func _init(card: Control, destination: Vector2, enabled: bool) -> void:
	_card = card
	if not enabled:
		return
	var origin := card.get_global_transform_with_canvas() * card.pivot_offset
	_direction = destination - origin
	var distance := Math.reference_delta(_direction, card.get_viewport_rect().size).length()
	_amount = Math.stretch_ratio(distance) * minf(card.size.x, card.size.y)
	_material = ShaderMaterial.new()
	_material.shader = CornerShader
	_material.set_shader_parameter("card_size", card.size)
	var direction := Math.local_direction(_direction, card.get_global_transform_with_canvas())
	_material.set_shader_parameter("front_corner", Math.front_corner(direction))
	_attach(card.group_visual())
	apply(0.0)

func update(progress: float) -> void:
	apply(Math.stretch_envelope(progress))

func land(timeline: Tween, delay := 0.0) -> void:
	if not _material:
		return
	var recoil := timeline.tween_method(apply, Config.ARRIVAL_STRETCH, -Config.RECOIL_RATIO, Config.RECOIL_DURATION)
	recoil.set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var recover := timeline.tween_method(apply, -Config.RECOIL_RATIO, 0.0, Config.RECOVER_DURATION)
	recover.set_delay(delay + Config.RECOIL_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func apply(amount: float) -> void:
	if not _material:
		return
	var world := _card.get_global_transform()
	var canvas := _card.get_global_transform_with_canvas()
	var direction := Math.local_direction(_direction, canvas)
	_material.set_shader_parameter("card_origin", world.origin)
	_material.set_shader_parameter("card_x", world.x)
	_material.set_shader_parameter("card_y", world.y)
	_material.set_shader_parameter("pull", direction * _amount * amount)

func finish() -> void:
	for item in _original_materials:
		item.material = _original_materials[item]
	_original_materials.clear()
	_material = null

func _attach(node: Node) -> void:
	if node is CanvasItem:
		_original_materials[node] = node.material
		node.material = _material
	for child in node.get_children():
		_attach(child)
