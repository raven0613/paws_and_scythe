shader_type canvas_item;
#include "fog.gdshaderinc"
#include "flash.gdshaderinc"
uniform vec4 violet : source_color;
uniform float violet_amount;
uniform float star_flow_speed;
uniform float star_cell_size;
uniform float star_density;
uniform vec2 star_radius;
uniform float star_brightness;
uniform vec4 star_color : source_color;
uniform float star_twinkle_speed;
uniform float star_twinkle_amount;
uniform float star_far_speed_ratio;
uniform float star_far_size_ratio;
uniform float star_far_brightness_ratio;
uniform float star_far_cell_ratio;

float stars(vec2 position, float cell_size, float size_ratio) {
	vec2 cell = floor(position / cell_size);
	vec2 local = fract(position / cell_size);
	float seed = fog_hash(cell);
	vec2 center = vec2(0.25) + 0.5 * vec2(fog_hash(cell + 31.7), fog_hash(cell + 73.2));
	float radius = mix(star_radius.x, star_radius.y, fog_hash(cell + 19.3)) * size_ratio;
	float distance = length((local - center) * cell_size);
	float core = 1.0 - smoothstep(radius * 0.2, radius, distance);
	float glow = exp(-distance * distance / (radius * radius * 3.0)) * 0.22;
	float twinkle = 1.0 - star_twinkle_amount * (0.5 + 0.5 * sin(clock_time * star_twinkle_speed + seed * 6.283185));
	return (core + glow) * twinkle * step(1.0 - star_density, seed);
}

void fragment() {
	vec3 fog = fog_field();
	vec3 nebula = texture(color_ramp, vec2(fog.x, 0.5)).rgb;
	float purple = violet_amount * smoothstep(0.35, 0.8, fog.z) * (1.0 - fog.y * 0.5);
	nebula = mix(nebula, violet.rgb, purple) * brightness;
	// 星點保留自己的慢速流動，不受雲霧座標扭曲。
	vec2 near_position = point + vec2(clock_time * star_flow_speed, 0.0);
	vec2 far_position = point + vec2(clock_time * star_flow_speed * star_far_speed_ratio, 0.0) + vec2(97.1, 41.3);
	float starlight = stars(near_position, star_cell_size, 1.0);
	starlight += stars(far_position, star_cell_size * star_far_cell_ratio, star_far_size_ratio) * star_far_brightness_ratio;
	vec3 galaxy = clamp(nebula + star_color.rgb * starlight * star_brightness, 0.0, 1.0);
	COLOR.rgb = apply_flash(mix(COLOR.rgb, galaxy, energy));
}
