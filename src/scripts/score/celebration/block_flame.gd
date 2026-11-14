@tool
extends Node2D

const Config = preload("res://src/configs/score/celebration_config.gd")
const Flame = preload("res://src/service/score/flame_math.gd")
var glyph := Rect2()
var energy := 0.0
var flare := 0.0
var clock_time := 0.0
var _layers: Array[Array] = []

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for layer in Config.FIRE_LAYERS:
		var particles: Array[Dictionary] = []
		for index in layer.count:
			particles.append(Flame.spawn(layer, rng))
		_layers.append(particles)

# 依 FIRE_LAYERS 順序由後往前繪製，最前方的深橘主體蓋住後方各層。
func _draw() -> void:
	if energy <= 0.0 or not Config.FIRE_ENABLED:
		return
	for index in Config.FIRE_LAYERS.size():
		var layer: Dictionary = Config.FIRE_LAYERS[index]
		for particle in _layers[index]:
			var block := Flame.block(layer, particle, Flame.progress(particle, clock_time), glyph, energy, flare)
			draw_set_transform(block.point, block.angle)
			draw_rect(Rect2(Vector2.ONE * -block.side / 2, Vector2.ONE * block.side), layer.color)
	draw_set_transform(Vector2.ZERO)
