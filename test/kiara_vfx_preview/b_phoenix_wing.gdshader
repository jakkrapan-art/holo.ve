shader_type canvas_item;
render_mode blend_add;

// ════════════════════════════════════════════════════════════════
// Kiara · Flame Slash — CONCEPT B "Phoenix Wing"  (Hoyo / WuWa-style)
// The slash SWINGS along an arc (วงฟัน) as three concentric feather-
// ribbons fanned like a phoenix wing. Smooth flowing bands with a
// noise erode dissolving the trailing edge, a gold rim-light on the
// leading edge, and embers peeling off behind. Elegant / elemental.
//
// Convention: progress 0→1 drives the swing · scale_p elastic pop-in.
// ════════════════════════════════════════════════════════════════

uniform float progress   : hint_range(0.0, 1.0) = 0.0;
uniform float scale_p    : hint_range(0.01, 1.2) = 1.0;
uniform float aspect     : hint_range(1.0, 4.0)  = 2.4;
uniform float arc_radius : hint_range(0.8, 4.0)  = 1.9;
uniform float arc_span   : hint_range(0.3, 1.2)  = 0.62;

const float APEX_Y = -0.08;

const vec3 C_CORE   = vec3(1.00, 0.97, 0.80);
const vec3 C_GOLD   = vec3(1.00, 0.80, 0.22);
const vec3 C_ORANGE = vec3(1.00, 0.42, 0.06);
const vec3 C_RED    = vec3(0.80, 0.10, 0.02);

float easeOut3(float t) { return 1.0 - pow(1.0 - t, 3.0); }
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

void fragment() {
	vec2 uv = (UV - 0.5) * vec2(aspect, 1.0) / max(scale_p, 0.01);

	float R   = arc_radius;
	float cy  = APEX_Y + R;
	vec2  rel = uv - vec2(0.0, cy);
	float rr  = length(rel);
	float ang = atan(rel.x, -rel.y);

	float swing     = easeOut3(clamp(progress / 0.45, 0.0, 1.0));
	float front_ang = mix(-arc_span - 0.12, arc_span + 0.12, swing);

	float an     = ang / arc_span;
	float tip    = sqrt(max(0.0, 1.0 - an * an));
	float inSpan = step(abs(ang), arc_span + 0.04);
	float reveal = 1.0 - smoothstep(front_ang, front_ang + 0.06, ang);

	vec3  col = vec3(0.0);
	float a   = 0.0;
	float rim = 0.0;

	// ── Three concentric feather ribbons → wing fan ──────────
	for (int i = 0; i < 3; i++) {
		float fi = float(i);
		float ro = R + (fi - 1.0) * 0.13;        // R-0.13, R, R+0.13
		float th = mix(0.13, 0.06, fi / 2.0);    // outer feathers thinner
		float d_band = abs(rr - ro);
		float across = d_band / max(th * tip, 1e-3);
		float ribbon = (1.0 - smoothstep(0.80, 1.0, across)) * inSpan;

		// dissolve erode: solid near front, breaks up toward the tail
		float nz    = fbm(vec2(ang * 4.0 - progress * 2.0, d_band * 8.0 + fi * 4.0));
		float age   = smoothstep(front_ang, front_ang - 1.4, ang);
		float erode = smoothstep(age * 0.9, age * 0.9 + 0.25, nz);
		float bd    = ribbon * reveal * mix(1.0, erode, 0.85);

		vec3 fcol = C_CORE;
		fcol = mix(fcol, C_GOLD,   smoothstep(0.05, 0.35, across));
		fcol = mix(fcol, C_ORANGE, smoothstep(0.35, 0.70, across));
		fcol = mix(fcol, C_RED,    smoothstep(0.70, 1.00, across));
		col += fcol * bd;
		a = max(a, bd);

		rim = max(rim, smoothstep(0.10, 0.0, abs(ang - front_ang)) * ribbon);
	}
	col += C_GOLD * rim * 1.4;
	a = max(a, rim);

	// ── Embers peeling off the trailing edge ─────────────────
	vec2  eg     = uv * vec2(16.0, 12.0) + vec2(progress * 6.0, -progress * 3.0);
	vec2  cell   = floor(eg);
	vec2  lp     = fract(eg) - 0.5;
	float seed   = hash(cell);
	float behind = smoothstep(front_ang, front_ang - 1.2, ang) * step(ang, front_ang) * inSpan;
	float ember  = step(0.90, seed) * (1.0 - smoothstep(0.0, 0.32, length(lp))) * behind;
	float tw     = sin(progress * 6.28318 + seed * 6.28318) * 0.5 + 0.5;
	col += C_ORANGE * ember * (0.5 + 0.5 * tw);
	a = max(a, ember * 0.8 * (0.5 + 0.5 * tw));

	// ── Edge envelope + life ─────────────────────────────────
	float ex = 1.0 - smoothstep(aspect * 0.5 - 0.12, aspect * 0.5 - 0.02, abs(uv.x));
	float ey = 1.0 - smoothstep(0.44, 0.49, abs(uv.y));
	a *= ex * ey;
	float life = smoothstep(0.0, 0.05, progress) * (1.0 - smoothstep(0.68, 1.0, progress));
	a *= life;

	COLOR = vec4(col * a * 2.2, a);
}
