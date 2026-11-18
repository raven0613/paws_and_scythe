shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform vec2 canvas_size;
uniform vec2 wave_center;
uniform float wave_radius;
uniform float wave_width;
uniform float wave_strength;
uniform float wave_aberration;
uniform vec2 haze_center;
uniform vec2 haze_radius = vec2(1.0);
uniform float haze_strength;
uniform float haze_frequency;
uniform float haze_drift;

float hash(vec2 p) {
	vec3 h = fract(vec3(p.xyx) * 0.1031);
	h += dot(h, h.yzx + 33.33);
	return fract((h.x + h.y) * h.z);
}

float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	vec2 blend = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), blend.x),
		mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0)), blend.x), blend.y);
}

// 位置皆為畫布像素。衝擊波環的截面在環前後推擠背景，最高點等於 wave_strength，並在環上錯開紅藍色；
// 熱浪在橢圓內以向上飄動的雜訊位移，往邊緣漸淡。
void fragment() {
	vec2 pixel = UV * canvas_size;
	vec2 away = pixel - wave_center;
	vec2 outward = normalize(away + vec2(0.0001));
	float band = (length(away) - wave_radius) / max(wave_width, 0.001);
	float ring = band * 2.449 * exp(0.5 - 3.0 * band * band);
	vec2 offset = outward * wave_strength * ring;
	float mask = 1.0 - smoothstep(0.35, 1.0, length((pixel - haze_center) / haze_radius));
	vec2 drift = (pixel + vec2(0.0, haze_drift)) * haze_frequency;
	vec2 ripple = vec2(noise(drift), noise(drift + vec2(17.3, 5.1))) * 0.65
		+ vec2(noise(drift * 2.1 + 3.7), noise(drift * 2.1 + 11.9)) * 0.35;
	offset += (ripple - 0.5) * 2.0 * haze_strength * mask;
	vec2 split = outward * wave_aberration * abs(ring) / canvas_size;
	vec2 uv = SCREEN_UV + offset / canvas_size;
	COLOR = vec4(texture(screen_texture, uv + split).r, texture(screen_texture, uv).g,
		texture(screen_texture, uv - split).b, 1.0);
}
