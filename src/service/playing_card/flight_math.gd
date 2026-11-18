extends RefCounted

const Config = preload("res://src/configs/playing_card/flight_animation_config.gd")
const Frame = preload("res://src/configs/gameplay/gameplay_frame_config.gd")

static func spring(progress: float) -> float:
	# 臨界阻尼彈簧，將有限時間的響應正規化至精確終點。
	var response: float = Config.SPRING_RESPONSE
	return (1.0 - (1.0 + response * progress) * exp(-response * progress)) / (1.0 - (1.0 + response) * exp(-response))

static func reference_delta(delta: Vector2, viewport_size: Vector2) -> Vector2:
	return delta * Frame.REFERENCE_SIZE / viewport_size

static func local_direction(visible_delta: Vector2, local_to_view: Transform2D) -> Vector2:
	return local_to_view.affine_inverse().basis_xform(visible_delta).normalized()

# 基準畫面速度換算的形變強度：靜止為 0，達 FULL_SPEED 時為 1。
static func intensity(speed: float) -> float:
	return clampf(speed / Config.FULL_SPEED, 0.0, 1.0)

# 以 pivot 為中心，沿單位向量 direction 拉長 stretch、垂直方向除以相同倍率，面積不變，再整體放大 scale。
static func deform(direction: Vector2, stretch: float, scale: float, pivot: Vector2) -> Transform2D:
	var across := direction.orthogonal()
	var along := (1.0 + stretch) * scale
	var narrow := scale / (1.0 + stretch)
	var x := direction * direction.x * along + across * across.x * narrow
	var y := direction * direction.y * along + across * across.y * narrow
	return Transform2D(x, y, pivot - x * pivot.x - y * pivot.y)

# 離開桌面的高度，0 為桌面、1 為最高點：apex 之前快速升起並減速，之後加速落下，在 progress 為 1 時以最快速度觸地。
static func lift(progress: float, apex: float) -> float:
	if progress < apex:
		var rise := 1.0 - progress / apex
		return 1.0 - rise * rise
	var fall := (progress - apex) / (1.0 - apex)
	return 1.0 - fall * fall

# 落地回彈：scale 為牌面尺寸倍率，先壓小再 Q 彈回 1；carry 為到站殘留伸縮與傾身的倍率，由 1 反向擺動後收回 0。
static func landing(progress: float, profile: Dictionary) -> Dictionary:
	var decay: float = pow(1.0 - progress, profile.decay)
	var phase: float = progress * TAU * profile.cycles
	var press: float = profile.press
	return {"scale": 1.0 - press * sin(phase) * decay, "carry": cos(phase) * decay}
