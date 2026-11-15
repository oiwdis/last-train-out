shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform vec4 tint : source_color = vec4(0.31, 0.36, 0.38, 0.62);
uniform float phase = 0.0;
uniform float detail = 1.0;
void fragment() {
	vec2 p = UV * vec2(16.0, 4.0);
	float drift = sin(p.x * 1.7 + sin(p.y * 2.0 + TIME * 0.19) + phase);
	float wisps = sin(p.y * 5.0 + drift * 2.0 - TIME * 0.35);
	float noise = 0.5 + 0.25 * drift + 0.25 * wisps * detail;
	float edges = smoothstep(0.0, 0.1, UV.x) * smoothstep(1.0, 0.9, UV.x) * smoothstep(0.0, 0.25, UV.y);
	ALBEDO = tint.rgb * (0.72 + noise * 0.28);
	ALPHA = tint.a * edges * (0.68 + noise * 0.32);
}
