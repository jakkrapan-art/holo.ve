shader_type canvas_item;
render_mode blend_premul_alpha;   // premultiplied: the dark void/purple body stays true over the
                                  // bright lit map while the white soul-core still adds
                                  // (Kiara Hinotori lesson).

// ════════════════════════════════════════════════════════════════
// Calliope · "Ricky" (normal) — Reaper's dark-energy crescent (self-centered 3x3).
// A dark void-purple bounded-tail crescent sweeps around Calliope: rounded LEAF
// head, sharp tapered tail, and a long white soul-core streak trailing into the
// body. Self-centered / aura family (no lane helpers). Sweeps in over ~0.68s then
// dissolves. Visual only — damage is the skill's find_multi_enemy 3x3.
//
// NOTE: TAU / PI / E are BUILT-IN Godot shader constants — never redeclare them
// (a `const float TAU = ...` collides with the builtin and fails the whole
//  compile: the effect then falls back to a plain white square).
// ════════════════════════════════════════════════════════════════

uniform float progress : hint_range(0.0, 1.0) = 0.0;   // external Tween 0->1, whole sequence
uniform float scale_p  : hint_range(0.01, 1.2) = 1.0;  // elastic pop-in
uniform float aspect   : hint_range(1.0, 4.0)  = 1.0;  // square footprint -> 1.0
uniform vec4  accent_color : source_color = vec4(0.42, 0.34, 0.98, 1.0);  // cool blue-violet patches
uniform float ring_radius  : hint_range(0.15, 0.45) = 0.25;   // ring sits at the 3x3 edge
uniform float ring_thick   : hint_range(0.02, 0.10) = 0.040;  // base band half-width (x1.5 internally)
uniform float ellipse      : hint_range(1.0, 1.8)   = 1.20;   // Y squash -> ground perspective
uniform float tail_len     : hint_range(1.5, 5.8)   = 4.7;    // bounded-tail arc (radians, < TAU: ends never meet)
uniform float swirl_speed  : hint_range(0.0, 4.0)   = 1.6;    // internal turbulence rotation
uniform float warp_amt     : hint_range(0.0, 0.15)  = 0.06;   // ring-edge wobble

const vec3 P_CORE = vec3(1.00, 0.93, 0.98);   // white-pink soul core

// Dark reaper palette: near-black void body -> deep purple -> dark magenta,
// bright pink/white only at the very top so the soul core still pops.
const vec3 D_CORE = vec3(1.00, 0.90, 0.98);
const vec3 D_B1   = vec3(0.85, 0.30, 0.70);
const vec3 D_B2   = vec3(0.42, 0.10, 0.45);
const vec3 D_B3   = vec3(0.20, 0.05, 0.30);
const vec3 D_B4   = vec3(0.04, 0.01, 0.08);

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1,0)), f.x),
	           mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), f.x), f.y);
}
float fbm(vec2 p) { float v = 0.0; float amp = 0.5; for (int i = 0; i < 5; i++) { v += amp * noise(p); p *= 2.0; amp *= 0.5; } return v; }
float easeOut2(float t) { return 1.0 - (1.0 - t) * (1.0 - t); }
mat2 rot(float a) { float s = sin(a); float c = cos(a); return mat2(vec2(c, -s), vec2(s, c)); }

vec3 ramp_dark(float h) {
	vec3 c = D_B4;
	c = mix(c, D_B3,   step(0.30, h));
	c = mix(c, D_B2,   step(0.55, h));
	c = mix(c, D_B1,   step(0.78, h));
	c = mix(c, D_CORE, step(0.92, h));
	return c;
}

void fragment() {
	vec2 uv  = (UV - 0.5) * vec2(aspect, 1.0) / max(scale_p, 0.01);
	vec2 ev  = uv * vec2(1.0, ellipse);        // elliptical (ground-perspective) space
	float r   = length(ev);
	float ang = atan(ev.y, ev.x);

	// Swirling turbulence field (rotate noise around centre over time).
	vec2 rev = rot(progress * swirl_speed) * ev;
	vec2 pc  = rev * 3.4;
	float fil = fbm(pc * 1.6 + vec2(0.0, -progress * 2.2));
	float wob = fbm(pc * 1.05 + vec2(progress * 1.1, 0.0)) - 0.5;
	float ringR = ring_radius + wob * warp_amt;

	// Bounded-tail sweep: a long crescent whose leading head + trailing tail are
	// held tail_len radians apart (< TAU) so the two tips never meet. Slower sweep.
	float start  = -1.9;
	float rel    = mod(ang - start, TAU);
	float fp1    = clamp(progress / 0.80, 0.0, 1.0);
	float front1 = TAU * 1.10 * easeOut2(fp1);
	float behind = mod(front1 - rel, TAU);
	float within = step(behind, tail_len);

	// TAIL = เรียว sharp point (thickness -> ~0.2). HEAD = rounded leaf point (a
	// gradual thickness taper to zero; smoothstep meets 0 tangentially -> rounded
	// apex, not a needle and not a bulb). Longer head taper = softer/rounder head.
	float thick0 = ring_thick * 1.5 * (0.6 + 1.0 * fil);       // +50% overall thickness
	float tail_sharp = smoothstep(0.0, 0.55, tail_len - behind);
	float head_taper = smoothstep(0.0, 1.5, behind);
	float tail_f = 0.20 + 0.80 * tail_sharp;
	float thick  = thick0 * min(head_taper, tail_f);
	float band   = abs(r - ringR);
	float ring   = 1.0 - smoothstep(0.0, max(thick, 1e-3), band);
	float arc    = within;

	// Leading brightness follows the leaf tip; long white soul-core streak trails
	// back along the crescent body (the "tongue").
	float crest  = (1.0 - smoothstep(0.0, 0.5, behind)) * within * ring;
	float center = 1.0 - smoothstep(0.0, max(thick, 1e-3) * 0.55, band);
	float core   = center * (1.0 - smoothstep(0.0, 2.5, behind)) * within;
	float hot    = max(crest, core);

	// Deep reaper colour (ramp_dark), full opacity, white soul core on top.
	float bright = ring * (0.5 + 0.7 * fil) * arc + hot * 1.0;
	float heat   = clamp(0.26 + 0.62 * bright + 0.4 * hot, 0.0, 1.0);
	vec3 col = ramp_dark(heat);
	float coolm = smoothstep(0.58, 0.92, fbm(pc * 1.2 + vec2(-progress * 0.8, 4.0)));
	col = mix(col, accent_color.rgb, coolm * 0.55 * ring * arc);
	col *= bright;
	col += P_CORE * hot * 1.2;

	float a = clamp(max(ring * arc, hot), 0.0, 1.0);

	// Envelope: pop-in, soft pad-edge frame, fade-out.
	float frame  = 1.0 - smoothstep(0.42, 0.49, length(uv));
	float appear = smoothstep(0.0, 0.05, progress);
	float keep   = 1.0 - smoothstep(0.82, 1.0, progress);
	col *= appear * keep * frame;
	a    = clamp(a * appear * keep * frame, 0.0, 1.0);
	COLOR = vec4(col, a);
}
