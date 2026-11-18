extends RefCounted

const Config = preload("res://src/configs/score/impact_distortion_config.gd")

# 衝擊波發出後 since 秒的扭曲環：radius、width 以畫面半高為 1，strength 與 aberration 為像素；
# 尚未發出（since 為負）與擴散結束後強度為 0。
static func shockwave(tier: int, since: float) -> Dictionary:
	var wave: Dictionary = Config.SHOCKWAVE[tier]
	if since < 0.0:
		return {"radius": 0.0, "width": wave.width, "strength": 0.0, "aberration": 0.0}
	var progress := clampf(since / wave.duration, 0.0, 1.0)
	var spread := 1.0 - pow(1.0 - progress, 2.0)
	var fade := 1.0 - progress
	return {
		"radius": wave.radius * spread,
		"width": wave.width * lerpf(0.6, 1.0, spread),
		"strength": wave.strength * fade,
		"aberration": wave.aberration * fade,
	}

# 熱浪設定：跑分時為 HEAT_HAZE_COUNT，強度乘上火焰漸強 energy；衝擊波發出後 since 秒內，
# 在衝擊波擴散期間由跑分設定過渡到該等級的 HEAT_HAZE。
static func haze(tier: int, energy: float, since: float) -> Dictionary:
	var calm: Dictionary = Config.HEAT_HAZE_COUNT
	var peak: Dictionary = Config.HEAT_HAZE[tier]
	var ramp := smoothstep(0.0, Config.SHOCKWAVE[tier].duration, since) if since >= 0.0 else 0.0
	var result := {}
	for key in calm:
		result[key] = lerp(calm[key], peak[key], ramp)
	result.strength = lerpf(calm.strength * energy, peak.strength, ramp)
	return result

# 熱浪橢圓在數字視覺層的中心與半徑；glyph 為數字字形範圍。
static func haze_region(settings: Dictionary, glyph: Rect2) -> Dictionary:
	return {
		"center": Vector2(glyph.get_center().x, glyph.end.y - glyph.size.y * settings.lift),
		"radius": Vector2(glyph.size.x / 2, glyph.size.y) * settings.size,
	}
