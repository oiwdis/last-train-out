shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

// Two channels of seamless, band-limited density. Mipmaps keep distant filaments
// stable. All presets share the program and material instances prepared at startup.
uniform sampler2D density_field : repeat_enable, filter_linear_mipmap;
uniform vec4 shadow_tint : source_color = vec4(0.40, 0.48, 0.49, 1.0);
uniform vec4 light_tint : source_color = vec4(0.79, 0.81, 0.74, 1.0);
uniform float phase = 0.0;
uniform float detail = 1.0;
uniform float opacity = 0.60;
varying vec2 density_uv;

void vertex() {
	vec2 wind = vec2(TIME * 0.19, TIME * 0.044);
	density_uv = (VERTEX.xy - wind) * vec2(0.009, 0.024) + vec2(phase, phase * 0.37);
}

void fragment() {
	vec2 large = texture(density_field, density_uv).rg;
	float mass = large.r;
	if (detail > 0.0) {
		vec2 filament_uv = density_uv * vec2(2.6, 1.65) + large * 0.19 - TIME * vec2(0.000266, 0.0000616);
		mass = mix(mass, texture(density_field, filament_uv).b, detail * 0.27);
	}
	float ceiling = 0.25 + 0.50 * large.g + 0.18 * mass;
	float height_mask = 1.0 - smoothstep(ceiling - 0.34, ceiling + 0.12, UV.y);
	float sides = smoothstep(0.0, 0.13, UV.x) * smoothstep(0.0, 0.13, 1.0 - UV.x);
	float density = smoothstep(0.19, 0.74, mass + 0.09 * (1.0 - UV.y));
	float close_fade = smoothstep(1.2, 9.5, length(VERTEX));
	float scattering = clamp(0.18 + 0.70 * UV.y + 0.33 * large.g - 0.18 * density, 0.0, 1.0);
	ALBEDO = mix(shadow_tint.rgb, light_tint.rgb, scattering);
	ALPHA = opacity * density * height_mask * sides * close_fade;
}
