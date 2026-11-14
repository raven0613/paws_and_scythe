@tool
extends ShaderMaterial

const Config = preload("res://src/configs/score/score_fill_config.gd")
const Feel = preload("res://src/configs/score/celebration_config.gd")
const Galaxy = preload("res://src/scripts/score/celebration/galaxy.gdshader")
const Holographic = preload("res://src/scripts/score/celebration/rainbow.gdshader")

static func debris_palette() -> Array:
	if Config.MODE == Config.Mode.GALAXY:
		return Config.GALAXY_COLORS.slice(Config.GALAXY_DEBRIS_FROM) + [Config.STAR_COLOR, Config.GALAXY_VIOLET]
	return Config.HOLOGRAPHIC_COLORS.slice(0, -1)

func _init() -> void:
	var galaxy: bool = Config.MODE == Config.Mode.GALAXY
	shader = Galaxy if galaxy else Holographic
	var parameters := {
		"flow_speed": Config.GALAXY_FLOW_SPEED if galaxy else Config.HOLOGRAPHIC_FLOW_SPEED,
		"spatial_scale": Config.GALAXY_SPATIAL_SCALE if galaxy else Config.HOLOGRAPHIC_SPATIAL_SCALE,
		"warp": Config.GALAXY_WARP if galaxy else Config.HOLOGRAPHIC_WARP,
		"evolution_speed": Config.GALAXY_EVOLUTION_SPEED if galaxy else Config.HOLOGRAPHIC_EVOLUTION_SPEED,
		"fog_contrast": Config.GALAXY_CONTRAST if galaxy else Config.HOLOGRAPHIC_CONTRAST,
		"brightness": Config.GALAXY_BRIGHTNESS if galaxy else Config.HOLOGRAPHIC_BRIGHTNESS,
	}
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray(Config.GALAXY_COLORS if galaxy else Config.HOLOGRAPHIC_COLORS)
	var offsets := PackedFloat32Array()
	for index in gradient.colors.size():
		offsets.append(float(index) / (gradient.colors.size() - 1))
	gradient.offsets = offsets
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CUBIC
	var ramp := GradientTexture1D.new()
	ramp.width = Config.PALETTE_RESOLUTION
	ramp.gradient = gradient
	parameters.color_ramp = ramp
	parameters.flash_tint = Feel.FLASH_TINT if Feel.FLASH_TINT_ENABLED else Color.WHITE
	if galaxy:
		parameters.merge({
			"violet": Config.GALAXY_VIOLET, "violet_amount": Config.GALAXY_VIOLET_AMOUNT,
			"star_flow_speed": Config.STAR_FLOW_SPEED, "star_cell_size": Config.STAR_CELL_SIZE,
			"star_density": Config.STAR_DENSITY, "star_radius": Config.STAR_RADIUS,
			"star_brightness": Config.STAR_BRIGHTNESS, "star_color": Config.STAR_COLOR,
			"star_twinkle_speed": Config.STAR_TWINKLE_SPEED, "star_twinkle_amount": Config.STAR_TWINKLE_AMOUNT,
			"star_far_speed_ratio": Config.STAR_FAR_SPEED_RATIO, "star_far_size_ratio": Config.STAR_FAR_SIZE_RATIO,
			"star_far_brightness_ratio": Config.STAR_FAR_BRIGHTNESS_RATIO, "star_far_cell_ratio": Config.STAR_FAR_CELL_RATIO,
		})
	else:
		parameters.merge({"color_cycles": Config.HOLOGRAPHIC_COLOR_CYCLES, "sheen": Config.HOLOGRAPHIC_SHEEN})
	for parameter in parameters:
		set_shader_parameter(parameter, parameters[parameter])
