shader_type canvas_item;
#include "fog.gdshaderinc"
#include "flash.gdshaderinc"
uniform float color_cycles;
uniform float sheen;

void fragment() {
	vec3 fog = fog_field();
	float color_position = fract(fog.x * color_cycles + fog.z * 0.35);
	vec3 pastel = texture(color_ramp, vec2(color_position, 0.5)).rgb;
	vec3 hologram = mix(pastel, vec3(1.0), sheen * smoothstep(0.4, 0.8, fog.y));
	COLOR.rgb = apply_flash(mix(COLOR.rgb, clamp(hologram * brightness, 0.0, 1.0), energy));
}
