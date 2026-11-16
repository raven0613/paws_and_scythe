shader_type canvas_item;
render_mode world_vertex_coords;

// 整張卡片共用的透視傾斜：卡片 visual 底下所有圖層共用此材質，每個頂點換回 visual 本地座標，
// 以卡片中心 pivot 為軸放到傾斜的平面上，再沿視線投影回畫面，貼圖以透視校正取樣。
// tilt.x 讓左側靠近鏡頭，tilt.y 讓上緣靠近鏡頭；perspective 為鏡頭到卡面的距離（卡片原尺寸像素），越小透視越強。
// card_origin、card_x、card_y 為 visual 的全域轉換。
uniform vec2 tilt = vec2(0.0);
uniform float perspective = 220.0;
uniform vec2 pivot = vec2(36.5, 46.0);
uniform vec2 card_origin;
uniform vec2 card_x = vec2(1.0, 0.0);
uniform vec2 card_y = vec2(0.0, 1.0);

varying vec3 corrected_uv;
varying vec4 tint;

void vertex() {
	mat2 basis = mat2(card_x, card_y);
	vec2 local = inverse(basis) * (VERTEX - card_origin) - pivot;
	vec3 across = vec3(cos(tilt.x), -sin(tilt.x) * sin(tilt.y), sin(tilt.x) * cos(tilt.y));
	vec3 down = vec3(0.0, cos(tilt.y), sin(tilt.y));
	vec3 point = across * local.x + down * local.y;
	float depth = perspective / (perspective + point.z);
	VERTEX = card_origin + basis * (pivot + point.xy * depth);
	corrected_uv = vec3(UV * depth, depth);
	tint = COLOR;
}

void fragment() {
	COLOR = texture(TEXTURE, corrected_uv.xy / corrected_uv.z) * tint;
}
