shader_type canvas_item;
render_mode world_vertex_coords;

uniform vec2 card_size;
uniform vec2 card_origin;
uniform vec2 card_x;
uniform vec2 card_y;
uniform vec2 front_corner;
uniform vec2 pull;

void vertex() {
	mat2 basis = mat2(card_x, card_y);
	vec2 local = inverse(basis) * (VERTEX - card_origin);
	vec2 uv = clamp(local / card_size, vec2(0.0), vec2(1.0));
	vec2 influence = mix(vec2(1.0) - uv, uv, front_corner);
	VERTEX += basis * pull * influence.x * influence.y;
}
