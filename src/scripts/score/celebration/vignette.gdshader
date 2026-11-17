shader_type canvas_item;
uniform vec4 tint : source_color;
uniform float radius;
uniform float softness;
uniform float intensity;
uniform float aspect;

// 距離以畫面半高為 1、從畫面中心起算，半徑內透明，往外在 softness 寬度內加深到 intensity。
void fragment() {
	vec2 offset = (UV - 0.5) * vec2(aspect, 1.0) * 2.0;
	float shade = smoothstep(radius, radius + softness, length(offset));
	COLOR = vec4(tint.rgb, tint.a * shade * clamp(intensity, 0.0, 1.0));
}
