extends RefCounted

# Hover 透視傾斜的目標：滑鼠所在的一側往後壓。mouse 為牌面本地座標，size 為牌面尺寸，limit 為牌緣的最大傾斜（弧度）。
# 回傳值沿用透視材質的定義：x 為正時左側靠近鏡頭，y 為正時上緣靠近鏡頭。
static func target(mouse: Vector2, size: Vector2, limit: Vector2) -> Vector2:
	var half := size / 2
	var ratio := ((mouse - half) / half).clamp(-Vector2.ONE, Vector2.ONE)
	return limit * ratio

# 以每秒 rate 的指數趨近平滑跟隨目標，結果與幀率無關。
static func follow(current: Vector2, target_tilt: Vector2, delta: float, rate: float) -> Vector2:
	return target_tilt + (current - target_tilt) * exp(-rate * delta)
