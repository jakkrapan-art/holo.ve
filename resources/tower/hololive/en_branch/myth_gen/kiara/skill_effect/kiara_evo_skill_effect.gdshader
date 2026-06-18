shader_type canvas_item;
render_mode blend_premul_alpha;   // premultiplied: dark magma bands show over the bright
                                  // map (true colour) while bright core/glow still adds.
                                  // (blend_add washed the violet/crimson over a lit bg.)

#include "res://resources/tower/shared/lane_fx.gdshaderinc"

// ════════════════════════════════════════════════════════════════
// Kiara · Hinotori (evo) — production VFX (magma-violet Wingsweep phoenix)
// Ported from test/kiara_vfx_preview/evo3_magma.gdshader with the chosen
// look baked as uniform DEFAULTS (shape=1 spread-wings, evo=2 Wingsweep,
// show_orb=false, show_streak=false, body_scale=0.6, burst_mode=1 none).
// The controller (kiara_evo_skill_effect.gd) only sets the dynamic uniforms
// (progress, scale_p, aspect, corridor_hx/hy/cx) + orients onto the 3×5 lane.
// Plays the whole rush internally via `progress`; damage is the separate
// wide-pierce kiara_skill_projectile. In-rect only — no scene FX.
// Perf: the fbm() calls are gated (born / slash-active) so the
// padded rect doesn't pay full noise cost where alpha is 0 — no look change.
// ════════════════════════════════════════════════════════════════

uniform float progress    : hint_range(0.0, 1.0) = 0.0;
uniform float scale_p     : hint_range(0.01, 1.2) = 1.0;
uniform float aspect      : hint_range(1.0, 4.0)  = 1.64;
uniform float corridor_hx : hint_range(-1.0, 4.0) = -1.0;
uniform float corridor_hy : hint_range(-1.0, 1.0) = -1.0;
uniform float corridor_cx : hint_range(-1.0, 1.0) = 0.0;
uniform int   shape       : hint_range(0, 2) = 1;        // baked: spread-wings
uniform vec4  rim_color   : source_color = vec4(1.0, 0.30, 0.72, 1.0);
uniform float body_scale  : hint_range(0.3, 1.5) = 0.6;  // baked: flies-farther
uniform bool  show_orb    = false;                       // baked: no head orb
uniform bool  show_streak = false;                       // baked: no inner cone
uniform int   evo              : hint_range(0, 2) = 2;   // baked: Wingsweep
uniform float feather_count    : hint_range(4.0, 16.0) = 9.0;
uniform float outline_strength : hint_range(0.0, 1.0) = 0.6;
uniform float wing_sweep       : hint_range(0.0, 1.2) = 0.8;
uniform int   burst_mode  : hint_range(0, 2) = 1;        // baked: no terminal burst
uniform float edge_fade   : hint_range(0.02, 0.6) = 0.30; // lane-end envelope fade band: bigger = softer dissolve near the caster (was a hard 0.05 scissor)

const vec3 P_CORE = vec3(1.00, 0.99, 0.92);
const vec3 P_B1   = vec3(1.00, 0.82, 0.28);
const vec3 P_B2   = vec3(1.00, 0.42, 0.08);
const vec3 P_B3   = vec3(0.86, 0.12, 0.18);
const vec3 P_B4   = vec3(0.45, 0.10, 0.55);

float easeOut3(float t) { return 1.0 - pow(1.0 - t, 3.0); }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1,0)), f.x),
	           mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), f.x), f.y);
}
float fbm(vec2 p) { float v=0.0; float a=0.5; for(int i=0;i<5;i++){v+=a*noise(p);p*=2.0;a*=0.5;} return v; }

vec3 ramp(float h) {
	vec3 c = P_B4;
	c = mix(c, P_B3,   step(0.24, h));
	c = mix(c, P_B2,   step(0.46, h));
	c = mix(c, P_B1,   step(0.66, h));
	c = mix(c, P_CORE, step(0.85, h));
	return c;
}

void fragment() {
	vec2 uv = (UV - 0.5) * vec2(aspect, 1.0) / max(scale_p, 0.01);

	float hx = (corridor_hx > 0.0) ? corridor_hx : (aspect * 0.5 - 0.12);
	float hy = (corridor_hy > 0.0) ? corridor_hy : 0.45;
	float LEFT  = corridor_cx - hx + 0.04;
	float RIGHT = corridor_cx + hx;

	// ── Motion: anticipation + HOLD → FAST rush, keeps drifting (no stop) ──
	float WIN = 0.30;
	float tt = clamp((progress - WIN) / 0.52, 0.0, 1.0);
	float launch = 1.0 - pow(1.0 - tt, 2.2);
	float drift = smoothstep(0.78, 1.0, progress);
	float pullc = smoothstep(0.0, WIN * 0.45, progress);
	float pull = 0.22 * pullc;
	float head_x = (progress < WIN) ? (LEFT - pull) : mix(LEFT, RIGHT, launch + 0.22 * drift);
	float spd = (progress < WIN) ? 0.0 : max(0.50, sin(3.14159 * tt));
	float born = smoothstep(WIN, WIN + 0.06, progress);

	// ── Living-flame domain warp (fbm gated: only once the body exists) ──
	vec2 w = vec2(0.5);
	if (born > 0.0) {
		w = vec2(fbm(uv * 4.0 + vec2(progress * 3.5, 0.0)),
		         fbm(uv * 4.0 + vec2(7.3, progress * 3.8)));
	}
	vec2 fuv = uv + (w - 0.5) * 0.22 * born;
	float bx = head_x - fuv.x;
	float ay = abs(fuv.y);

	vec3  col = vec3(0.0);
	float a   = 0.0;
	vec3  sc  = vec3(0.0);   // sparkle layer — own lifetime, outlives the body
	float sa  = 0.0;

	// ── Opening slash — magma crescent (fbm gated to the slash window) ──
	{
		float SCALE = 0.28;
		vec2 a_uv = vec2(uv.y, -(uv.x - (LEFT + 0.06))) / SCALE;
		float R = 1.9; float APEX = -0.08; float cy = APEX + R;
		float TAIL_LEN = 0.25;
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
		float tailm = smoothstep(front - TAIL_LEN, front - TAIL_LEN + 0.20, ang);
		float crescent = blade * reveal * tailm;
		float snz = (progress < 0.34) ? fbm(vec2(uv.x * 7.0 - progress * 5.0, uv.y * 8.0)) : 0.0;
		float sflame = mix(0.55, 1.0, snz);
		float sfade = 1.0 - smoothstep(0.16, 0.30, progress);
		col += ramp(clamp(0.55 + 0.35 * sflame, 0.0, 1.0)) * crescent * sflame * 1.6;
		a = max(a, crescent * sfade);
	}

	// ── Anticipation charge orb (no fbm — exp only) ─────────────
	{
		float charge = smoothstep(0.0, WIN, progress) * (1.0 - smoothstep(WIN, WIN + 0.06, progress));
		vec2 cp = uv - vec2(LEFT - pull, 0.0);
		float g = exp(-dot(cp, cp) * 18.0) * (0.82 + 0.18 * sin(progress * 40.0));
		col += ramp(0.92) * g * charge * 1.4;
		a = max(a, g * charge);
	}

	// ── Head (squash & stretch) — disabled (show_orb=false) but cheap ──
	float stretch = 1.0 + 3.2 * spd;
	vec2 hp = vec2((uv.x - head_x) / stretch, uv.y * (1.0 + 0.6 * spd)) / max(body_scale, 0.3);
	float head = show_orb ? exp(-dot(hp, hp) * 32.0) : 0.0;

	// ── Phoenix body silhouette (fbm `flick` gated by born) ─────
	float flick = (born > 0.0) ? fbm(vec2(uv.x * 5.0 - progress * 6.0, uv.y * 6.0)) : 0.0;
	float across; float inr; float heat;
	float ev_fhb = 0.0;
	float ev_quill = 0.0;
	float ev_crest = 0.0;
	if (shape == 2) {
		float tail_len = 1.45;
		float t = clamp(bx / tail_len, 0.0, 1.0);
		float wave = (hy * 0.55 * smoothstep(0.0, 0.18, t)) * sin(bx * 6.5 - progress * 5.0);
		float ribbon = hy * 0.42 * sin(3.14159 * pow(t, 0.7)) * mix(0.85, 1.15, flick) * body_scale;
		across = abs(fuv.y - wave) / max(ribbon, 1e-3);
		inr = step(0.0, bx) * step(bx, tail_len);
		heat = (1.0 - across) * (1.0 - 0.35 * t) * inr;
	} else if (shape == 1) {
		float tail_len = 0.72;
		float t = clamp(bx / tail_len, 0.0, 1.0);
		float body_w = hy * 0.28 * sin(3.14159 * pow(t, 0.6));
		float flap = 1.0 + 0.28 * sin(progress * 28.0 - bx * 2.5);
		float dw = (t - 0.20) / 0.10; float wing = hy * 1.05 * flap * exp(-dw * dw);
		float hw = (body_w + wing) * mix(0.80, 1.15, flick) * body_scale;
		float q = ay / (hy * 0.5); float fork = 1.0 - 0.6 * exp(-q * q) * smoothstep(0.65, 1.0, t);
		across = ay / max(hw, 1e-3);
		inr = step(0.0, bx) * step(bx, tail_len);
		heat = (1.0 - across) * (1.0 - 0.45 * t) * inr * fork;

		if (evo == 1) {
			vec2 wr = fuv - vec2(head_x - tail_len * 0.20, 0.0);
			float fang = atan(abs(wr.y), max(-wr.x, 1e-3));
			float fq = fract(fang * feather_count / 3.14159 + flick * 0.15);
			float quill = smoothstep(0.0, 0.12, fq) * smoothstep(1.0, 0.55, fq);
			quill *= (1.0 - smoothstep(0.5, 1.0, across)) * inr;
			ev_quill = quill;
			ev_fhb = 0.20 * quill;
		} else if (evo == 2) {
			float wingheat = 0.0; float toparc = 0.0;
			for (int k = 0; k < 3; k++) {
				float fk = float(k);
				float spine = hy * (0.30 + 0.20 * fk) * sin(3.14159 * pow(t, 0.6)) * body_scale
				            + hy * 0.10 * sin(progress * 28.0 - bx * 2.5 - fk * 0.8) * wing_sweep;
				float wk = max(hy * (0.20 - 0.045 * fk) * body_scale, 1e-3);
				float dk = ay - spine;
				float arc = exp(-(dk * dk) / (wk * wk)) * smoothstep(0.95, 0.30, t) * inr;
				wingheat = max(wingheat, arc * (1.0 - 0.18 * fk));
				if (k == 0) { toparc = arc; }
			}
			heat = clamp(max(heat, wingheat), 0.0, 1.0);
			ev_crest = smoothstep(0.55, 0.78, toparc) * (1.0 - smoothstep(0.78, 0.93, toparc)) * inr;
		}
	} else {
		float tail_len = 1.05;
		float t = clamp(bx / tail_len, 0.0, 1.0);
		float base_w = sin(3.14159 * pow(t, 0.55));
		float dwf = (t - 0.20) / 0.13; float wingflare = exp(-dwf * dwf);
		float hw = (hy * 0.74 * base_w + hy * 0.40 * wingflare) * mix(0.78, 1.18, flick) * body_scale;
		across = ay / max(hw, 1e-3);
		inr = step(0.0, bx) * step(bx, tail_len);
		heat = (1.0 - across) * (1.0 - 0.50 * t) * inr;
	}
	heat = max(heat, head * 1.25);
	heat = clamp(heat * born, 0.0, 1.0);

	float body_mask = smoothstep(0.03, 0.12, heat);
	float hb = clamp(heat + 0.20 * (flick - 0.5) + ev_fhb, 0.0, 1.0);
	col += ramp(hb) * body_mask * 1.5;
	a = max(a, body_mask);
	col += P_CORE * smoothstep(0.82, 0.97, heat) * 1.7;

	float rim = smoothstep(0.82, 0.95, across) * (1.0 - smoothstep(0.95, 1.10, across)) * inr * born;
	col += rim_color.rgb * rim * 2.2;
	a = max(a, rim);

	if (evo == 1) {
		col += ramp(clamp(hb + 0.22, 0.0, 1.0)) * ev_quill * body_mask;
		float ink = smoothstep(0.05, 0.14, heat) * (1.0 - smoothstep(0.14, 0.22, heat));
		col *= (1.0 - outline_strength * ink);
		float inner = smoothstep(0.16, 0.26, heat) * (1.0 - smoothstep(0.26, 0.36, heat));
		col += P_CORE * inner * 1.3;
		a = max(a, inner);
	}
	if (evo == 2) {
		col += (P_CORE * 1.8 + rim_color.rgb * 0.6) * ev_crest * born;
		a = max(a, ev_crest * born);
	}

	if (show_streak) {
		float streak_len = 0.55;
		float sb = head_x - uv.x;
		float st = clamp(sb / streak_len, 0.0, 1.0);
		float sw = hy * 0.40 * (1.0 - st) * body_scale;
		float sacross = abs(uv.y) / max(sw, 1e-3);
		float sgate = step(0.0, sb) * step(sb, streak_len) * born;
		float sl = fbm(vec2(uv.x * 11.0 - progress * 18.0, uv.y * 3.0));
		float streak = (1.0 - smoothstep(0.55, 1.0, sacross)) * sgate * mix(0.45, 1.0, sl);
		col += ramp(0.74) * streak * 1.7;
		col += P_CORE * streak * (1.0 - smoothstep(0.0, 0.35, sacross)) * 1.1;
		a = max(a, streak);
	}

	// ── Launch flash (brief, no fbm) ────────────────────────────
	float flash = 1.0 - smoothstep(0.0, 0.12, abs(progress - 0.30));
	vec2 fp = vec2(uv.x - (LEFT + 0.05), uv.y);
	col += mix(P_CORE, rim_color.rgb, 0.2) * exp(-dot(fp, fp) * 16.0) * flash * 0.8;

	// ── Terminal impact burst (baked off: burst_mode=1) ─────────
	if (burst_mode != 1) {
		float bphase = clamp((progress - 0.74) / 0.20, 0.0, 1.0);
		float arrive = smoothstep(0.78, 0.96, tt);
		float bf = arrive * born;
		vec2  ip = uv - vec2(RIGHT, 0.0);
		vec2  ipe = ip * vec2(1.0, 1.2);
		float r = length(ipe);
		float ang2 = atan(ip.y, ip.x);
		if (burst_mode == 2) {
			float flashc = exp(-r * r * 8.0) * (1.0 - smoothstep(0.0, 0.22, bphase));
			float ring_r2 = mix(0.02, 0.40, sqrt(bphase));
			float ripple = smoothstep(0.045, 0.0, abs(r - ring_r2)) * (1.0 - bphase) * (1.0 - bphase);
			float spikes = smoothstep(0.80, 1.0, sin(ang2 * 5.0) * 0.5 + 0.5)
			             * smoothstep(ring_r2 + 0.05, ring_r2 - 0.25, r) * smoothstep(0.0, 0.20, bphase) * (1.0 - bphase);
			col += (P_CORE * flashc * 2.4 + rim_color.rgb * ripple * 2.0 + ramp(0.70) * spikes * 1.2) * bf;
			a = max(a, clamp((flashc * 1.6 + ripple * 1.4 + spikes * 0.9) * bf, 0.0, 1.0));
		} else {
			float ring_r = mix(0.03, 0.30, bphase);
			float ring = smoothstep(0.06, 0.0, abs(r - ring_r)) * (1.0 - bphase);
			float core = exp(-r * r * 20.0) * (1.0 - smoothstep(0.35, 1.0, bphase));
			float shards = smoothstep(0.55, 1.0, sin(ang2 * 7.0 + 1.0) * 0.5 + 0.5)
			             * smoothstep(0.32, 0.06, r) * 4.0 * bphase * (1.0 - bphase);
			col += (P_CORE * core * 2.2 + rim_color.rgb * ring * 1.8 + ramp(0.62) * shards * 0.9) * bf;
			a = max(a, clamp((core * 2.0 + ring * 1.4 + shards * 0.8) * bf, 0.0, 1.0));
		}
	}

	// ── Projectile SPARKLES — own layer, outlives the body (the vanish) ──
	vec2 eg = uv * vec2(20.0, 14.0) + vec2(progress * 4.0, 0.0);
	vec2 cell = floor(eg); vec2 lp = fract(eg) - 0.5; float seed = hash(cell);
	float passed_e = step(uv.x, head_x) * step(LEFT - 0.10, uv.x) * step(uv.x, RIGHT + 0.30) * step(ay, hy + 0.10);
	float dim = 1.0 - smoothstep(0.2, 2.6, head_x - uv.x);
	float twk = sin(progress * 6.28318 + seed * 6.28318) * 0.5 + 0.5;
	float spark = step(0.90, seed) * (1.0 - smoothstep(0.0, 0.28, length(lp))) * passed_e * dim * (0.35 + 0.65 * twk) * born;
	sc += mix(P_B2, P_B3, hash(cell + 4.0)) * spark * 1.9;
	sa = max(sa, spark);

	// (Lingering scorched bed removed — its magenta corridor trail read as a rectangle behind
	//  the phoenix. Director cut it; the bird silhouette carries the read on its own.)

	// ── Envelope + VANISH (body fade + sparkles that outlive it) ─
	// Frame vignette via the shared corner-free helper (was ex*ey, which left a rectangle).
	// fade_x = edge_fade; fade_y = 0.03 (the old 0.47->0.50 band). Identical on the edges
	// where content lives; only the empty corner is rounded. See lane_fx.gdshaderinc.
	float env = lane_frame_mask(uv, aspect, edge_fade, 0.03) * smoothstep(0.0, 0.04, progress);
	float keep = 1.0 - smoothstep(0.80, 0.95, progress);
	float body_env = env * keep;
	float spark_env = env * (1.0 - smoothstep(0.90, 1.04, progress));

	col = col * body_env + sc * spark_env;
	a   = clamp(a * body_env + sa * spark_env, 0.0, 1.0);

	COLOR = vec4(col, a);
}
