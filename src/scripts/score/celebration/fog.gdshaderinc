uniform float energy = 0.0;
uniform float clock_time = 0.0;
uniform float flow_speed;
uniform float spatial_scale;
uniform float warp;
uniform float evolution_speed;
uniform float fog_contrast;
uniform float brightness;
uniform sampler2D color_ramp : source_color, filter_linear, repeat_disable;
varying vec2 point;

void vertex() {
	// 全部數字共用連續座標，跨字元保持同一片雲霧。
	point = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float fog_hash(vec2 p) {
	vec3 h = fract(vec3(p.xyx) * 0.1031);
	h += dot(h, h.yzx + 33.33);
	return fract((h.x + h.y) * h.z);
}

float fog_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	vec2 blend = f * f * (3.0 - 2.0 * f);
	return mix(mix(fog_hash(cell), fog_hash(cell + vec2(1.0, 0.0)), blend.x),
		mix(fog_hash(cell + vec2(0.0, 1.0)), fog_hash(cell + vec2(1.0)), blend.x), blend.y);
}

float fog_fbm(vec2 p) {
	float value = 0.0;
	float weight = 0.5;
	mat2 turn = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	for (int octave = 0; octave < 4; octave++) {
		value += fog_noise(p) * weight;
		p = turn * p * 2.02 + vec2(17.1, 9.2);
		weight *= 0.5;
	}
	return value / 0.9375;
}

vec3 fog_field() {
	// 取樣座標向右前進，雲霧形狀持續向左流動；翻湧另用較慢時鐘。
	vec2 p = (point + vec2(clock_time * flow_speed, 0.0)) * spatial_scale;
	float evolution = clock_time * evolution_speed;
	vec2 q = vec2(fog_fbm(p + vec2(0.0, evolution)),
		fog_fbm(p + vec2(5.2, 1.3 - evolution)));
	vec2 r = vec2(fog_fbm(p + warp * q + vec2(1.7, 9.2)),
		fog_fbm(p + warp * q + vec2(8.3, 2.8)));
	vec2 curled = p + warp * (r - 0.5);
	float body = fog_fbm(curled);
	float detail = fog_fbm(curled * 2.4 + q);
	float cloud = clamp(((body * 0.8 + detail * 0.2) - 0.5) * fog_contrast + 0.5, 0.0, 1.0);
	return vec3(cloud, detail, r.x);
}
