shader_type canvas_item;
render_mode blend_premul_alpha;

#include "res://resources/tower/shared/lane_fx.gdshaderinc"

// Josuiji Shinri "Heartpierce Shot" crit pierce-arrow VFX - EVOLVE tier.
// Seamless pink COMET core (cel bands + living fbm warp) + braided light FILAMENTS tied to a
// binding KNOT at the front tip + scattered sparkle/heart charm dots that linger past the bolt.
// Premultiplied so the saturated pink/magenta survives over a lit map (Kiara Hinotori technique).
// Lane-static: head travels via `progress`; the lingering particles run on `life_t` (longer clock).
// Driven by progress / life_t / scale_p, never internal TIME.

uniform float progress  : hint_range(0.0, 1.0) = 0.0;
uniform float life_t     : hint_range(0.0, 1.0) = 0.0;   // full-cycle clock (dots/hearts linger after the bolt)
uniform float shot_frac  : hint_range(0.05, 1.0) = 0.55; // travel_dur / total_dur (life_t value when the bolt ends)
uniform float scale_p    : hint_range(0.01, 1.2) = 1.0;
uniform float lane_pad   : hint_range(0.0, 0.5) = 0.25;  // must match the controller LANE_PAD

uniform float head_r       : hint_range(0.01, 0.12) = 0.030;
uniform float tail_len     : hint_range(0.10, 1.20) = 0.50;
uniform float beam_width   : hint_range(0.008, 0.12) = 0.035;
uniform float intensity    : hint_range(0.0, 2.5)   = 1.1;
uniform float spark_amount : hint_range(0.0, 1.5)   = 0.6;
uniform float origin_soft  : hint_range(0.0, 0.30)  = 0.08;   // soft tail fade at the lane origin (was a hard scissor at the tower)

const float XR = 2.5;   // x-unit px / y-unit px -> isotropic hearts/knot
const vec3 PCORE = vec3(1.00, 0.99, 0.97);
const vec3 CHARM = vec3(1.00, 0.40, 0.66);

float hash11(float x){ return fract(sin(x * 127.1) * 43758.5453); }
float hash21(vec2 p){ return fract(sin(dot(p, vec2(41.3, 289.1))) * 43758.5453); }
float headx_at(float p){ return smoothstep(0.08, 0.95, p) * (1.0 + lane_pad * 0.35); }

float vnoise(vec2 p){
	vec2 i = floor(p); vec2 f = fract(p);
	float a = hash21(i), b = hash21(i + vec2(1.0, 0.0)), c = hash21(i + vec2(0.0, 1.0)), d = hash21(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
float fbm(vec2 p){ float s = 0.0, a = 0.5; for (int i = 0; i < 3; i++){ s += a * vnoise(p); p *= 2.0; a *= 0.5; } return s; }

vec3 cel_rose(float t){
	t = clamp(t, 0.0, 1.0);
	if (t < 0.16) return vec3(1.00, 0.98, 0.96);
	if (t < 0.42) return vec3(1.00, 0.72, 0.86);
	if (t < 0.70) return vec3(1.00, 0.40, 0.62);
	return vec3(0.88, 0.22, 0.58);
}

vec4 over(vec4 d, vec4 s){
	float a = s.a + d.a * (1.0 - s.a);
	vec3 rgb = (s.rgb * s.a + d.rgb * d.a * (1.0 - s.a)) / max(a, 1e-4);
	return vec4(rgb, a);
}

float heart(vec2 d, float s){
	vec2 p = d / max(s, 1e-4);
	float a = dot(p, p) - 1.0;
	float h = a * a * a - p.x * p.x * p.y * p.y * p.y;
	return 1.0 - smoothstep(-0.4, 0.5, h);
}

void fragment(){
	vec2 lc = lane_coord(UV, lane_pad);
	float x = lc.x;
	float y = lc.y;

	float hr = max(head_r, 1e-3)    * 1.55;
	float bw = max(beam_width, 1e-3)* 1.40;
	float L  = max(tail_len, 1e-3)  * 1.40;

	float head_x = headx_at(progress);
	float launch = smoothstep(0.0, 0.10, progress);
	float bolt_life = 1.0 - smoothstep(0.88, 1.0, progress);
	float pop = mix(0.6, 1.0, smoothstep(0.0, 0.55, clamp(scale_p, 0.01, 1.2)));
	float tower_gate = lane_origin_gate(x, origin_soft);   // soft fade-in at the lane origin (shared helper)

	float dx = head_x - x;
	float tt = clamp(dx / L, 0.0, 1.0);
	float along = tt;
	float born = launch * pop;
	float warp = (fbm(vec2(x * 7.0 - progress * 3.5, y * 9.0 + progress * 1.5)) - 0.5) * 0.30;

	vec4 acc = vec4(0.0);

	// ===== seamless comet core (head orb + tail that ramps from under the head) =====
	float head_d = length(vec2(dx / hr, y / bw));
	float head = exp(-head_d * head_d) * born * bolt_life;
	acc = over(acc, vec4(cel_rose(smoothstep(0.20, 1.0, head_d) + warp), head * 0.95));

	float tgate = smoothstep(0.0, hr * 2.0, dx) * step(dx, L) * step(0.0, x);
	float tw = bw * (1.0 - 0.70 * tt);
	float tail = exp(-(y * y) / (2.0 * max(tw, 1e-4) * max(tw, 1e-4))) * pow(1.0 - tt, 1.35) * tgate * born * bolt_life;
	acc = over(acc, vec4(cel_rose(0.30 + 0.55 * tt + warp), tail * 0.92));

	float inner = exp(-head_d * head_d * 2.4) * born * bolt_life;
	acc = over(acc, vec4(PCORE, inner * 0.6));
	float flash = exp(-(dx * dx) / (2.0 * (hr * 1.6) * (hr * 1.6)))
			* exp(-(y * y) / (2.0 * (bw * 1.6) * (bw * 1.6))) * (1.0 - smoothstep(0.0, 0.18, progress));
	acc = over(acc, vec4(PCORE, flash * 0.7 * tower_gate));

	// ===== braided light filaments tied to a binding KNOT at the front tip, fanning down the body =====
	{
		float front = smoothstep(-hr * 0.2, hr * 0.6, dx);
		float fbody = front * step(dx, L) * step(0.0, x) * born * bolt_life;
		float fw = bw * 0.18;
		float tie_dx = -hr * 0.7;                  // tie point at the very FRONT tip, ahead of centre
		float fil = 0.0;
		for (int i = 0; i < 4; i++){
			float fi = float(i);
			float amp = bw * (1.3 + fi * 0.45) * 0.85;   // moderate fan (not too wide)
			float freq = 6.0 + fi * 2.5;
			float phase = fi * 1.9 + progress * 5.0 + hash11(fi * 3.1) * 6.2831;
			float conv = smoothstep(0.0, hr * 1.3, dx - tie_dx);   // converge to the front-tip tie point
			float cy = amp * conv * sin(along * freq + phase);
			float d = (y - cy) / fw;
			fil = max(fil, exp(-d * d) * pow(1.0 - along, 1.1));
		}
		acc = over(acc, vec4(cel_rose(0.22), fil * fbody * 0.95));

		// bright binding node - the single tie point at the very front tip
		float node = exp(-((dx - tie_dx) * (dx - tie_dx)) / (2.0 * (hr * 0.42) * (hr * 0.42)))
				* exp(-(y * y) / (2.0 * (bw * 0.36) * (bw * 0.36))) * born * bolt_life;
		acc = over(acc, vec4(mix(PCORE, CHARM, 0.25), node * 0.95 * tower_gate));
	}

	// ===== charm particles: scattered sparkle DOTS + ~1/3 hearts, twinkle, linger past the bolt =====
	for (int i = 0; i < 10; i++){
		float fi = float(i);
		float s1 = hash11(fi * 5.3 + 0.2);
		float s2 = hash11(fi * 9.1 + 1.7);
		float s3 = hash11(fi * 3.7 + 4.1);
		float pe_prog = 0.05 + s1 * 0.90;
		float emT = pe_prog * shot_frac;
		float local = life_t - emT;
		float app = smoothstep(0.0, 0.04, local);
		float linger = 1.0 - smoothstep(0.74, 1.0, life_t);
		float k = clamp(local / 0.9, 0.0, 1.0);
		float emX = headx_at(pe_prog);
		float sx = emX - 0.05 * local;
		float sy = (s2 - 0.5) * bw * 4.0 + (s3 - 0.5) * bw * 2.0 * k;   // scattered around the trail
		float tw = 0.30 + 0.70 * (0.5 + 0.5 * sin(life_t * 20.0 + s1 * 30.0));   // twinkle
		float dot;
		if (s3 < 0.32) {
			dot = heart(vec2((x - sx) * XR, y - sy), bw * 0.5 * (1.0 - 0.3 * k));   // charm hearts
		} else {
			float dd = length(vec2((x - sx) * XR, y - sy));
			dot = exp(-(dd * dd) / (2.0 * (bw * 0.16) * (bw * 0.16)));              // round sparkle
		}
		acc = over(acc, vec4(mix(PCORE, CHARM, s3), dot * app * linger * tw * step(0.0, x) * spark_amount));
	}

	acc.rgb *= intensity * 1.30;
	float a = clamp(acc.a, 0.0, 1.0) * tower_gate;
	COLOR = vec4(acc.rgb * a, a);
}
