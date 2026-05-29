shader_type canvas_item;
render_mode blend_add;

// ════════════════════════════════════════════════════════════════
// Kiara · Hinotori (evo) R2-B "Sacred Azure-Gold Rebirth"
// Same living-flame comet-phoenix base as R2-A, but the "ฉีก"
// spectacular take: warm gold fire core with a COOL azure-white RIM
// (anime complementary contrast = pop) — divine rebirth phoenix.
// Hard cel bands, sakuga colour-motion, brief impact flash, normal
// Flame Slash crescent motion for the opening (subtler).
// ════════════════════════════════════════════════════════════════

uniform float progress  : hint_range(0.0, 1.0) = 0.0;
uniform float scale_p   : hint_range(0.01, 1.2) = 1.0;
uniform float aspect    : hint_range(1.0, 4.0)  = 1.667;
uniform vec4  rim_color : source_color = vec4(0.55, 0.85, 1.0, 1.0); // cool azure rim

const vec3 P_CORE = vec3(1.00, 1.00, 1.00);
const vec3 P_B1   = vec3(1.00, 0.88, 0.45);  // gold
const vec3 P_B2   = vec3(1.00, 0.60, 0.15);  // amber
const vec3 P_B3   = vec3(0.95, 0.35, 0.08);  // deep orange
const vec3 C_AZURE = vec3(0.55, 0.85, 1.00); // sacred cool accent

float easeOut3(float t) { return 1.0 - pow(1.0 - t, 3.0); }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1,0)), f.x),
	           mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), f.x), f.y);
}
float fbm(vec2 p) { float v=0.0; float a=0.5; for(int i=0;i<5;i++){v+=a*noise(p);p*=2.0;a*=0.5;} return v; }

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

	vec2 w = vec2(fbm(uv * 4.0 + vec2(progress * 3.5, 0.0)),
	              fbm(uv * 4.0 + vec2(7.3, progress * 3.8)));
	vec2 fuv = uv + (w - 0.5) * 0.20 * born;

	float bx = head_x - fuv.x;
	float ay = abs(fuv.y);

	vec3  col = vec3(0.0);
	float a   = 0.0;

	// ── Opening slash — normal Flame Slash crescent motion ──────
	{
		float SCALE = 0.55;
		vec2 a_uv = vec2(uv.y, -(uv.x - (LEFT + 0.04))) / SCALE;
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
		col += mix(P_B1, P_CORE, 0.6) * crescent * 1.5;
		a = max(a, crescent * sfade);
	}

	// ── Living-flame phoenix body ───────────────────────────────
	float tail_len = 1.0;
	float t = clamp(bx / tail_len, 0.0, 1.0);
	float flick = fbm(vec2(uv.x * 5.0 - progress * 6.0, uv.y * 6.0));
	float hw = (0.32 * sin(3.14159 * pow(t, 0.55))) * mix(0.78, 1.18, flick);
	float across = ay / max(hw, 1e-3);
	float inr = step(0.0, bx) * step(bx, tail_len);

	float heat = (1.0 - across) * (1.0 - 0.45 * t) * inr;
	vec2 hp = vec2((uv.x - head_x) * 1.3, uv.y);
	float head = exp(-dot(hp, hp) * 34.0);
	heat = max(heat, head * 1.2);
	heat = clamp(heat * born, 0.0, 1.0);

	float body_mask = smoothstep(0.03, 0.12, heat);
	float hb = clamp(heat + 0.16 * (flick - 0.5), 0.0, 1.0);
	col += ramp(hb) * body_mask * 1.5;
	a = max(a, body_mask);

	col += P_CORE * smoothstep(0.80, 0.96, heat) * 1.7;

	// inner azure halo just inside the silhouette (sacred glow)
	float halo = smoothstep(0.60, 0.78, across) * (1.0 - smoothstep(0.80, 0.95, across)) * inr * born;
	col += C_AZURE * halo * 0.9;

	// bold cool azure rim on the silhouette edge (complementary pop)
	float rim = smoothstep(0.82, 0.95, across) * (1.0 - smoothstep(0.95, 1.10, across)) * inr * born;
	col += rim_color.rgb * rim * 2.4;
	a = max(a, rim);

	// ── Impact flash at launch ──────────────────────────────────
	float flash = 1.0 - smoothstep(0.0, 0.12, abs(progress - 0.17));
	vec2 fp = vec2(uv.x - (LEFT + 0.05), uv.y);
	col += mix(P_CORE, C_AZURE, 0.25) * exp(-dot(fp, fp) * 9.0) * flash * 1.3;

	// ── Ember spray ─────────────────────────────────────────────
	vec2 eg = uv * vec2(18.0, 12.0) + vec2(progress * 5.0, 0.0);
	vec2 cell = floor(eg); vec2 lp = fract(eg) - 0.5; float seed = hash(cell);
	float behind = smoothstep(0.0, 0.4, bx) * step(bx, 1.6) * step(ay, 0.44);
	float tw = sin(progress * 6.28318 + seed * 6.28318) * 0.5 + 0.5;
	float ember = step(0.91, seed) * (1.0 - smoothstep(0.0, 0.30, length(lp))) * behind * (0.4 + 0.6 * tw) * born;
	col += mix(P_B1, C_AZURE, 0.25) * ember * 1.7;
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
