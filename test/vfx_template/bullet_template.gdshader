shader_type canvas_item;
render_mode blend_mix;
// ================================================================
// BULLET + IMPACT SHADER TEMPLATE (copy me) - godot-2dfx skill
//
// ONE shader draws BOTH beats off `phase` (production convention,
// docs/shader.md Section 2): 0 = in flight, 1 = on-hit impact. The
// single vfx_shader warm then covers both - do NOT split the impact
// into a second shader file.
//
// Uniform names core_color / mid_color / edge_color / glow_softness
// must keep these exact names: they are the set a tower YAML `attack:`
// block may override (TowerAttackConfig.COLOR_KEYS).
//
// CRAFT TRAP (Ina, Director-caught): an afterimage/ghost offset FORWARD
// along the travel axis pushes its tip past the quad edge, where the
// scissor turns it into a flat lit cap on the projectile's head. It
// reads as deliberate glow and survives review - lagging-copy offsets
// must be NEGATIVE, and any bullet look must be checked at the quad
// boundary before presenting.
//
// Variant exploration: while the 3 directions are unrelated, use 3
// copies of this shader; once the round narrows to branches of one
// winner, fold them into a single `look` int uniform on ONE shader
// (one shader = one warm).
// ================================================================

uniform float phase = 0.0;     // 0 = flight, 1 = impact (set once at spawn)
uniform float life = 0.0;      // seconds in flight, pushed per frame (AttackController._onBulletMove)
uniform float progress = 0.0;  // impact clock 0->1 (AttackController._spawnImpact tween)

uniform vec4 core_color : source_color = vec4(1.0, 0.98, 0.9, 1.0);
uniform vec4 mid_color : source_color = vec4(1.0, 0.78, 0.35, 1.0);
uniform vec4 edge_color : source_color = vec4(0.9, 0.35, 0.1, 1.0);
uniform float glow_softness = 0.6;

// Flight beat: bolt travelling along +X (the harness rotates the quad).
vec4 flight(vec2 p) {
	// body: elongated core/mid/edge falloff
	float d = length(vec2(p.x * 0.55, p.y));
	float body = smoothstep(0.7 + 0.3 * glow_softness, 0.0, d);
	float core = smoothstep(0.24, 0.0, d);
	// afterimage ghost: offset NEGATIVE (lagging) - see CRAFT TRAP above
	float dg = length(vec2((p.x + 0.45) * 0.8, p.y));
	float ghost = smoothstep(0.45, 0.0, dg) * 0.35;
	// gentle energy flicker off seconds-in-flight
	float flicker = 0.92 + 0.08 * sin(life * 30.0);
	vec3 col = edge_color.rgb * body;
	col = mix(col, mid_color.rgb, pow(body, 2.0));
	col = mix(col, core_color.rgb, core);
	float a = clamp(body + ghost, 0.0, 1.0) * flicker;
	return vec4(col, a);
}

// Impact beat: radial ring + flash - the reason production spawns this on a
// square UNROTATED quad (AttackController._spawnImpact).
vec4 impact(vec2 p) {
	float r = length(p);
	float ring_r = mix(0.05, 0.85, progress);
	float ring_w = 0.05 + 0.15 * glow_softness;
	float ring = smoothstep(ring_w, 0.0, abs(r - ring_r));
	float flash = smoothstep(0.5, 0.0, r) * (1.0 - smoothstep(0.0, 0.4, progress));
	float fade = 1.0 - smoothstep(0.55, 1.0, progress);
	vec3 col = edge_color.rgb * ring;
	col = mix(col, mid_color.rgb, ring * 0.6);
	col += core_color.rgb * flash;
	float a = clamp(ring + flash, 0.0, 1.0) * fade;
	return vec4(col, a);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	COLOR = phase < 0.5 ? flight(p) : impact(p);
}
