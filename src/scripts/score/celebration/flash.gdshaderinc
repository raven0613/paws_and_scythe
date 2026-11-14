uniform float flash = 0.0;
uniform vec4 flash_tint : source_color = vec4(1.0);

// 撞擊瞬間填色為純白，回落時經過 flash_tint 再回到原本填色。
vec3 apply_flash(vec3 color) {
	vec3 hot = mix(flash_tint.rgb, vec3(1.0), flash);
	return mix(color, hot, sqrt(flash));
}
