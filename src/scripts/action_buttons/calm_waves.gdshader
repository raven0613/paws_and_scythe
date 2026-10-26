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

varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	float time = TIME * speed + phase;
	float x = local_position.x * TAU / wavelength;
	float y = local_position.y / panel_size.y;
	float back_surface = surface_height
		+ sin(x + time) * amplitude
		+ sin(x * 0.57 - time * 0.65) * amplitude * 0.35;
	float front_surface = surface_height + layer_offset
		+ sin(x * 0.83 - time * 0.8 + 1.7) * amplitude * 0.7;
	vec4 water = mix(background_color, back_wave_color, step(back_surface, y));
	water = mix(water, front_wave_color, step(front_surface, y));
	COLOR *= water;
}
