shader_type canvas_item;
render_mode blend_add;

// ════════════════════════════════════════════════════════════════
// Kiara · Hinotori (evo) — Variant A "Comet Phoenix"
// Beats: opening sacred slash → phoenix comet flies L→R down the
// 3×5 corridor (head + swept wing-leaf body + ember tail) → lingering
// scorched bed fades. Sacred white-gold palette. In-rect only.
//   progress 0→1 drives the whole sequence (travel + linger + fade).
//   scale_p = elastic pop-in. rim_color = tweakable accent (flag: red).
// ════════════════════════════════════════════════════════════════

uniform float progress  : hint_range(0.0, 1.0) = 0.0;
uniform float scale_p   : hint_range(0.01, 1.2) = 1.0;
uniform float aspect    : hint_range(1.0, 4.0)  = 1.667;
uniform vec4  rim_color : source_color = vec4(1.0, 0.82, 0.28, 1.0);

const vec3 C_SACRED = vec3(1.00, 0.98, 0.90);  // white-gold
const vec3 C_GOLD   = vec3(1.00, 0.85, 0.32);
const vec3 C_AMBER  = vec3(1.00, 0.55, 0.12);
const vec3 C_ORANGE = vec3(1.00, 0.38, 0.06);

float easeOut3(float t) { return 1.0 - pow(1.0 - t, 3.0); }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1,0)), f.x),
	           mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), f.x), f.y);
}
float fbm(vec2 p) { float v=0.0; float a=0.5; for(int i=0;i<5;i++){v+=a*noise(p);p*=2.0;a*=0.5;} return v; }

void fragment() {
	vec2 uv = (UV - 0.5) * vec2(aspect, 1.0) / max(scale_p, 0.01);

	float LEFT  = -aspect * 0.5 + 0.12;
	float RIGHT =  aspect * 0.5 - 0.12;
	float travel  = easeOut3(clamp((progress - 0.12) / 0.72, 0.0, 1.0));
	float head_x  = mix(LEFT, RIGHT, travel);
	float wob     = 0.02 * sin(progress * 18.0);
	float born    = smoothstep(0.10, 0.22, progress);

	float bx = head_x - uv.x;             // distance behind the head
	float ay = abs(uv.y - wob);

	vec3  col = vec3(0.0);
	float a   = 0.0;

	// ── Opening sacred slash: vertical crescent across the lane mouth ──
	{
		float halfW = 0.40;
		float swipe = clamp(progress / 0.16, 0.0, 1.0);
		float xline = (LEFT + 0.02) + 0.10 * (1.0 - clamp(abs(uv.y) / halfW, 0.0, 1.0));
		float edge  = mix(0.0, halfW + 0.05, easeOut3(swipe));
		float within = 1.0 - smoothstep(edge, edge + 0.05, abs(uv.y));
		float band  = 1.0 - smoothstep(0.04, 0.11, abs(uv.x - xline));
		float sfade = 1.0 - smoothstep(0.14, 0.30, progress);
		float crescent = band * within;
		col += mix(C_GOLD, C_SACRED, 0.6) * crescent * 2.4;
		a = max(a, crescent * sfade);
	}

	// ── Comet head (bright sacred teardrop) ──────────────────────
	vec2 hp = vec2((uv.x - head_x) * 1.4, uv.y - wob);
	float head = exp(-dot(hp, hp) * 42.0);

	// ── Wing-leaf body trailing the head ────────────────────────
	float tail_len = 0.85;
	float t  = clamp(bx / tail_len, 0.0, 1.0);
	float hw = 0.22 * sin(3.14159 * pow(t, 0.6));      // 0 at head & tail, wing bulge mid
	float across = ay / max(hw, 1e-3);
	float inr  = step(0.0, bx) * step(bx, tail_len);
	float nz   = fbm(vec2(uv.x * 3.0 - progress * 3.0, uv.y * 5.0));
	float flame = mix(0.7, 1.0, smoothstep(0.2, 0.7, nz));
	float body = (1.0 - smoothstep(0.55, 1.0, across)) * inr * flame * born;

	// gradient: centerline/head hot → edges & tail cooler
	vec3 grad = C_SACRED;
	grad = mix(grad, C_GOLD,   smoothstep(0.0, 0.40, across) + t * 0.30);
	grad = mix(grad, C_AMBER,  smoothstep(0.35, 0.75, across));
	grad = mix(grad, C_ORANGE, smoothstep(0.55, 1.0, t));
	col += grad * body * 1.6;
	a = max(a, body);

	col += C_SACRED * head * born * 2.6;
	a = max(a, head * born);

	// ── Gold leading rim on wing edges (tweakable accent) ───────
	float wing_edge = smoothstep(0.78, 1.0, across) * (1.0 - smoothstep(1.0, 1.18, across)) * inr * born;
	col += rim_color.rgb * wing_edge * 1.5 * flame;
	a = max(a, wing_edge * 0.8);

	// ── Ember spray peeling off behind ──────────────────────────
	vec2 eg = uv * vec2(18.0, 12.0) + vec2(progress * 5.0, 0.0);
	vec2 cell = floor(eg); vec2 lp = fract(eg) - 0.5; float seed = hash(cell);
	float behind = smoothstep(0.0, 0.4, bx) * step(bx, 1.4) * step(ay, 0.40);
	float tw = sin(progress * 6.28318 + seed * 6.28318) * 0.5 + 0.5;
	float ember = step(0.92, seed) * (1.0 - smoothstep(0.0, 0.30, length(lp))) * behind * (0.4 + 0.6 * tw) * born;
	col += C_AMBER * ember * 1.8;
	a = max(a, ember);

	// ── Lingering scorched bed (fades as progress → 1) ──────────
	float passed = smoothstep(0.0, 0.06, head_x - uv.x);
	float bed = passed * (1.0 - smoothstep(0.30, 0.46, abs(uv.y)));
	float bednz = fbm(vec2(uv.x * 4.0 - progress * 2.0, uv.y * 6.0 + progress));
	float linger = bed * mix(0.12, 0.45, bednz) * (0.45 + 0.55 * smoothstep(1.0, 0.40, progress));
	col += mix(C_AMBER, C_ORANGE, 0.5) * linger * 0.8;
	a = max(a, linger * 0.55);

	// ── Envelope + life ─────────────────────────────────────────
	float ex = 1.0 - smoothstep(aspect * 0.5 - 0.10, aspect * 0.5, abs(uv.x));
	float ey = 1.0 - smoothstep(0.42, 0.49, abs(uv.y));
	float life = smoothstep(0.0, 0.04, progress) * (1.0 - smoothstep(0.80, 1.0, progress));
	float mask = ex * ey * life;
	col *= mask; a *= mask;

	COLOR = vec4(col, a);
}
