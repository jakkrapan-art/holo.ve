shader_type canvas_item;
render_mode blend_add;

// V1 — Crescent Slash
// 3-tile × 1-tile horizontal slash. A flame "blade-stroke" sweeps left→right with a trail.
// Driven by `progress 0→1` (controller/Tween) — same convention as amelia_skill_effect.gdshader.

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float scale_p  : hint_range(0.01, 1.2) = 1.0;

// ── Noise (value-noise fbm) ────────────────────────────────
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
	for (int i = 0; i < 4; i++) { v += a * noise(p); p *= 2.0; a *= 0.5; }
	return v;
}

float easeOut3(float t) { return 1.0 - pow(1.0 - t, 3.0); }

void fragment() {
	// Map UV (0..1, 0..1) → (-1.5..1.5, -0.5..0.5) to preserve 3:1 aspect
	vec2 uv = (UV - 0.5) * vec2(3.0, 1.0) / max(scale_p, 0.01);

	// Slash front moves left→right over first 45% of progress
	float front_t = clamp(progress / 0.45, 0.0, 1.0);
	float front_x = mix(-1.6, 1.6, easeOut3(front_t));

	// Trail erase moves left→right starting at 45% — flame fades from the cut origin
	float erase_t = clamp((progress - 0.45) / 0.55, 0.0, 1.0);
	float erase_x = mix(-1.7, 1.6, erase_t);

	// Slash band — thin horizontal at y=0
	float slash_thick = 0.18;
	float y_mask = smoothstep(slash_thick, 0.0, abs(uv.y));

	// Region mask: behind the front AND beyond the erase line
	float region = step(uv.x, front_x) * step(erase_x, uv.x);

	// Flame turbulence — fbm scrolling left (gives "fire trailing")
	float n = fbm(vec2(uv.x * 1.5 - progress * 3.0, uv.y * 4.0));
	// Vertical tongues — high-frequency sine for fire wisp feel
	float tongue = sin(uv.x * 7.0 + progress * 12.0) * 0.5 + 0.5;

	float body = y_mask * region * (0.55 + 0.55 * n) * (0.7 + 0.4 * tongue);

	// Color gradient — yellow core → orange → red edge by |y|
	float vt = abs(uv.y) / slash_thick;
	vec3 yellow = vec3(1.0, 0.95, 0.30);
	vec3 orange = vec3(1.0, 0.45, 0.05);
	vec3 red    = vec3(0.90, 0.10, 0.0);
	vec3 col = mix(yellow, orange, smoothstep(0.0, 0.6, vt));
	col = mix(col, red, smoothstep(0.55, 1.0, vt));

	// Front pulse — bright streak at the cut head while traveling
	float front_dist = abs(uv.x - front_x);
	float front_glow = smoothstep(0.28, 0.0, front_dist) * y_mask * (1.0 - front_t);
	col += vec3(1.0, 0.98, 0.6) * front_glow * 2.5;
	body = max(body, front_glow * 0.9);

	// Overall life envelope
	float life = smoothstep(0.0, 0.1, progress) * (1.0 - smoothstep(0.8, 1.0, progress));

	float alpha = body * life;
	COLOR = vec4(col * alpha * 2.0, alpha);
}
