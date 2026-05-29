shader_type canvas_item;
render_mode blend_add;

// ════════════════════════════════════════════════════════════════
// Kiara · Hinotori (evo) R2-A "Demon-Slayer cel-fire"
// Comet-phoenix base, rebuilt as LIVING anime flame:
//   • domain-warped fbm makes the silhouette churn/lick (not a fixed
//     shape sliding) — colour-as-motion (sakuga technique)
//   • hard CEL colour bands (white→gold→orange→crimson), high sat
//   • bold contrasting RIM around the silhouette (legibility)
//   • brief white IMPACT flash at launch
//   • opening slash reuses the normal Flame Slash crescent MOTION,
//     smaller/subtler (not the highlight)
// progress 0→1 drives slash → surge → linger. scale_p = pop.
// rim_color = tweakable accent.
// ════════════════════════════════════════════════════════════════

uniform float progress  : hint_range(0.0, 1.0) = 0.0;
uniform float scale_p   : hint_range(0.01, 1.2) = 1.0;
uniform float aspect    : hint_range(1.0, 4.0)  = 1.667;
uniform vec4  rim_color : source_color = vec4(1.0, 0.28, 0.10, 1.0); // bold crimson rim

// palette (warm shounen)
const vec3 P_CORE = vec3(1.00, 1.00, 0.95);
const vec3 P_B1   = vec3(1.00, 0.86, 0.30);  // gold
const vec3 P_B2   = vec3(1.00, 0.45, 0.08);  // orange
const vec3 P_B3   = vec3(0.85, 0.10, 0.05);  // crimson

float easeOut3(float t) { return 1.0 - pow(1.0 - t, 3.0); }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1,0)), f.x),
	           mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), f.x), f.y);
}
float fbm(vec2 p) { float v=0.0; float a=0.5; for(int i=0;i<5;i++){v+=a*noise(p);p*=2.0;a*=0.5;} return v; }

// hard CEL colour ramp (anime stepped bands)
vec3 ramp(float h) {
	vec3 c = P_B3;
	c = mix(c, P_B2,   step(0.32, h));
	c = mix(c, P_B1,   step(0.58, h));
	c = mix(c, P_CORE, step(0.82, h));
	return c;
}

void fragment() {
	vec2 uv = (UV - 0.5) * vec2(aspect, 1.0) / max(scale_p, 0.01);

	float LEFT  = -aspect * 0.5 + 0.12;
	float RIGHT =  aspect * 0.5 - 0.12;
	float travel = easeOut3(clamp((progress - 0.14) / 0.70, 0.0, 1.0));
	float head_x = mix(LEFT, RIGHT, travel);
	float born   = smoothstep(0.12, 0.24, progress);

	// living-flame domain warp (animates with progress)
	vec2 w = vec2(fbm(uv * 4.0 + vec2(progress * 3.5, 0.0)),
	              fbm(uv * 4.0 + vec2(7.3, progress * 3.8)));
	vec2 fuv = uv + (w - 0.5) * 0.20 * born;

	float bx = head_x - fuv.x;
	float ay = abs(fuv.y);

	vec3  col = vec3(0.0);
	float a   = 0.0;

	// ── Opening slash — reuse normal Flame Slash crescent MOTION ──
	{
		float SCALE = 0.55;
		vec2 a_uv = vec2(uv.y, -(uv.x - (LEFT + 0.04))) / SCALE; // rotate so apex bows forward
		float R = 1.9; float APEX = -0.08; float cy = APEX + R;
		vec2 rel = a_uv - vec2(0.0, cy);
		float rr = length(rel);
		float ang = atan(rel.x, -rel.y);
		float arc_span = 0.62;
		float sp = clamp(progress / 0.18, 0.0, 1.0);
		float front = mix(-arc_span - 0.12, arc_span + 0.12, easeOut3(sp));
		float an = ang / arc_span;
		float tip = sqrt(max(0.0, 1.0 - an * an));
		float half_t = 0.17 * tip;
		float across_s = abs(rr - R) / max(half_t, 1e-3);
		float inSpan = step(abs(ang), arc_span + 0.04);
		float blade = (1.0 - smoothstep(0.82, 1.0, across_s)) * inSpan;
		float reveal = 1.0 - smoothstep(front, front + 0.06, ang);
		float crescent = blade * reveal;
		float sfade = 1.0 - smoothstep(0.16, 0.30, progress);
		col += mix(P_B1, P_CORE, 0.5) * crescent * 1.5;     // subtler than normal
		a = max(a, crescent * sfade);
	}

	// ── Living-flame phoenix body ───────────────────────────────
	float tail_len = 1.0;
	float t = clamp(bx / tail_len, 0.0, 1.0);
	float flick = fbm(vec2(uv.x * 5.0 - progress * 6.0, uv.y * 6.0));
	float hw = (0.32 * sin(3.14159 * pow(t, 0.55))) * mix(0.78, 1.18, flick); // wings flicker
	float across = ay / max(hw, 1e-3);
	float inr = step(0.0, bx) * step(bx, tail_len);

	float heat = (1.0 - across) * (1.0 - 0.45 * t) * inr;
	vec2 hp = vec2((uv.x - head_x) * 1.3, uv.y);
	float head = exp(-dot(hp, hp) * 34.0);
	heat = max(heat, head * 1.2);
	heat = clamp(heat * born, 0.0, 1.0);

	float body_mask = smoothstep(0.03, 0.12, heat);
	float hb = clamp(heat + 0.16 * (flick - 0.5), 0.0, 1.0);   // band edges ripple (sakuga)
	col += ramp(hb) * body_mask * 1.5;
	a = max(a, body_mask);

	col += P_CORE * smoothstep(0.80, 0.96, heat) * 1.7;        // white-hot core

	// bold silhouette rim (contrasting accent)
	float rim = smoothstep(0.80, 0.94, across) * (1.0 - smoothstep(0.94, 1.08, across)) * inr * born;
	col += rim_color.rgb * rim * 2.2;
	a = max(a, rim);

	// ── Impact flash at launch (brief white bloom) ──────────────
	float flash = 1.0 - smoothstep(0.0, 0.12, abs(progress - 0.17));
	vec2 fp = vec2(uv.x - (LEFT + 0.05), uv.y);
	col += P_CORE * exp(-dot(fp, fp) * 9.0) * flash * 1.3;

	// ── Ember spray peeling behind ──────────────────────────────
	vec2 eg = uv * vec2(18.0, 12.0) + vec2(progress * 5.0, 0.0);
	vec2 cell = floor(eg); vec2 lp = fract(eg) - 0.5; float seed = hash(cell);
	float behind = smoothstep(0.0, 0.4, bx) * step(bx, 1.6) * step(ay, 0.44);
	float tw = sin(progress * 6.28318 + seed * 6.28318) * 0.5 + 0.5;
	float ember = step(0.91, seed) * (1.0 - smoothstep(0.0, 0.30, length(lp))) * behind * (0.4 + 0.6 * tw) * born;
	col += P_B2 * ember * 1.8;
	a = max(a, ember);

	// ── Lingering scorched bed ──────────────────────────────────
	float passed = smoothstep(0.0, 0.06, head_x - uv.x);
	float bed = passed * (1.0 - smoothstep(0.32, 0.47, abs(uv.y)));
	float bednz = fbm(vec2(uv.x * 4.0 - progress * 2.0, uv.y * 6.0 + progress));
	float linger = bed * mix(0.12, 0.45, bednz) * (0.45 + 0.55 * smoothstep(1.0, 0.40, progress));
	col += mix(P_B2, P_B3, 0.5) * linger * 0.9;
	a = max(a, linger * 0.55);

	// ── Envelope + life ─────────────────────────────────────────
	float ex = 1.0 - smoothstep(aspect * 0.5 - 0.10, aspect * 0.5, abs(uv.x));
	float ey = 1.0 - smoothstep(0.44, 0.50, abs(uv.y));
	float life = smoothstep(0.0, 0.04, progress) * (1.0 - smoothstep(0.80, 1.0, progress));
	float mask = ex * ey * life;
	col *= mask; a *= mask;

	COLOR = vec4(col, a);
}
