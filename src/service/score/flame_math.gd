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

# 火焰發光由彩虹組往銀河組混合 blend 比例後的設定。
static func glow(blend: float) -> Dictionary:
	var result := {}
	for key in Config.FIRE_GLOW_HOLOGRAPHIC:
		result[key] = lerpf(Config.FIRE_GLOW_HOLOGRAPHIC[key], Config.FIRE_GLOW_GALAXY[key], blend)
	return result

# 發光時火焰方塊本身的顏色：該層火焰色維持色相與飽和度，亮度往最亮推 brighten 的比例，像由內而外發光。
static func lit_color(layer: Dictionary, glow: Dictionary) -> Color:
	var color: Color = layer.color
	return Color.from_hsv(color.h, color.s, lerpf(color.v, 1.0, glow.brighten))

static func speed(blend: float) -> float:
	return lerpf(Config.FIRE_SPEED_HOLOGRAPHIC, Config.FIRE_SPEED_GALAXY, blend)

static func lifetime(layer: Dictionary, particle: Dictionary) -> float:
	return lerpf(layer.lifetime.x, layer.lifetime.y, particle.life)

# 壽命進度依經過時間累加，速度與壽命改變時進度保持連續。
static func advance(layer: Dictionary, particle: Dictionary, phase: float, elapsed: float) -> float:
	return fposmod(phase + elapsed / lifetime(layer, particle), 1.0)

# 漸強時整團火焰的縮放比例：開始漸強即以 FIRE_MIN_SCALE 燃起，隨能量長到完整尺寸；能量為零時為零。
static func scale(energy: float) -> float:
	return lerpf(Config.FIRE_MIN_SCALE, 1.0, energy) if energy > 0.0 else 0.0

# glyph 為數字字形範圍：高度以字底到字頂為一個字高，寬度為整串數字。
# 高分漸強以字底中央為基準等比例縮放整團火焰，寬度、高度、橫向散開與方塊大小一起縮放，各層維持滿能量時的形狀與相對位置並互相銜接；
# 撞擊噴發拉高各層頂端並放大方塊。
static func block(layer: Dictionary, particle: Dictionary, p: float, glyph: Rect2, energy: float, flare: float) -> Dictionary:
	var climb := pow(p, layer.acceleration)
	var size := scale(energy)
	var start: float = layer.bottom * size
	var finish: float = layer.top * size * (1.0 + Config.FLARE_RISE * flare)
	var height := lerpf(start, finish, climb)
	var growth := size * (1.0 + Config.FLARE_SIZE * flare)
	var life := smoothstep(0.0, Config.FIRE_EMERGE, p) * (1.0 - smoothstep(1.0 - Config.FIRE_FADE, 1.0, p))
	var side: float = lerpf(layer.size.x, layer.size.y, particle.size)
	var spin: float = lerpf(layer.spin.x, layer.spin.y, particle.spin) * particle.turn
	return {
		"point": Vector2(glyph.get_center().x + (particle.x * layer.width * glyph.size.x + layer.spread * particle.drift * climb) * size,
			glyph.end.y - height * glyph.size.y),
		"side": side * growth * lerpf(1.0, layer.shrink, p) * life,
		"angle": particle.angle + spin * lifetime(layer, particle) * p,
	}
