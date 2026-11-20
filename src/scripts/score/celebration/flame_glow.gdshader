shader_type canvas_item;
render_mode blend_premul_alpha, unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
// blur 為螢幕像素，由 block_flame.gd 依畫面縮放換算。
uniform float blur;
uniform float halo_alpha;
const int RINGS = 6;
const int DIRECTIONS = 16;

// CanvasGroup 的畫面為以各層提亮色合成的整團火焰輪廓（預乘透明度）。多圈取樣 blur 範圍內的平均覆蓋率與顏色，各圈錯開角度讓邊緣平滑；
// 輪廓邊緣的覆蓋率約為一半，放大兩倍後邊緣達到 halo_alpha 並往外平滑淡出，以正常混色畫在火焰後方，光與該處火焰同色。
void fragment() {
	vec4 sum = texture(screen_texture, SCREEN_UV);
	float total = 1.0;
	for (int ring = 1; ring <= RINGS; ring++) {
		float distance = float(ring) / float(RINGS);
		float weight = exp(-distance * distance);
		for (int index = 0; index < DIRECTIONS; index++) {
			float angle = (float(index) + 0.5 * float(ring)) * TAU / float(DIRECTIONS);
			sum += texture(screen_texture, SCREEN_UV + vec2(cos(angle), sin(angle)) * SCREEN_PIXEL_SIZE * blur * distance) * weight;
			total += weight;
		}
	}
	float strength = min(sum.a / total * 2.0, 1.0) * halo_alpha;
	vec3 tint = sum.rgb / max(sum.a, 0.0001);
	COLOR = vec4(tint, 1.0) * strength;
}
