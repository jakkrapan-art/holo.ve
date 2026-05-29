shader_type canvas_item;
render_mode blend_add;

// ════════════════════════════════════════════════════════════════
// Kiara · Hinotori (evo) R3-C "Magma-Violet" — tuning pass on R2-C
// Changes vs R2-C (Lead feedback):
//   • opening slash now = the NORMAL Flame Slash crescent, UNROTATED
//     → same left→right reveal/fade, just smaller & subtler
//   • nicer phoenix silhouette: leaf body + front wing-flare + tail
//   • more IMPACT motion: snappy launch + head motion-smear (stretch
//     along travel when fast) + launch flash
//   • TERMINAL IMPACT BURST when the head reaches the corridor end
//     (ring + white core + radial shards) — blooms into the visual
//     pad so it is NOT clipped; damage AoE is unaffected (code-side)
//   • visual frame is WIDER than the damage corridor: travel/clip use
//     corridor_hx / corridor_hy / corridor_cx uniforms (pad = headroom)
// progress 0→1 drives slash → surge → impact → linger. scale_p = pop.
// ════════════════════════════════════════════════════════════════

uniform float progress    : hint_range(0.0, 1.0) = 0.0;
uniform float scale_p     : hint_range(0.01, 1.2) = 1.0;
uniform float aspect      : hint_range(1.0, 4.0)  = 1.714;
uniform float corridor_hx : hint_range(-1.0, 4.0) = -1.0;  // <0 = auto (frame edge)
uniform float corridor_hy : hint_range(-1.0, 1.0) = -1.0;  // <0 = auto
uniform float corridor_cx : hint_range(-1.0, 1.0) = 0.0;   // corridor centre offset (author-x)
uniform vec4  rim_color   : source_color = vec4(1.0, 0.30, 0.72, 1.0); // magenta rim

const vec3 P_CORE = vec3(1.00, 0.99, 0.92);  // white-gold
const vec3 P_B1   = vec3(1.00, 0.82, 0.28);  // gold
const vec3 P_B2   = vec3(1.00, 0.42, 0.08);  // orange
const vec3 P_B3   = vec3(0.86, 0.12, 0.18);  // crimson
const vec3 P_B4   = vec3(0.45, 0.10, 0.55);  // violet (tail/edge)

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

	// ── Motion: snappy launch + speed hump (for smear) ──────────
	float tt     = clamp((progress - 0.14) / 0.64, 0.0, 1.0);
	float travel = easeOut3(tt);
	float head_x = mix(LEFT, RIGHT, travel);
	float spd    = sin(3.14159 * tt);           // 0→1→0 speed envelope
	float born   = smoothstep(0.12, 0.24, progress);

	// ── Living-flame domain warp ────────────────────────────────
	vec2 w = vec2(fbm(uv * 4.0 + vec2(progress * 3.5, 0.0)),
	              fbm(uv * 4.0 + vec2(7.3, progress * 3.8)));
	vec2 fuv = uv + (w - 0.5) * 0.22 * born;

	float bx = head_x - fuv.x;
	float ay = abs(fuv.y);

	vec3  col = vec3(0.0);
	float a   = 0.0;

	// ── Opening slash — COPIED from the normal Flame Slash crescent
	//    (same polar-arc shape, reveal, bounded TAIL_LEN), rotated to
	//    face the lane exactly like the normal controller orients it
	//    toward the enemy. Size 0.28 (approved base). ─────────────
	{
		float SCALE = 0.28;
		vec2 a_uv = vec2(uv.y, -(uv.x - (LEFT + 0.06))) / SCALE;  // rotated: apex faces +x (forward)
		float R = 1.9; float APEX = -0.08; float cy = APEX + R;
		float TAIL_LEN = 0.95;
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
		float tailm  = smoothstep(front - TAIL_LEN, front - TAIL_LEN + 0.20, ang); // bounded tail (normal)
		float crescent = blade * reveal * tailm;
		float sfade = 1.0 - smoothstep(0.16, 0.30, progress);
		col += mix(P_B1, P_CORE, 0.55) * crescent * 1.4;
		a = max(a, crescent * sfade);
	}

	// ── Phoenix silhouette: leaf body + front wing-flare + tail ──
	float tail_len = 1.05;
	float t = clamp(bx / tail_len, 0.0, 1.0);
	float flick = fbm(vec2(uv.x * 5.0 - progress * 6.0, uv.y * 6.0));
	float base_w = sin(3.14159 * pow(t, 0.55));
	float dwf = (t - 0.20) / 0.13;
	float wingflare = exp(-dwf * dwf);                 // upswept front wings
	float hw = (hy * 0.74 * base_w + hy * 0.38 * wingflare) * mix(0.78, 1.18, flick);
	float across = ay / max(hw, 1e-3);
	float inr = step(0.0, bx) * step(bx, tail_len);

	float heat = (1.0 - across) * (1.0 - 0.50 * t) * inr;
	vec2 hp = vec2((uv.x - head_x) / (1.0 + 2.0 * spd), uv.y); // motion smear (stretch when fast)
	float head = exp(-dot(hp, hp) * 32.0);
	heat = max(heat, head * 1.25);
	heat = clamp(heat * born, 0.0, 1.0);

	float body_mask = smoothstep(0.03, 0.12, heat);
	float hb = clamp(heat + 0.20 * (flick - 0.5), 0.0, 1.0);   // band waves (sakuga)
	col += ramp(hb) * body_mask * 1.5;
	a = max(a, body_mask);

	col += P_CORE * smoothstep(0.82, 0.97, heat) * 1.7;        // white-hot core

	float rim = smoothstep(0.82, 0.95, across) * (1.0 - smoothstep(0.95, 1.10, across)) * inr * born;
	col += rim_color.rgb * rim * 2.2;
	a = max(a, rim);

	// ── Launch flash (brief) ────────────────────────────────────
	float flash = 1.0 - smoothstep(0.0, 0.12, abs(progress - 0.18));
	vec2 fp = vec2(uv.x - (LEFT + 0.05), uv.y);
	col += mix(P_CORE, rim_color.rgb, 0.2) * exp(-dot(fp, fp) * 9.0) * flash * 1.2;

	// ── TERMINAL IMPACT BURST at corridor end (blooms into pad) ──
	{
		float bphase = clamp((progress - 0.60) / 0.34, 0.0, 1.0);
		float arrive = smoothstep(0.80, 0.98, travel);
		vec2  ip = uv - vec2(RIGHT, 0.0);
		vec2  ipe = ip * vec2(1.0, 1.2);
		float r = length(ipe);
		float ang2 = atan(ip.y, ip.x);
		float ring_r = mix(0.03, 0.30, bphase);
		float ring = smoothstep(0.06, 0.0, abs(r - ring_r)) * (1.0 - bphase);
		float core = exp(-r * r * 20.0) * (1.0 - smoothstep(0.35, 1.0, bphase));
		float shards = smoothstep(0.55, 1.0, sin(ang2 * 7.0 + 1.0) * 0.5 + 0.5)
		             * smoothstep(0.32, 0.06, r) * 4.0 * bphase * (1.0 - bphase);
		float bf = arrive * born;
		col += (P_CORE * core * 2.2 + rim_color.rgb * ring * 1.8 + ramp(0.62) * shards * 0.9) * bf;
		a = max(a, clamp((core * 2.0 + ring * 1.4 + shards * 0.8) * bf, 0.0, 1.0));
	}

	// ── Ember spray ─────────────────────────────────────────────
	vec2 eg = uv * vec2(18.0, 12.0) + vec2(progress * 5.0, 0.0);
	vec2 cell = floor(eg); vec2 lp = fract(eg) - 0.5; float seed = hash(cell);
	float behind = smoothstep(0.0, 0.4, bx) * step(bx, 1.6) * step(ay, hy + 0.06);
	float tw = sin(progress * 6.28318 + seed * 6.28318) * 0.5 + 0.5;
	float ember = step(0.91, seed) * (1.0 - smoothstep(0.0, 0.30, length(lp))) * behind * (0.4 + 0.6 * tw) * born;
	col += mix(P_B2, P_B3, 0.5) * ember * 1.8;
	a = max(a, ember);

	// ── Lingering scorched bed (within damage lane) ─────────────
	float in_lane = step(LEFT - 0.05, uv.x) * step(uv.x, RIGHT + 0.05);
	float passed = smoothstep(0.0, 0.06, head_x - uv.x) * in_lane;
	float bed = passed * (1.0 - smoothstep(hy * 0.80, hy, abs(uv.y)));
	float bednz = fbm(vec2(uv.x * 4.0 - progress * 2.0, uv.y * 6.0 + progress));
	float linger = bed * mix(0.12, 0.45, bednz) * (0.45 + 0.55 * smoothstep(1.0, 0.40, progress));
	col += mix(P_B3, P_B4, 0.5) * linger * 0.9;
	a = max(a, linger * 0.55);

	// ── Envelope + life (clip only at the FRAME edge, not corridor) ─
	float ex = 1.0 - smoothstep(aspect * 0.5 - 0.08, aspect * 0.5, abs(uv.x));
	float ey = 1.0 - smoothstep(0.46, 0.50, abs(uv.y));
	float life = smoothstep(0.0, 0.04, progress) * (1.0 - smoothstep(0.84, 1.0, progress));
	float mask = ex * ey * life;
	col *= mask; a *= mask;

	COLOR = vec4(col, a);
}
