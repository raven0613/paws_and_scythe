shader_type canvas_item;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec4 reference_tint : source_color = vec4(1.0);
void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	COLOR = vec4(pixel.rgb * tint.rgb / reference_tint.rgb, pixel.a * tint.a);
}
