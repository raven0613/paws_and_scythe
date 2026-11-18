@tool
extends Node2D

const Config = preload("res://src/configs/score/celebration_config.gd")
const Flame = preload("res://src/service/score/flame_math.gd")
const GLOW_SHADER = preload("res://src/scripts/score/celebration/flame_glow.gdshader")
var glyph := Rect2()
var energy := 0.0
var flare := 0.0
# 由彩虹組往銀河組的漸變比例。
var blend := 0.0
var _layers: Array[Array] = []
var _bloom: CanvasGroup
var _halos: Node2D
var _halo: GradientTexture2D

# 每層依兩組中較多的方塊數生成，繪製時取混合後的數量。
# 光暈在 CanvasGroup 內合成整團火焰的輪廓，模糊後以疊加混色畫在火焰後方。
func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for index in Flame.layer_count():
		var count := maxi(Config.FIRE_LAYERS_HOLOGRAPHIC[index].count, Config.FIRE_LAYERS_GALAXY[index].count)
		var particles: Array[Dictionary] = []
		for particle in count:
			particles.append(Flame.spawn(rng))
		_layers.append(particles)
	_halo = _soft_texture()
	_bloom = CanvasGroup.new()
	_bloom.show_behind_parent = true
	_bloom.visible = Config.FIRE_GLOW_ENABLED
	_bloom.material = ShaderMaterial.new()
	_bloom.material.shader = GLOW_SHADER
	add_child(_bloom)
	_halos = Node2D.new()
	_halos.draw.connect(_draw_halos)
	_bloom.add_child(_halos)

func advance(elapsed: float) -> void:
	var scaled := elapsed * Flame.speed(blend)
	for index in _layers.size():
		var layer := Flame.layer(index, blend)
		for particle in _layers[index]:
			particle.phase = Flame.advance(layer, particle, particle.phase, scaled)
	redraw()

func redraw() -> void:
	var glow := Flame.glow(blend)
	_bloom.fit_margin = glow.blur * 2.0
	_bloom.clear_margin = glow.blur * 2.0
	_bloom.material.set_shader_parameter("blur", glow.blur)
	_bloom.material.set_shader_parameter("intensity", glow.intensity)
	queue_redraw()
	_halos.queue_redraw()

# 由後往前繪製，最前方的主體蓋住後方各層；發光時方塊本身提亮。
func _draw() -> void:
	if energy <= 0.0 or not Config.FIRE_ENABLED:
		return
	var glow := Flame.glow(blend)
	for index in _layers.size():
		var layer := Flame.layer(index, blend)
		var color: Color = Flame.lit_color(layer, glow) if Config.FIRE_GLOW_ENABLED else layer.color
		for particle in _visible(index, layer):
			var block := Flame.block(layer, particle, particle.phase, glyph, energy, flare)
			draw_set_transform(block.point, block.angle)
			draw_rect(Rect2(Vector2.ONE * -block.side / 2, Vector2.ONE * block.side), color)
	draw_set_transform(Vector2.ZERO)

# 每個方塊在原位置畫一個柔邊光暈，重疊處合成同一片輪廓。
func _draw_halos() -> void:
	if energy <= 0.0 or not Config.FIRE_ENABLED:
		return
	var glow := Flame.glow(blend)
	for index in _layers.size():
		var layer := Flame.layer(index, blend)
		var color := Flame.glow_color(layer, glow)
		for particle in _visible(index, layer):
			var block := Flame.block(layer, particle, particle.phase, glyph, energy, flare)
			var side: float = block.side * glow.size
			_halos.draw_texture_rect(_halo, Rect2(block.point - Vector2.ONE * side / 2, Vector2.ONE * side), false, color)

func _visible(index: int, layer: Dictionary) -> Array:
	return _layers[index].slice(0, roundi(layer.count))

func _soft_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	texture.width = Config.FIRE_GLOW_RESOLUTION
	texture.height = Config.FIRE_GLOW_RESOLUTION
	return texture
