extends ColorRect

const Config = preload("res://src/configs/score/galaxy_transition_config.gd")
const Feedback = preload("res://src/configs/score/score_feedback_config.gd")
const SHADER = preload("res://src/scripts/score/celebration/vignette.gdshader")

# 銀河暗角鋪滿畫面，獨立於父節點的位置與圖層，位於周邊 UI 之上、飛行粒子與中央分數之下。
func _ready() -> void:
	top_level = true
	z_as_relative = false
	z_index = Feedback.VIGNETTE_LAYER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	material = ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("tint", Config.VIGNETTE_COLOR)
	material.set_shader_parameter("softness", Config.VIGNETTE_SOFTNESS)
	hide()
	get_viewport().size_changed.connect(_fit)
	_fit()

func apply(pose: Dictionary) -> void:
	material.set_shader_parameter("radius", pose.radius)
	material.set_shader_parameter("intensity", pose.intensity)
	show()

func _fit() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	material.set_shader_parameter("aspect", size.x / size.y)
