shader_type canvas_item;
render_mode blend_add;

// ════════════════════════════════════════════════════════════════
// Kiara · Flame Slash — CONCEPT C "Sigil Burst"  (2D-pixel / idol)
// Iconographic, sticker-flat anime look — same family as Amelia's VFX.
//   Phase 1 (0.00–0.32): phoenix sigil ring + flame core flashes in.
//   Phase 2 (0.25–0.62): a bold gold-outlined crescent SWINGS along
//                        an arc (วงฟัน), revealed angularly.
//   Phase 3 (0.55–1.00): sparkle + heart burst (KFP idol cuteness).
// Hard edges + flat fills + thick gold outline. Cute / magical.
//
// Convention: progress 0→1 drives the sequence · scale_p elastic pop.
// ════════════════════════════════════════════════════════════════

uniform float progress   : hint_range(0.0, 1.0) = 0.0;
uniform float scale_p    : hint_range(0.01, 1.2) = 1.0;
uniform float aspect     : hint_range(1.0, 4.0)  = 2.4;
uniform float arc_radius : hint_range(0.8, 4.0)  = 1.9;
uniform float arc_span   : hint_range(0.3, 1.2)  = 0.62;

const float APEX_Y = -0.08;

const vec3 C_OUTLINE = vec3(1.00, 0.78, 0.12);  // gold outline
const vec3 C_FILL    = vec3(1.00, 0.40, 0.05);  // orange flat fill
const vec3 C_CORE    = vec3(1.00, 0.96, 0.85);
const vec3 C_PINK    = vec3(1.00, 0.55, 0.62);  // idol heart pink

float easeOut3(float t) { return 1.0 - pow(1.0 - t, 3.0); }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

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

float heart(vec2 p) {
	p.y -= 0.25;
	float x = p.x;
	float y = -p.y;
	float q = x * x + y * y - 1.0;
	return q * q * q - x * x * y * y * y;
}

void fragment() {
	vec2 uv = (UV - 0.5) * vec2(aspect, 1.0) / max(scale_p, 0.01);
	vec3  col = vec3(0.0);
	float a   = 0.0;

	// ── PHASE 1: phoenix sigil ring (0.00–0.32) ──────────────
	float p1   = clamp(progress / 0.32, 0.0, 1.0);
	float ringFade = 1.0 - smoothstep(0.55, 0.85, progress);
	{
		float rr   = mix(0.05, 0.30, easeOut3(p1));
		float d    = abs(length(uv) - rr);
		float ringline = smoothstep(0.022, 0.012, d);
		float ang  = atan(uv.y, uv.x);
		float ticks = smoothstep(0.85, 0.95, abs(sin(ang * 4.0))) * smoothstep(0.05, 0.02, d);
		col += C_OUTLINE * (ringline + ticks) * ringFade * 1.4;
		a = max(a, (ringline + ticks) * ringFade);

		float emb = smoothstep(0.05, -0.02, sdStar4(uv, 0.07)) * ringFade * p1;
		col += C_CORE * emb * 1.5;
		a = max(a, emb);
	}

	// ── PHASE 2: bold outlined crescent SWING (0.25–0.62) ────
	float p2 = clamp((progress - 0.25) / 0.37, 0.0, 1.0);
	float slashFade = (1.0 - smoothstep(0.62, 0.82, progress)) * step(0.25, progress);
	{
		float R   = arc_radius;
		float cy  = APEX_Y + R;
		vec2  rel = uv - vec2(0.0, cy);
		float rr  = length(rel);
		float ang = atan(rel.x, -rel.y);
		float swing     = easeOut3(p2);
		float front_ang = mix(-arc_span - 0.10, arc_span + 0.10, swing);
		float an    = ang / arc_span;
		float tip   = sqrt(max(0.0, 1.0 - an * an));
		float th    = 0.15 * tip;
		float across = abs(rr - R) / max(th, 1e-3);
		float inSpan = step(abs(ang), arc_span + 0.04);
		float reveal = 1.0 - smoothstep(front_ang, front_ang + 0.05, ang);
		float fill    = (1.0 - smoothstep(0.78, 0.92, across)) * reveal * slashFade * inSpan;
		float outline = clamp(smoothstep(1.05, 0.92, across) - smoothstep(0.92, 0.78, across), 0.0, 1.0) * reveal * slashFade * inSpan;
		col = mix(col, C_FILL, fill);
		col = mix(col, C_OUTLINE, outline);
		a = max(a, max(fill, outline));
	}

	// ── PHASE 3: sparkle + heart burst (0.55–1.00) ───────────
	float p3 = clamp((progress - 0.55) / 0.45, 0.0, 1.0);
	float burstFade = 1.0 - p3;
	{
		float br = mix(0.10, 0.46, easeOut3(p3));
		for (int i = 0; i < 10; i++) {
			float fi  = float(i);
			float ang = fi / 10.0 * 6.28318 + 0.3;
			vec2  pos = vec2(cos(ang), sin(ang)) * br * vec2(1.1, 0.8);
			if (i % 3 == 0) {
				float h  = heart((uv - pos) / 0.055);
				float hk = smoothstep(0.02, -0.05, h) * burstFade;
				col += C_PINK * hk * 1.4;
				a = max(a, hk);
			} else {
				float sz = mix(0.05, 0.018, p3);
				float st = smoothstep(0.02, -0.015, sdStar4(uv - pos, sz)) * burstFade;
				col += (i % 2 == 0 ? C_OUTLINE : C_CORE) * st * 1.6;
				a = max(a, st);
			}
		}
		float pop = smoothstep(0.12, 0.0, length(uv)) * burstFade * (1.0 - step(0.80, progress));
		col += C_CORE * pop * 1.2;
		a = max(a, pop * 0.6);
	}

	// ── Edge envelope + life ─────────────────────────────────
	float ex = 1.0 - smoothstep(aspect * 0.5 - 0.10, aspect * 0.5, abs(uv.x));
	float ey = 1.0 - smoothstep(0.45, 0.50, abs(uv.y));
	a *= ex * ey;
	float life = smoothstep(0.0, 0.04, progress) * (1.0 - smoothstep(0.85, 1.0, progress));
	a *= life;

	COLOR = vec4(col * a * 2.2, a);
}
