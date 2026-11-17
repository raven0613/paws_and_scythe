uniform float flash = 0.0;
uniform vec4 flash_tint : source_color = vec4(1.0);
uniform float impact = 0.0;
uniform vec4 impact_color : source_color = vec4(1.0);

// 撞擊瞬間填色為純白，回落時經過 flash_tint 再回到原本填色；impact 為銀河轉場的反轉幀，整片換成 impact_color。
vec3 apply_flash(vec3 color) {
	vec3 hot = mix(flash_tint.rgb, vec3(1.0), flash);
	return mix(mix(color, hot, sqrt(flash)), impact_color.rgb, impact);
}
