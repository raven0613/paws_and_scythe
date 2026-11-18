extends ColorRect

const Feedback = preload("res://src/configs/score/score_feedback_config.gd")
const SHADER = preload("res://src/scripts/score/celebration/impact_distortion.gdshader")

# 衝擊波與熱浪共用一層鋪滿畫面的扭曲，讀取一次下層畫面；位於周邊 UI 之上、暗角與中央分數之下。
func _ready() -> void:
	top_level = true
	z_as_relative = false
	z_index = Feedback.DISTORTION_LAYER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	material = ShaderMaterial.new()
	material.shader = SHADER
	hide()
	get_viewport().size_changed.connect(_fit)
	_fit()

# wave 的半徑與環寬以畫面半高為 1；haze 的中心、半徑、位移與飄移量為畫布像素。
func apply(center: Vector2, wave: Dictionary, haze: Dictionary) -> void:
	var half := size.y / 2
	material.set_shader_parameter("wave_center", center)
	material.set_shader_parameter("wave_radius", wave.radius * half)
	material.set_shader_parameter("wave_width", wave.width * half)
	material.set_shader_parameter("wave_strength", wave.strength)
	material.set_shader_parameter("wave_aberration", wave.aberration)
	material.set_shader_parameter("haze_center", haze.center)
	material.set_shader_parameter("haze_radius", haze.radius)
	material.set_shader_parameter("haze_strength", haze.strength)
	material.set_shader_parameter("haze_frequency", haze.frequency)
	material.set_shader_parameter("haze_drift", haze.drift)
	show()

func _fit() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	material.set_shader_parameter("canvas_size", size)
