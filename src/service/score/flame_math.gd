extends RefCounted

const Config = preload("res://src/configs/score/celebration_config.gd")

# 方塊的隨機特徵以 0～1 的取值保存，套用到當下混合後的層設定，兩組火焰漸變時各方塊連續過渡。
static func spawn(rng: RandomNumberGenerator) -> Dictionary:
	return {
		"x": rng.randf_range(-0.5, 0.5),
		"phase": rng.randf(),
		"life": rng.randf(),
		"size": rng.randf(),
		"drift": rng.randf_range(-1.0, 1.0),
		"angle": rng.randf_range(Config.FIRE_INITIAL_ANGLE.x, Config.FIRE_INITIAL_ANGLE.y),
		"spin": rng.randf(),
		"turn": 1.0 if rng.randf() < 0.5 else -1.0,
	}

static func layer_count() -> int:
	return Config.FIRE_LAYERS_HOLOGRAPHIC.size()

# 第 index 層由彩虹組往銀河組混合 blend 比例後的設定。
static func layer(index: int, blend: float) -> Dictionary:
	var from: Dictionary = Config.FIRE_LAYERS_HOLOGRAPHIC[index]
	var to: Dictionary = Config.FIRE_LAYERS_GALAXY[index]
	var result := {}
	for key in from:
		result[key] = lerp(from[key], to[key], blend)
	return result

# 火焰光暈由彩虹組往銀河組混合 blend 比例後的設定。
static func glow(blend: float) -> Dictionary:
	var result := {}
	for key in Config.FIRE_GLOW_HOLOGRAPHIC:
		result[key] = lerpf(Config.FIRE_GLOW_HOLOGRAPHIC[key], Config.FIRE_GLOW_GALAXY[key], blend)
	return result

# 光暈顏色：該層火焰色往白色提亮。
static func glow_color(layer: Dictionary, glow: Dictionary) -> Color:
	return layer.color.lerp(Color.WHITE, glow.lighten)

# 發光時火焰方塊本身的提亮顏色。
static func lit_color(layer: Dictionary, glow: Dictionary) -> Color:
	return layer.color.lerp(Color.WHITE, glow.brighten)

static func speed(blend: float) -> float:
	return lerpf(Config.FIRE_SPEED_HOLOGRAPHIC, Config.FIRE_SPEED_GALAXY, blend)

static func lifetime(layer: Dictionary, particle: Dictionary) -> float:
	return lerpf(layer.lifetime.x, layer.lifetime.y, particle.life)

# 壽命進度依經過時間累加，速度與壽命改變時進度保持連續。
static func advance(layer: Dictionary, particle: Dictionary, phase: float, elapsed: float) -> float:
	return fposmod(phase + elapsed / lifetime(layer, particle), 1.0)

# glyph 為數字字形範圍：高度以字底到字頂為一個字高，寬度為整串數字。
# 高分漸強以字底為基準等比例縮放整團火焰，各層維持相對位置並互相銜接；撞擊噴發拉高各層頂端。
# 漸強與噴發同時放大方塊。
static func block(layer: Dictionary, particle: Dictionary, p: float, glyph: Rect2, energy: float, flare: float) -> Dictionary:
	var climb := pow(p, layer.acceleration)
	var start: float = layer.bottom * energy
	var finish: float = layer.top * energy * (1.0 + Config.FLARE_RISE * flare)
	var height := lerpf(start, finish, climb)
	var growth := energy * (1.0 + Config.FLARE_SIZE * flare)
	var life := smoothstep(0.0, Config.FIRE_EMERGE, p) * (1.0 - smoothstep(1.0 - Config.FIRE_FADE, 1.0, p))
	var side: float = lerpf(layer.size.x, layer.size.y, particle.size)
	var spin: float = lerpf(layer.spin.x, layer.spin.y, particle.spin) * particle.turn
	return {
		"point": Vector2(glyph.get_center().x + particle.x * layer.width * glyph.size.x + layer.spread * particle.drift * climb,
			glyph.end.y - height * glyph.size.y),
		"side": side * growth * lerpf(1.0, layer.shrink, p) * life,
		"angle": particle.angle + spin * lifetime(layer, particle) * p,
	}
