shader_type canvas_item;
render_mode blend_add, unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float blur;
uniform float intensity;

// CanvasGroup 的畫面為合成後的整團火焰光暈輪廓（預乘透明度），以兩圈取樣模糊後疊加到下層。
void fragment() {
	vec2 step = SCREEN_PIXEL_SIZE * blur;
	vec4 sum = texture(screen_texture, SCREEN_UV) * 0.2;
	for (int index = 0; index < 8; index++) {
		float angle = float(index) * 0.785398;
		vec2 direction = vec2(cos(angle), sin(angle));
		sum += texture(screen_texture, SCREEN_UV + direction * step * 0.5) * 0.06;
		sum += texture(screen_texture, SCREEN_UV + direction * step) * 0.04;
	}
	COLOR = vec4(sum.rgb * intensity, 1.0);
}
