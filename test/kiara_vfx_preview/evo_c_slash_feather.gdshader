shader_type canvas_item;
render_mode blend_add;

// ════════════════════════════════════════════════════════════════
// Kiara · Hinotori (evo) — Variant C "Slash-Feather Phoenix"
// The phoenix is BUILT from the slash: several crescent blade-feathers
// fan out behind a comet head like wings, carrying the Flame Slash
// lineage forward down the 3×5 corridor. Strongest "slash trace" read.
// Sacred white-gold, opening slash + lingering bed shared with A/B.
// ════════════════════════════════════════════════════════════════

uniform float progress  : hint_range(0.0, 1.0) = 0.0;
uniform float scale_p   : hint_range(0.01, 1.2) = 1.0;
uniform float aspect    : hint_range(1.0, 4.0)  = 1.667;
uniform vec4  rim_color : source_color = vec4(1.0, 0.82, 0.28, 1.0);

const vec3 C_SACRED = vec3(1.00, 0.98, 0.90);
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
	float born    = smoothstep(0.10, 0.22, progress);

	float bx = head_x - uv.x;
	float ay = abs(uv.y);

	vec3  col = vec3(0.0);
	float a   = 0.0;

	// ── Opening sacred slash (shared) ───────────────────────────
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

	// ── Blade-feather wings (fan of thin crescents behind head) ──
	vec2 P = vec2(uv.x - head_x, uv.y);
	float feather = 0.0;
	float fedge   = 0.0;
	for (int i = 0; i < 5; i++) {
		float fi = float(i) / 4.0;            // 0..1 across the fan
		float th = mix(-0.55, 0.55, fi);      // fan spread angle
		float c = cos(th); float s = sin(th);
		vec2  q = vec2(P.x * c - P.y * s, P.x * s + P.y * c);
		float fb = -q.x;                      // distance behind head along feather
		float flen = 0.72 - 0.18 * abs(fi - 0.5) * 2.0; // outer feathers shorter
		float ft = clamp(fb / flen, 0.0, 1.0);
		float fhw = 0.055 * sin(3.14159 * ft);          // thin leaf blade
		float across = abs(q.y) / max(fhw, 1e-3);
		float inr = step(0.0, fb) * step(fb, flen);
		feather += (1.0 - smoothstep(0.55, 1.0, across)) * inr;
		fedge   += smoothstep(0.72, 1.0, across) * (1.0 - smoothstep(1.0, 1.2, across)) * inr;
	}
	feather = clamp(feather, 0.0, 1.0) * born;
	fedge   = clamp(fedge, 0.0, 1.0) * born;

	float nz = fbm(vec2(uv.x * 3.5 - progress * 3.0, uv.y * 5.0));
	float flame = mix(0.7, 1.0, smoothstep(0.2, 0.7, nz));
	float t = clamp(bx / 0.8, 0.0, 1.0);

	vec3 grad = C_SACRED;
	grad = mix(grad, C_GOLD,   smoothstep(0.0, 0.45, t));
	grad = mix(grad, C_AMBER,  smoothstep(0.40, 0.80, t));
	grad = mix(grad, C_ORANGE, smoothstep(0.70, 1.0, t));
	col += grad * feather * flame * 1.7;
	a = max(a, feather * flame);

	// comet head
	vec2 hp = vec2((uv.x - head_x) * 1.4, uv.y);
	float head = exp(-dot(hp, hp) * 44.0);
	col += C_SACRED * head * born * 2.6;
	a = max(a, head * born);

	// blade edges glow (tweakable accent)
	col += rim_color.rgb * fedge * 1.5 * flame;
	a = max(a, fedge * 0.8);

	// ── Ember spray + lingering bed (shared family) ─────────────
	vec2 eg = uv * vec2(18.0, 12.0) + vec2(progress * 5.0, 0.0);
	vec2 cell = floor(eg); vec2 lp = fract(eg) - 0.5; float seed = hash(cell);
	float behind = smoothstep(0.0, 0.4, bx) * step(bx, 1.5) * step(ay, 0.42);
	float tw = sin(progress * 6.28318 + seed * 6.28318) * 0.5 + 0.5;
	float ember = step(0.92, seed) * (1.0 - smoothstep(0.0, 0.30, length(lp))) * behind * (0.4 + 0.6 * tw) * born;
	col += C_AMBER * ember * 1.8;
	a = max(a, ember);

	float passed = smoothstep(0.0, 0.06, head_x - uv.x);
	float bed = passed * (1.0 - smoothstep(0.30, 0.46, ay));
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
