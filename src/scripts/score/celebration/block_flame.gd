@tool
extends Node2D

const Config = preload("res://src/configs/score/celebration_config.gd")
const Flame = preload("res://src/service/score/flame_math.gd")
var glyph := Rect2()
var energy := 0.0
var flare := 0.0
# 由彩虹組往銀河組的漸變比例。
var blend := 0.0
var _layers: Array[Array] = []

# 每層依兩組中較多的方塊數生成，繪製時取混合後的數量。
func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for index in Flame.layer_count():
		var count := maxi(Config.FIRE_LAYERS_HOLOGRAPHIC[index].count, Config.FIRE_LAYERS_GALAXY[index].count)
		var particles: Array[Dictionary] = []
		for particle in count:
			particles.append(Flame.spawn(rng))
		_layers.append(particles)

func advance(elapsed: float) -> void:
	var scaled := elapsed * Flame.speed(blend)
	for index in _layers.size():
		var layer := Flame.layer(index, blend)
		for particle in _layers[index]:
			particle.phase = Flame.advance(layer, particle, particle.phase, scaled)
	queue_redraw()

# 由後往前繪製，最前方的主體蓋住後方各層。
func _draw() -> void:
	if energy <= 0.0 or not Config.FIRE_ENABLED:
		return
	for index in _layers.size():
		var layer := Flame.layer(index, blend)
		var particles: Array = _layers[index].slice(0, roundi(layer.count))
		for particle in particles:
			var block := Flame.block(layer, particle, particle.phase, glyph, energy, flare)
			draw_set_transform(block.point, block.angle)
			draw_rect(Rect2(Vector2.ONE * -block.side / 2, Vector2.ONE * block.side), layer.color)
	draw_set_transform(Vector2.ZERO)
