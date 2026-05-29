shader_type canvas_item;
render_mode blend_add;

// ════════════════════════════════════════════════════════════════
// Kiara · Flame Slash — CONCEPT A "Crescent Slash"  (FGO-style)
// One bold cel-shaded crescent blade SWINGS along an arc (วงฟัน):
// the blade is a curved band that reveals angularly left→right.
// White-hot core → gold → orange → red, with motion-trail arcs and
// a spark at the blade tip. Shape-driven (no noise) for a clean read.
//
// Convention (matches amelia_skill_effect.gdshader):
//   progress 0→1 drives the swing · scale_p does the elastic pop-in.
// Author frame is horizontal; the controller rotates the rect in game.
// ════════════════════════════════════════════════════════════════

uniform float progress   : hint_range(0.0, 1.0) = 0.0;
uniform float scale_p    : hint_range(0.01, 1.2) = 1.0;
uniform float aspect     : hint_range(1.0, 4.0)  = 2.4;   // rect width / height
uniform float arc_radius : hint_range(0.8, 4.0)  = 1.9;   // bigger = gentler curve
uniform float arc_span   : hint_range(0.3, 1.2)  = 0.62;  // half angular extent (rad)

const float APEX_Y = -0.08;   // arc apex sits slightly above centre

const vec3 C_CORE   = vec3(1.00, 1.00, 0.92);  // white-hot
const vec3 C_GOLD   = vec3(1.00, 0.86, 0.30);
const vec3 C_ORANGE = vec3(1.00, 0.45, 0.08);
const vec3 C_RED    = vec3(0.85, 0.12, 0.03);

float easeOut3(float t) { return 1.0 - pow(1.0 - t, 3.0); }

float sdStar4(vec2 p, float r) {
	float s = 0.38;
	p = abs(p);
	if (p.y > p.x) p = p.yx;
	p.x -= r; p.y += s * r;
	float a = dot(p, vec2(s, -1.0));
	float b = dot(p, vec2(1.0,  s));
	return (max(a, b) < 0.0)
		? -min(length(p - vec2(s, -1.0) * a), length(p - vec2(1.0, s) * b))
		: length(max(vec2(a, b), 0.0));
}

void fragment() {
	vec2 uv = (UV - 0.5) * vec2(aspect, 1.0) / max(scale_p, 0.01);

	// ── Polar arc frame (centre below → arc bows up like ∩) ──
	float R   = arc_radius;
	float cy  = APEX_Y + R;
	vec2  rel = uv - vec2(0.0, cy);
	float rr  = length(rel);
	float ang = atan(rel.x, -rel.y);   // 0 at apex, + to the right

	// ── Angular swing front (fast snap, eased) ───────────────
	float swing     = easeOut3(clamp(progress / 0.42, 0.0, 1.0));
	float front_ang = mix(-arc_span - 0.12, arc_span + 0.12, swing);

	// ── Crescent band: thickness tapers to pointed tips ──────
	float an     = ang / arc_span;                    // -1..1 along arc
	float tip    = sqrt(max(0.0, 1.0 - an * an));     // 0 at tips, 1 mid
	float half_t = 0.16 * tip;
	float d_band = abs(rr - R);
	float across = d_band / max(half_t, 1e-3);        // 0 centre → 1 edge
	float inSpan = step(abs(ang), arc_span + 0.04);
	float blade  = (1.0 - smoothstep(0.82, 1.0, across)) * inSpan;
	float reveal = 1.0 - smoothstep(front_ang, front_ang + 0.06, ang);
	float body   = blade * reveal;

	// ── Colour ramp across the blade ─────────────────────────
	vec3 col = C_CORE;
	col = mix(col, C_GOLD,   smoothstep(0.05, 0.35, across));
	col = mix(col, C_ORANGE, smoothstep(0.35, 0.70, across));
	col = mix(col, C_RED,    smoothstep(0.70, 1.00, across));

	float trail = smoothstep(front_ang - 1.3, front_ang, ang);
	float shade = 0.40 + 0.60 * trail;
	shade = floor(shade * 3.0 + 0.5) / 3.0;   // 3 hard bands → anime
	col *= shade;

	float a = body;

	// ── Leading-edge highlight (bright tip line, angular) ────
	float edge = smoothstep(0.09, 0.0, abs(ang - front_ang)) * blade;
	col += C_CORE * edge * 1.3;
	a = max(a, edge);

	// ── Motion-trail concentric arcs behind the front ────────
	float speed = 0.0;
	for (int i = 0; i < 2; i++) {
		float ro     = R + (float(i) * 2.0 - 1.0) * 0.14;  // R-0.14, R+0.14
		float ln     = smoothstep(0.010, 0.0, abs(rr - ro)) * inSpan;
		float behind = smoothstep(front_ang, front_ang - 0.8, ang) * step(ang, front_ang);
		speed += ln * behind;
	}
	speed *= 0.40;
	col += C_GOLD * speed;
	a = max(a, speed);

	// ── Spark at the blade tip (only while travelling) ───────
	float tipFade = (1.0 - swing) * (1.0 - smoothstep(0.42, 0.55, progress));
	vec2  dir     = vec2(sin(front_ang), -cos(front_ang));
	vec2  tip_pos = vec2(0.0, cy) + R * dir;
	float star    = smoothstep(0.028, -0.01, sdStar4(uv - tip_pos, 0.035));
	col += C_CORE * star * tipFade * 1.6;
	a = max(a, star * tipFade);

	// ── Edge envelope — never touch rect borders ─────────────
	float ex = 1.0 - smoothstep(aspect * 0.5 - 0.12, aspect * 0.5 - 0.02, abs(uv.x));
	float ey = 1.0 - smoothstep(0.42, 0.49, abs(uv.y));
	a *= ex * ey;

	float life = smoothstep(0.0, 0.05, progress) * (1.0 - smoothstep(0.62, 1.0, progress));
	a *= life;

	COLOR = vec4(col * a * 2.2, a);
}
