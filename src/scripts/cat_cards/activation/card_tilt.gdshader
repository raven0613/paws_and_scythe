shader_type canvas_item;

// 以每張貼圖自身中心為軸的透視傾斜，套用於卡片 visual 底下共用材質的陰影與卡面。
// tilt.x 讓左側靠近鏡頭，tilt.y 讓上緣靠近鏡頭；perspective 為鏡頭到卡面的距離（像素）。
uniform vec2 tilt = vec2(0.0);
uniform float perspective = 220.0;
uniform vec2 card_size = vec2(73.0, 92.0);
uniform float margin = 16.0;

varying vec2 local;
varying vec2 pivot;
varying vec4 tint;

void vertex() {
	pivot = VERTEX - UV * card_size + card_size * 0.5;
	vec2 grow = sign(VERTEX - pivot) * margin;
	VERTEX += grow;
	UV += grow / card_size;
	local = VERTEX;
	tint = COLOR;
}

// 由畫面上的點沿視線回推到傾斜卡面上的座標。
vec2 unproject(vec2 screen) {
	vec3 across = vec3(cos(tilt.x), -sin(tilt.x) * sin(tilt.y), sin(tilt.x) * cos(tilt.y));
	vec3 down = vec3(0.0, cos(tilt.y), sin(tilt.y));
	vec3 normal = cross(across, down);
	vec3 ray = vec3(screen, perspective);
	vec3 hit = vec3(0.0, 0.0, -perspective) + ray * (normal.z * perspective / dot(normal, ray));
	return vec2(dot(hit, across), dot(hit, down));
}

void fragment() {
	vec2 source = pivot + unproject(local - pivot);
	vec2 uv = UV + (source - local) / card_size;
	if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) {
		discard;
	}
	COLOR = texture(TEXTURE, uv) * tint;
}
