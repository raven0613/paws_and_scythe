extends RefCounted

const Config = preload("res://src/configs/playing_card/flight_animation_config.gd")
const Frame = preload("res://src/configs/gameplay/gameplay_frame_config.gd")

static func spring(progress: float) -> float:
	# 臨界阻尼彈簧，將有限時間的響應正規化至精確終點。
	var response: float = Config.SPRING_RESPONSE
	return (1.0 - (1.0 + response * progress) * exp(-response * progress)) / (1.0 - (1.0 + response) * exp(-response))

static func reference_delta(delta: Vector2, viewport_size: Vector2) -> Vector2:
	return delta * Frame.REFERENCE_SIZE / viewport_size

static func stretch_ratio(distance: float) -> float:
	return clampf(distance / Config.FULL_STRETCH_DISTANCE, 0.0, 1.0) * Config.MAX_STRETCH_RATIO

static func front_corner(direction: Vector2) -> Vector2:
	return Vector2(1.0 if direction.x >= 0.0 else 0.0, 1.0 if direction.y > 0.0 else 0.0)

static func local_direction(visible_delta: Vector2, local_to_view: Transform2D) -> Vector2:
	return local_to_view.affine_inverse().basis_xform(visible_delta).normalized()

static func stretch_envelope(progress: float) -> float:
	var attack := smoothstep(0.0, Config.STRETCH_ATTACK, progress)
	return attack * lerpf(1.0, Config.ARRIVAL_STRETCH, progress)
