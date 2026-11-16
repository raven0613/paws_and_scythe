shader_type canvas_item;
render_mode unshaded;

uniform vec4 background_color : source_color;
uniform vec4 back_wave_color : source_color;
uniform vec4 front_wave_color : source_color;
uniform float speed;
uniform float amplitude;
uniform float wavelength;
uniform float surface_height;
uniform float layer_offset;
uniform float phase = 0.0;
uniform vec2 panel_size = vec2(113.0, 39.0);
// 晃動：slosh_tilt 為水面斜率（正值左側較高），slosh_chop 為碎浪振幅，皆以按鈕高度為單位。
uniform float slosh_tilt = 0.0;
uniform float slosh_chop = 0.0;
uniform float chop_wavelength = 36.0;
uniform float chop_speed = 7.0;

varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	float time = TIME * speed + phase;
	float x = local_position.x * TAU / wavelength;
	float y = local_position.y / panel_size.y;
	float lean = slosh_tilt * (local_position.x / panel_size.x - 0.5);
	float chop_x = local_position.x * TAU / chop_wavelength;
	float chop_time = TIME * chop_speed;
	float back_surface = surface_height + lean
		+ sin(x + time) * amplitude
		+ sin(x * 0.57 - time * 0.65) * amplitude * 0.35
		+ (sin(chop_x + chop_time) + sin(chop_x * 1.7 - chop_time * 1.3 + 2.1) * 0.5) * slosh_chop;
	float front_surface = surface_height + layer_offset + lean * 0.85
		+ sin(x * 0.83 - time * 0.8 + 1.7) * amplitude * 0.7
		+ sin(chop_x * 1.3 - chop_time * 1.1 + 0.7) * slosh_chop * 0.8;
	vec4 water = mix(background_color, back_wave_color, step(back_surface, y));
	water = mix(water, front_wave_color, step(front_surface, y));
	COLOR *= water;
}
