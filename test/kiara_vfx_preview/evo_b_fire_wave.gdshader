shader_type canvas_item;
render_mode blend_add;

// ════════════════════════════════════════════════════════════════
// Kiara · Hinotori (evo) — Variant B "Dragon-Slave Fire-Wave"
// A surging WALL of phoenix fire fills the 3-tile width and sweeps
// down the 5-tile corridor, a bright sacred head poking forward at
// center. Emphasis on the grand wave (Dragon Slave feel) over a
// distinct bird. Opening slash + lingering bed shared with A.
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

	// ── Fire-wave: leading wall + decaying body fill ────────────
	float f1 = fbm(vec2(uv.x * 3.5 - progress * 4.0, uv.y * 4.0));
	float f2 = fbm(vec2(uv.x * 7.0 - progress * 6.0, uv.y * 7.0 + 3.0));
	float head_poke = head_x + 0.12 * (1.0 - clamp(ay / 0.18, 0.0, 1.0)); // center reaches further
	float dwall = uv.x - head_poke;                                       // >0 ahead of wall
	float wall  = exp(-pow(max(dwall, 0.0) / 0.05, 2.0));                  // sharp leading edge
	float fill  = smoothstep(0.0, 0.05, bx) * exp(-bx * 1.4);             // decays behind
	float wEnv  = 1.0 - smoothstep(0.34, 0.47, ay);
	float tongues = mix(0.5, 1.0, f1) * mix(0.6, 1.0, f2);
	float wave  = (wall * 1.2 + fill) * wEnv * tongues * born;

	vec2  hp   = vec2((uv.x - head_x) * 1.2, uv.y);
	float head = exp(-dot(hp, hp) * 36.0);

	// gradient: front hot sacred/gold → body amber→orange behind
	vec3 grad = mix(C_ORANGE, C_AMBER, smoothstep(0.0, 0.6, exp(-bx)));
	grad = mix(grad, C_GOLD,   clamp(wall * 0.9, 0.0, 1.0));
	grad = mix(grad, C_SACRED, clamp(head, 0.0, 1.0));
	col += grad * wave * 1.4;
	a = max(a, clamp(wave, 0.0, 1.0));

	col += C_SACRED * head * born * 2.2;
	a = max(a, head * born);

	// leading rim (tweakable accent)
	float lead = exp(-pow(max(dwall, 0.0) / 0.02, 2.0)) * wEnv * born;
	col += rim_color.rgb * lead * 1.7;
	a = max(a, lead);

	// ── Ember spray + lingering bed (shared family) ─────────────
	vec2 eg = uv * vec2(16.0, 11.0) + vec2(progress * 5.0, 0.0);
	vec2 cell = floor(eg); vec2 lp = fract(eg) - 0.5; float seed = hash(cell);
	float behind = smoothstep(0.0, 0.4, bx) * step(bx, 1.6) * step(ay, 0.42);
	float tw = sin(progress * 6.28318 + seed * 6.28318) * 0.5 + 0.5;
	float ember = step(0.91, seed) * (1.0 - smoothstep(0.0, 0.30, length(lp))) * behind * (0.4 + 0.6 * tw) * born;
	col += C_AMBER * ember * 1.7;
	a = max(a, ember);

	float passed = smoothstep(0.0, 0.06, head_x - uv.x);
	float bed = passed * (1.0 - smoothstep(0.30, 0.47, ay));
	float bednz = fbm(vec2(uv.x * 4.0 - progress * 2.0, uv.y * 6.0 + progress));
	float linger = bed * mix(0.14, 0.50, bednz) * (0.45 + 0.55 * smoothstep(1.0, 0.40, progress));
	col += mix(C_AMBER, C_ORANGE, 0.5) * linger * 0.85;
	a = max(a, linger * 0.6);

	// ── Envelope + life ─────────────────────────────────────────
	float ex = 1.0 - smoothstep(aspect * 0.5 - 0.10, aspect * 0.5, abs(uv.x));
	float ey = 1.0 - smoothstep(0.42, 0.49, abs(uv.y));
	float life = smoothstep(0.0, 0.04, progress) * (1.0 - smoothstep(0.80, 1.0, progress));
	float mask = ex * ey * life;
	col *= mask; a *= mask;

	COLOR = vec4(col, a);
}
