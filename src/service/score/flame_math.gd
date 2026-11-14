extends RefCounted

const Config = preload("res://src/configs/score/celebration_config.gd")

static func spawn(layer: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	return {
		"x": rng.randf_range(-0.5, 0.5),
		"phase": rng.randf(),
		"life": rng.randf_range(layer.lifetime.x, layer.lifetime.y),
		"size": rng.randf_range(layer.size.x, layer.size.y),
		"drift": rng.randf_range(-layer.spread, layer.spread),
		"angle": rng.randf_range(Config.FIRE_INITIAL_ANGLE.x, Config.FIRE_INITIAL_ANGLE.y),
		"spin": rng.randf_range(layer.spin.x, layer.spin.y) * (1.0 if rng.randf() < 0.5 else -1.0),
	}

static func progress(particle: Dictionary, clock: float) -> float:
	return fposmod(clock / particle.life + particle.phase, 1.0)

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
	return {
		"point": Vector2(glyph.get_center().x + particle.x * layer.width * glyph.size.x + particle.drift * climb,
			glyph.end.y - height * glyph.size.y),
		"side": particle.size * growth * lerpf(1.0, layer.shrink, p) * life,
		"angle": particle.angle + particle.spin * particle.life * p,
	}
