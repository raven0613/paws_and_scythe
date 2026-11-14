extends RefCounted

const Config = preload("res://src/configs/score/celebration_config.gd")
const CONTACT_COUNT = 2
const TOP = -1.0
const BOTTOM = 1.0

# 動作結束後保留撞擊特效完整淡出的時間。
static func duration() -> float:
	var settle := landing_time(Config.BOUNCE_COUNT) + Config.LANDING_SHAKE_DURATION
	var effects := maxf(Config.FLASH_DURATION, maxf(Config.FLARE_DURATION, Config.QUAKE_DURATION))
	return maxf(settle, contact_time(1) + effects)

# 第 0 次撞擊為天花板，第 1 次為地板第一個角著地。
static func contact_time(index: int) -> float:
	var ceiling := Config.LAUNCH_DURATION
	return ceiling if index == 0 else ceiling + Config.CEILING_HOLD + Config.FALL_DURATION

static func contacts(progress: float) -> int:
	var time := progress * duration()
	var count := 0
	for index in CONTACT_COUNT:
		if time >= contact_time(index):
			count += 1
	return count

static func impact(index: int) -> Dictionary:
	if index == 0:
		return {"shake": Config.CEILING_SHAKE, "quake": Config.CEILING_QUAKE, "flash": Config.CEILING_FLASH, "flare": Config.CEILING_FLARE}
	return {"shake": Config.FLOOR_SHAKE, "quake": Config.FLOOR_QUAKE, "flash": Config.FLOOR_FLASH, "flare": Config.FLOOR_FLARE}

# 第 0 次著地為第一個角，之後每次彈起後著地一次，最後一次兩腳同時著地。
static func landing_time(index: int) -> float:
	if index == 0:
		return contact_time(1)
	var time := contact_time(1) + Config.FLOOR_HOLD
	for bounce in index:
		time += Config.BOUNCE_DURATION * pow(Config.BOUNCE_DECAY, bounce)
	return time

static func landing_tilt(index: int) -> float:
	return 0.0 if index >= Config.BOUNCE_COUNT else Config.FLOOR_TILT * pow(-Config.BOUNCE_DECAY, index)

# 碎片噴出點以靜止中心為原點：撞頂由上緣兩端向外，落地由著地的角向上。
static func emitters(index: int, size: Vector2) -> Array:
	var pose := _motion(contact_time(index), size)
	var ceiling := index == 0
	var points := [
		_emitter(pose, size, Vector2(-0.5, -0.5), Vector2.LEFT.rotated(-Config.CEILING_DEBRIS_DROP)),
		_emitter(pose, size, Vector2(0.5, -0.5), Vector2.RIGHT.rotated(Config.CEILING_DEBRIS_DROP)),
	] if ceiling else [_emitter(pose, size, Vector2(signf(Config.FLOOR_TILT) * 0.5, 0.5), Vector2.UP)]
	var shared := {
		"count": roundi(float(Config.CEILING_DEBRIS_COUNT if ceiling else Config.FLOOR_DEBRIS_COUNT) / points.size()),
		"speed": Config.CEILING_DEBRIS_SPEED if ceiling else Config.FLOOR_DEBRIS_SPEED,
		"spread": Config.CEILING_DEBRIS_SPREAD if ceiling else Config.FLOOR_DEBRIS_SPREAD,
		"front": ceiling,
	}
	return points.map(func(point: Dictionary) -> Dictionary: return point.merged(shared))

# 已發生的撞擊各自淡出並疊加成閃白、火焰噴發與畫面震動。
static func pose(progress: float, size: Vector2) -> Dictionary:
	var time := progress * duration()
	var result := _motion(time, size)
	var flash := 0.0
	var flare := 0.0
	var quake := Vector2.ZERO
	for index in contacts(progress):
		var since := time - contact_time(index)
		var strength := impact(index)
		flash += strength.flash * fade(since, Config.FLASH_DURATION)
		flare += strength.flare * fade(since, Config.FLARE_DURATION)
		quake += strength.quake * vibration(since, Config.QUAKE_DURATION, Config.QUAKE_FREQUENCY)
	result.flash = minf(flash, 1.0)
	result.flare = flare
	result.quake = quake
	return result

# 起始速度為 start_speed、結束速度為 2 - start_speed 的等加速度位移。
static func travel(progress: float, start_speed: float) -> float:
	return start_speed * progress + (1.0 - start_speed) * progress * progress

static func fade(since: float, length: float) -> float:
	if since < 0.0 or since >= length:
		return 0.0
	return pow(1.0 - since / length, Config.COLLISION_FALLOFF)

static func vibration(since: float, length: float, frequency: Vector2) -> Vector2:
	return Vector2(sin(TAU * frequency.x * since), sin(TAU * frequency.y * since)) * fade(since, length)

# 天花板位於衝到頂時放大且傾斜的最高角，撞頂期間該角固定不動。
static func _motion(time: float, size: Vector2) -> Dictionary:
	var launched := -Config.CEILING_HEIGHT
	var ceiling := launched + _corner(TOP, size, Config.LAUNCH_SCALE, Config.CEILING_TILT).y
	var ground := size.y / 2
	if time < Config.LAUNCH_DURATION:
		var p := time / Config.LAUNCH_DURATION
		return _pose(Vector2(0.0, launched * travel(p, Config.LAUNCH_SPEED)),
			Vector2.ONE.lerp(Config.LAUNCH_SCALE, p), Config.CEILING_TILT * p)
	time -= Config.LAUNCH_DURATION
	if time < Config.CEILING_HOLD:
		var hit := Config.LAUNCH_SCALE * Config.CEILING_SQUASH
		var scale := hit.lerp(Config.LAUNCH_SCALE, smoothstep(0.0, 1.0, time / Config.CEILING_HOLD))
		var shake := Config.CEILING_SHAKE * vibration(time, Config.CEILING_HOLD, Config.COLLISION_SHAKE_FREQUENCY)
		return _pose(Vector2(0.0, _resting(ceiling, TOP, size, scale, Config.CEILING_TILT)) + shake, scale, Config.CEILING_TILT)
	time -= Config.CEILING_HOLD
	if time < Config.FALL_DURATION:
		var p := time / Config.FALL_DURATION
		var landed := _resting(ground, BOTTOM, size, Config.FALL_STRETCH, Config.FLOOR_TILT)
		return _pose(Vector2(0.0, lerpf(launched, landed, travel(p, Config.REBOUND_SPEED))),
			Config.LAUNCH_SCALE.lerp(Config.FALL_STRETCH, p), lerpf(Config.CEILING_TILT, Config.FLOOR_TILT, p))
	time -= Config.FALL_DURATION
	if time < Config.FLOOR_HOLD:
		var scale := Config.FLOOR_SQUASH.lerp(Vector2.ONE, smoothstep(0.0, 1.0, time / Config.FLOOR_HOLD))
		var shake := Config.FLOOR_SHAKE * vibration(time, Config.FLOOR_HOLD, Config.COLLISION_SHAKE_FREQUENCY)
		return _pose(Vector2(0.0, _resting(ground, BOTTOM, size, scale, Config.FLOOR_TILT)) + shake, scale, Config.FLOOR_TILT)
	return _rock(time - Config.FLOOR_HOLD, size)

# 每次彈起時在空中轉向另一側，落下時由新的最低角著地。
static func _rock(time: float, size: Vector2) -> Dictionary:
	for bounce in Config.BOUNCE_COUNT:
		var length := Config.BOUNCE_DURATION * pow(Config.BOUNCE_DECAY, bounce)
		if time < length:
			var p := time / length
			var tilt := lerpf(landing_tilt(bounce), landing_tilt(bounce + 1), p)
			var hop := Config.BOUNCE_HEIGHT * pow(Config.BOUNCE_DECAY, bounce) * 4.0 * p * (1.0 - p)
			var y := _resting(size.y / 2, BOTTOM, size, Vector2.ONE, tilt) - hop
			return _pose(Vector2(0.0, y) + _landing_shake(bounce, time), Vector2.ONE, tilt)
		time -= length
	return _pose(_landing_shake(Config.BOUNCE_COUNT, time), Vector2.ONE, 0.0)

# 第一個角著地的震動由 FLOOR_HOLD 播放，之後每次著地的震動逐次減弱。
static func _landing_shake(landing: int, since: float) -> Vector2:
	if landing == 0:
		return Vector2.ZERO
	var strength := Config.LANDING_SHAKE * pow(Config.BOUNCE_DECAY, landing - 1)
	return Config.FLOOR_SHAKE * strength * vibration(since, Config.LANDING_SHAKE_DURATION, Config.COLLISION_SHAKE_FREQUENCY)

# 讓最高角（TOP）或最低角（BOTTOM）貼住 surface 時的中心高度。
static func _resting(surface: float, side: float, size: Vector2, scale: Vector2, tilt: float) -> float:
	return surface - _corner(side, size, scale, tilt).y

# 最高角（TOP）或最低角（BOTTOM）相對中心的位置；水平時為邊緣中點。
static func _corner(side: float, size: Vector2, scale: Vector2, tilt: float) -> Vector2:
	return _local(Vector2(side * signf(tilt) * 0.5, side * 0.5), size, scale, tilt)

static func _local(anchor: Vector2, size: Vector2, scale: Vector2, rotation: float) -> Vector2:
	return (anchor * size * scale).rotated(rotation)

static func _emitter(pose: Dictionary, size: Vector2, anchor: Vector2, direction: Vector2) -> Dictionary:
	return {"point": pose.position + _local(anchor, size, pose.scale, pose.rotation), "direction": direction}

static func _pose(position: Vector2, scale: Vector2, rotation: float) -> Dictionary:
	return {"position": position, "scale": scale, "rotation": rotation}
