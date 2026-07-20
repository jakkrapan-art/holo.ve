shader_type canvas_item;
render_mode blend_mix;
// Watson Amelia — normal-attack bullet (Soft Glow). Clean round shape drawn entirely
// in-shader (no sprite texture sampled, so no black rim). Warm-gold pistol round.
// Static look — the bullet's animation is its transform, not the shader (no internal
// TIME). Do NOT use MODULATE: a custom-COLOR canvas_item fragment
// won't auto-apply it and an unknown built-in fails compile silently (square fallback).
// First production bullet in the game to use a custom shader (others use sprite+tint).

uniform vec4 core_color : source_color = vec4(1.0, 0.98, 0.86, 1.0);
uniform vec4 mid_color  : source_color = vec4(1.0, 0.84, 0.45, 1.0);
uniform vec4 edge_color : source_color = vec4(0.86, 0.52, 0.18, 1.0);
uniform float glow_softness : hint_range(0.0, 0.6) = 0.3;   // halo width (artist-tunable)
uniform float intensity : hint_range(0.0, 2.0) = 1.0;
uniform float alpha_mul : hint_range(0.0, 1.0) = 1.0;       // spawn-in / fade hook

void fragment() {
	vec2 uv = (UV - 0.5) * 2.0;          // -1..1, centre at 0
	float d = length(uv);                // 0 centre .. 1 circle edge

	// SOFT GLOW: white-hot core -> gold -> warm falloff; halo width = glow_softness
	// so a bigger bullet won't read as a smudge.
	vec3 col = mix(core_color.rgb, mid_color.rgb, smoothstep(0.0, 0.7, d));
	col = mix(col, edge_color.rgb, smoothstep(0.7, 1.0, d));
	col += core_color.rgb * (1.0 - smoothstep(0.0, 0.5, d)) * 0.6;

	float alpha = (1.0 - smoothstep(1.0 - glow_softness, 1.0, d)) * alpha_mul;
	col *= intensity;
	COLOR = vec4(col, alpha);
}
