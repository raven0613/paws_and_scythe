extends RefCounted

const Config = preload("res://src/configs/cat_cards/cat_activation_config.gd")
const Timing = preload("res://src/service/cat_cards/activation/activation_timing.gd")
const Badge = preload("res://src/service/cat_cards/activation/badge_motion.gd")
static var _samples: Array[PackedVector2Array] = []

# 各節尾巴中心相對主體中心的位移，由前往後排列，尚未乘上主體縮放。
static func offsets(time: float) -> PackedVector2Array:
	var samples := simulate()
	var position := maxf(time, 0.0) / Config.TAIL_STEP
	var index := int(position)
	if index >= samples.size() - 1:
		return rest()
	var result := PackedVector2Array()
	for tail in samples[index].size():
		result.append(samples[index][tail].lerp(samples[index + 1][tail], position - index))
	return result

static func rest() -> PackedVector2Array:
	var result := PackedVector2Array()
	var point := Vector2.ZERO
	for distance in Config.TAIL_REST_DISTANCE:
		point += Vector2.from_angle(Config.TAIL_REST_ANGLE) * distance
		result.append(point)
	return result

# 以固定步長模擬到到位後 TAIL_SETTLE_DURATION 秒；第 i 筆為時間 i × TAIL_STEP 的位移。
# 方向以連續角度追蹤，尾巴沿目標實際轉過的方向甩動。
static func simulate() -> Array[PackedVector2Array]:
	if not _samples.is_empty():
		return _samples
	var step := Config.TAIL_STEP
	var count := ceili((Timing.arrival() + Config.BADGE_LANDING_DURATION + Config.TAIL_SETTLE_DURATION) / step)
	var velocity := _velocity(0.0)
	var lead := _direction(0.0, velocity)
	var angles: Array[float] = []
	var spins: Array[float] = []
	var distances: Array[float] = []
	var stretches: Array[float] = []
	for tail in Config.TAIL_REST_DISTANCE.size():
		angles.append(lead)
		spins.append(0.0)
		distances.append(_distance(tail, velocity))
		stretches.append(0.0)
	for index in count + 1:
		_samples.append(_record(angles, distances))
		var time := index * step
		velocity = _velocity(time)
		lead += wrapf(_direction(time, velocity) - lead, -PI, PI)
		for tail in angles.size():
			var target: float = lead if tail == 0 else angles[tail - 1]
			spins[tail] += (Config.TAIL_ANGLE_STIFFNESS[tail] * (target - angles[tail]) - Config.TAIL_ANGLE_DAMPING[tail] * spins[tail]) * step
			angles[tail] += spins[tail] * step
			var gap := _distance(tail, velocity) - distances[tail]
			stretches[tail] += (Config.TAIL_DISTANCE_STIFFNESS[tail] * gap - Config.TAIL_DISTANCE_DAMPING[tail] * stretches[tail]) * step
			distances[tail] += stretches[tail] * step
	return _samples

static func _velocity(time: float) -> Vector2:
	return (Badge.path(time + Config.TAIL_STEP) - Badge.path(time)) / Config.TAIL_STEP

# 快速移動時朝移動反方向，減速後轉回隨主體轉動的靜止方向。
static func _direction(time: float, velocity: Vector2) -> float:
	var follow := clampf(velocity.length() / Config.TAIL_FOLLOW_SPEED, 0.0, 1.0)
	var resting := Config.TAIL_REST_ANGLE + Badge.rotation(time) - Config.BADGE_ROTATION
	return lerp_angle(resting, (-velocity).angle(), follow)

static func _distance(tail: int, velocity: Vector2) -> float:
	return Config.TAIL_REST_DISTANCE[tail] + velocity.length() * Config.TAIL_STRETCH

static func _record(angles: Array[float], distances: Array[float]) -> PackedVector2Array:
	var result := PackedVector2Array()
	var point := Vector2.ZERO
	for tail in angles.size():
		point += Vector2.from_angle(angles[tail]) * distances[tail]
		result.append(point)
	return result
