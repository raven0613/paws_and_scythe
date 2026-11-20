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

# 每層依兩組中較多的方塊數生成，繪製時取混合後的數量。
# 外暈在 CanvasGroup 內合成整團火焰的輪廓與顏色，由邊緣往外淡出後畫在火焰後方。
func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for index in Flame.layer_count():
		var count := maxi(Config.FIRE_LAYERS_HOLOGRAPHIC[index].count, Config.FIRE_LAYERS_GALAXY[index].count)
		var particles: Array[Dictionary] = []
		for particle in count:
			particles.append(Flame.spawn(rng))
		_layers.append(particles)
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

# 外暈淡出距離以基準畫面像素設定，換算成螢幕像素交給 shader，任何視窗大小的光暈寬度一致。
func redraw() -> void:
	var glow := Flame.glow(blend)
	_bloom.fit_margin = glow.blur
	_bloom.clear_margin = glow.blur
	_bloom.material.set_shader_parameter("blur", glow.blur * get_screen_transform().get_scale().x)
	_bloom.material.set_shader_parameter("halo_alpha", glow.halo_alpha)
	queue_redraw()
	_halos.queue_redraw()

# 由後往前繪製，最前方的主體蓋住後方各層；發光時方塊本身提高亮度。
func _draw() -> void:
	_paint(self, Config.FIRE_GLOW_ENABLED)

# 外暈輪廓與發光的火焰相同，重疊處合成整團火焰的外形，各處保留該層的顏色。
func _draw_halos() -> void:
	_paint(_halos, true)

func _paint(canvas: CanvasItem, lit: bool) -> void:
	if energy <= 0.0 or not Config.FIRE_ENABLED:
		return
	var glow := Flame.glow(blend)
	for index in _layers.size():
		var layer := Flame.layer(index, blend)
		var color: Color = Flame.lit_color(layer, glow) if lit else layer.color
		for particle in _visible(index, layer):
			var block := Flame.block(layer, particle, particle.phase, glyph, energy, flare)
			canvas.draw_set_transform(block.point, block.angle)
			canvas.draw_rect(Rect2(Vector2.ONE * -block.side / 2, Vector2.ONE * block.side), color)
	canvas.draw_set_transform(Vector2.ZERO)

func _visible(index: int, layer: Dictionary) -> Array:
	return _layers[index].slice(0, roundi(layer.count))
