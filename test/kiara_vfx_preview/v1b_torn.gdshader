shader_type canvas_item;
render_mode blend_add;

// V1B — Torn Fireball
// Same fireball + teardrop geometry as V1A but with HEAVIER domain warp and
// two multiplied noise layers. Result: a fragmented, chaotic flame with
// visible internal gaps and a faint heat halo connecting torn pieces.

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float scale_p  : hint_range(0.01, 1.2) = 1.0;
uniform float rect_aspect : hint_range(1.0, 10.0) = 6.0;
uniform float ball_radius  : hint_range(0.03, 0.20) = 0.13;
uniform float trail_length : hint_range(0.5, 3.0)  = 1.7;

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
	float blade_t = clamp(progress / 0.80, 0.0, 1.0);
	float ball_x = mix(-half_w + 0.4, half_w - 0.4, easeOut3(blade_t));
	vec2 local = uv - vec2(ball_x, 0.0);

	// HEAVY warp → chaotic torn contour
	vec2 warp = 0.18 * vec2(
		fbm(local * 2.0 - vec2(progress * 3.0, progress * 4.0)) - 0.5,
		fbm(local * 2.5 + vec2(7.0, 3.0) - vec2(0.0, progress * 5.0)) - 0.5
	);
	vec2 local_w = local + warp;

	// Slightly wider teardrop — fragments can drift further out
	float forward  = 0.25;
	float backward = trail_length;
	float up       = 0.38;
	float down     = 0.14;
	float xs = local_w.x > 0.0 ? local_w.x / forward : local_w.x / backward;
	float ys = local_w.y > 0.0 ? local_w.y / down    : local_w.y / up;
	float field_d = length(vec2(xs, ys));
	float field = 1.0 - smoothstep(0.2, 1.0, field_d);

	// Circular core (sharp, no warp)
	float core = 1.0 - smoothstep(0.0, ball_radius, length(local));

	// Two-octave multiplied noise — destroys flame connectivity → gaps
	float n1 = fbm(vec2(local_w.x * 2.0, local_w.y * 3.0 - progress * 3.0));
	float n2 = fbm(vec2(local_w.x * 4.5 + 10.0, local_w.y * 4.0 - progress * 4.5));
	float n  = n1 * (0.4 + n2);

	float torn = smoothstep(0.42, 0.55, n);              // tight band → flame pieces
	float halo = smoothstep(0.22, 0.40, n) * 0.30;       // faint heat halo bridging pieces
	float fragmented = max(torn, halo);

	float body = max(core, field * fragmented);

	float life = smoothstep(0.0, 0.05, progress) * (1.0 - smoothstep(0.78, 1.0, progress));
	body *= life;

	vec3 col;
	col = mix(vec3(0.32, 0.02, 0.0), vec3(0.95, 0.12, 0.02), smoothstep(0.0,  0.22, body));
	col = mix(col,                    vec3(1.0,  0.48, 0.06), smoothstep(0.20, 0.48, body));
	col = mix(col,                    vec3(1.0,  0.85, 0.30), smoothstep(0.48, 0.76, body));
	col = mix(col,                    vec3(1.0,  1.00, 0.82), smoothstep(0.76, 1.00, body));

	COLOR = vec4(col * body * 2.5, body);
}
