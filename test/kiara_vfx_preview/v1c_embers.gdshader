shader_type canvas_item;
render_mode blend_add;

// V1C — Slash Arc + Flame Trail + Ember Spray (revised)
//
// Fixes vs prior:
//  • Arc geometry center is shifted backward by arc_radius*cos(arc_span) so
//    the arc's chord endpoints land at slash_pos.x — the trail emerges from
//    the same x and meets the arc endpoints (was misaligned before).
//  • Universal x/y edge envelope multiplies the final body — flame fades to
//    0 well inside every rect edge, so no edge clipping anywhere.
//  • Arc trajectory removed; linear left→right motion only (per design call:
//    arc can come back via gd controller in real game scenes if desired).

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float scale_p  : hint_range(0.01, 1.2) = 1.0;
uniform float rect_aspect : hint_range(1.0, 10.0) = 3.0;

// Slash arc shape (thin sliver, convex forward)
uniform float arc_radius    : hint_range(0.15, 0.55) = 0.40;
uniform float arc_thickness : hint_range(0.02, 0.15) = 0.05;
uniform float arc_span      : hint_range(0.4, 1.6)  = 1.00;

// Trails behind the slash
uniform float trail_length       : hint_range(0.3, 2.5) = 1.2;
uniform float ember_trail_length : hint_range(0.5, 4.0) = 2.2;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i),               hash(i + vec2(1.0, 0.0)), f.x),
	           mix(hash(i + vec2(0.0,1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) { v += a * noise(p); p *= 2.0; a *= 0.5; }
	return v;
}
float easeOut3(float t) { return 1.0 - pow(1.0 - t, 3.0); }

void fragment() {
	vec2 uv = (UV - 0.5) * vec2(rect_aspect, 1.0) / max(scale_p, 0.01);
	float half_w = rect_aspect * 0.5;

	// Linear motion. slash_pos = visual anchor (arc endpoints + trail origin all live here)
	float blade_t = clamp(progress / 0.80, 0.0, 1.0);
	float slash_x = mix(-half_w + 0.4, half_w - 0.4, easeOut3(blade_t));
	vec2 local = uv - vec2(slash_x, 0.0);

	// Domain warp (slash-relative so noise travels with the slash)
	vec2 warp = 0.04 * vec2(
		fbm(local * 4.0 - vec2(progress * 4.0, 0.0)) - 0.5,
		fbm(local * 4.0 + vec2(13.0, 7.0) - vec2(0.0, progress * 3.0)) - 0.5
	);

	// ── Slash arc SDF (alignment fix) ────────────────────────
	// Shift arc geometry center BACKWARD by R*cos(θ). Then the arc's chord
	// endpoints (at angles ±arc_span) land at uv.x = slash_x — exactly where
	// the trail emerges. Arc and trail share the same visual anchor.
	vec2 arc_offset = vec2(arc_radius * cos(arc_span), 0.0);
	vec2 local_arc = local + arc_offset + warp;

	float r_polar = length(local_arc);
	float theta = atan(local_arc.y, local_arc.x);
	float d_band = abs(r_polar - arc_radius);
	float angle_from_forward = abs(theta);
	float angular_in = 1.0 - smoothstep(arc_span, arc_span + 0.15, angle_from_forward);
	float arc_body = (1.0 - smoothstep(arc_thickness * 0.4, arc_thickness, d_band)) * angular_in;

	// ── Flame trail behind slash_pos ─────────────────────────
	float behind = -local.x;
	float trail_t = clamp(max(0.0, behind) / trail_length, 0.0, 1.0);
	float trail_decay = exp(-trail_t * 1.8) * step(0.0, behind) * step(behind, trail_length);
	float trail_y_rad  = mix(0.18, 0.04, trail_t);
	float trail_upper = exp(-pow(max(0.0, -local.y) / (trail_y_rad * 1.4), 1.5));
	float trail_lower = exp(-pow(max(0.0,  local.y) / (trail_y_rad * 0.7), 1.5));
	float trail_y_env = trail_upper + trail_lower * 0.5;
	float trail = trail_decay * trail_y_env;

	// Wispy noise on trail
	vec2 local_w = local + warp;
	float n = fbm(vec2(local_w.x * 3.0, local_w.y * 4.0 - progress * 3.5));
	float wispy = smoothstep(0.30, 0.65, n);
	float trail_wispy = trail * mix(0.45, 1.0, wispy);

	float body = max(arc_body, trail_wispy);

	// ── Ember spray ──────────────────────────────────────────
	float ember_in = step(0.0, behind) * step(behind, ember_trail_length);
	float ember_decay = exp(-max(0.0, behind) / ember_trail_length * 1.4) * ember_in;
	vec2 ember_uv = uv * vec2(20.0, 14.0) + vec2(0.0, progress * 8.0);
	vec2 ember_grid  = floor(ember_uv);
	vec2 ember_local = fract(ember_uv) - 0.5;
	float seed = hash(ember_grid);
	float ember_thresh = mix(0.84, 0.97, smoothstep(-0.15, 0.20, local.y));
	float is_ember = step(ember_thresh, seed);
	float ember_d = length(ember_local);
	float ember_size = mix(0.12, 0.28, hash(ember_grid + 3.0));
	float ember_dot = is_ember * (1.0 - smoothstep(0.0, ember_size, ember_d));
	float twinkle = sin(progress * 6.28318 + seed * 6.28318) * 0.5 + 0.5;
	float ember = ember_dot * ember_decay * (0.45 + 0.55 * twinkle);

	body = max(body, ember * 0.85);

	// ── Universal edge envelope (no rect-edge leak anywhere) ─
	float x_envelope = 1.0 - smoothstep(half_w - 0.20, half_w - 0.05, abs(uv.x));
	float y_envelope = 1.0 - smoothstep(0.36, 0.46, abs(uv.y));
	body *= x_envelope * y_envelope;

	// Life envelope — fade in/out across the loop
	float life = smoothstep(0.0, 0.05, progress) * (1.0 - smoothstep(0.78, 1.0, progress));
	body *= life;

	// Temperature gradient
	vec3 col;
	col = mix(vec3(0.35, 0.03, 0.0),  vec3(1.0, 0.18, 0.02), smoothstep(0.0,  0.22, body));
	col = mix(col,                     vec3(1.0, 0.55, 0.10), smoothstep(0.20, 0.48, body));
	col = mix(col,                     vec3(1.0, 0.92, 0.35), smoothstep(0.48, 0.76, body));
	col = mix(col,                     vec3(1.0, 1.00, 0.85), smoothstep(0.76, 1.00, body));

	COLOR = vec4(col * body * 2.5, body);
}
