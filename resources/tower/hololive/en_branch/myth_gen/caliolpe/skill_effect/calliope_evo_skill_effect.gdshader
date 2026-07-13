shader_type canvas_item;
render_mode blend_premul_alpha;   // premultiplied: the dark void/purple body stays true over the
                                  // bright lit map while the white soul-core still adds.

// ================================================================
// Calliope evolve - "Excuse My Rudeness, But Could You Please RIP?"
// TWO beats, but each is a SEPARATE self-contained visual event driven by its
// own `progress` 0->1 (no inter-beat pause lives here - the 0.5s gap is owned by
// the gameplay AftershockTimer). `phase` picks which beat this instance draws:
//   phase 0 = REAP  : elevated reaper crescent + smoke + magenta ink rim (beat 1).
//   phase 1 = SLASH : elevated cross-slash flurry + closing reap-ring (beat 2).
// Energy-glow look, Director-approved (preview variant 2). No central flash.
//
// `phase` is a runtime UNIFORM (not a #define): one pipeline compile covers both
// beats, so warming this shader via the beat-1 play_effect also warms beat 2.
//
// NOTE: TAU / PI / E are BUILT-IN Godot shader constants - never redeclare them
// (a `const float TAU = ...` collides and fails the whole compile -> white square).
// ================================================================

uniform float progress : hint_range(0.0, 1.0) = 0.0;   // external Tween 0->1, this beat's whole life
uniform float scale_p  : hint_range(0.01, 1.2) = 1.0;  // elastic pop-in
uniform float aspect   : hint_range(1.0, 4.0)  = 1.0;  // square footprint -> 1.0
uniform int   phase    : hint_range(0, 1) = 0;         // 0 reap beat / 1 slash beat
uniform vec4  accent_color : source_color = vec4(0.42, 0.34, 0.98, 1.0);  // cool blue-violet
uniform float ring_radius  : hint_range(0.15, 0.45) = 0.26;
uniform float ring_thick   : hint_range(0.02, 0.12) = 0.052;
uniform float ellipse      : hint_range(1.0, 1.8)   = 1.20;   // Y squash -> ground perspective
uniform float tail_len     : hint_range(1.5, 5.8)   = 4.9;    // bounded-tail arc (< TAU)
uniform float swirl_speed  : hint_range(0.0, 4.0)   = 1.6;
uniform float warp_amt     : hint_range(0.0, 0.15)  = 0.06;
uniform float smoke_amt    : hint_range(0.0, 1.0)   = 0.7;    // reserved-for-evolve haze strength

const vec3 P_CORE = vec3(1.00, 0.93, 0.98);   // white-pink soul core

// Dark reaper palette: near-black void -> deep purple -> dark magenta, bright at the top only.
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
	vec2 ev  = uv * vec2(1.0, ellipse);
	float r   = length(ev);
	float ang = atan(ev.y, ev.x);

	vec3  col = vec3(0.0);
	float a   = 0.0;

	if (phase == 0) {
		// ================= BEAT 1 - REAP (elevated reaper crescent + smoke) =================
		float sweep = clamp(progress / 0.72, 0.0, 1.0);         // crescent sweeps over this beat's life
		float keep0 = 1.0 - smoothstep(0.80, 1.0, progress);    // fade out at the end

		vec2 rev = rot(progress * swirl_speed) * ev;
		vec2 pc  = rev * 3.4;
		float fil = fbm(pc * 1.6 + vec2(0.0, -progress * 2.2));
		float wob = fbm(pc * 1.05 + vec2(progress * 1.1, 0.0)) - 0.5;
		float ringR = ring_radius + wob * warp_amt;

		float start  = -1.9;
		float rel    = mod(ang - start, TAU);
		float front1 = TAU * 1.10 * easeOut2(sweep);
		float behind = mod(front1 - rel, TAU);
		float within = step(behind, tail_len);

		float thick0 = ring_thick * 1.5 * (0.6 + 1.0 * fil);
		float tail_sharp = smoothstep(0.0, 0.55, tail_len - behind);
		float head_taper = smoothstep(0.0, 1.5, behind);
		float tail_f = 0.20 + 0.80 * tail_sharp;
		float thick  = thick0 * min(head_taper, tail_f);
		float band   = abs(r - ringR);
		float ring   = 1.0 - smoothstep(0.0, max(thick, 1e-3), band);

		float crest  = (1.0 - smoothstep(0.0, 0.5, behind)) * within * ring;
		float center = 1.0 - smoothstep(0.0, max(thick, 1e-3) * 0.55, band);
		float core   = center * (1.0 - smoothstep(0.0, 2.5, behind)) * within;
		float hot    = max(crest, core);

		float bright = ring * (0.5 + 0.7 * fil) * within + hot * 1.0;
		float heat   = clamp(0.26 + 0.62 * bright + 0.4 * hot, 0.0, 1.0);
		vec3 c1 = ramp_dark(heat);
		float coolm = smoothstep(0.58, 0.92, fbm(pc * 1.2 + vec2(-progress * 0.8, 4.0)));
		c1 = mix(c1, accent_color.rgb, coolm * 0.55 * ring * within);
		c1 *= bright;
		c1 += P_CORE * hot * 1.2;                               // white soul core (kept - Director)
		float a1 = clamp(max(ring * within, hot), 0.0, 1.0);

		// Smoke / tongue haze spilling OUTSIDE the ring (reserved-for-evolve).
		float sm_f  = fbm(ev * 2.6 + vec2(progress * 0.6, -progress * 1.8));
		float outer = smoothstep(ringR + 0.01, ringR + 0.20, r) * (1.0 - smoothstep(0.30, 0.46, r));
		float smoke = outer * smoothstep(0.42, 0.80, sm_f) * smoke_amt;
		c1 += D_B2 * smoke * 0.9 + accent_color.rgb * smoke * 0.25;
		a1  = max(a1, smoke * 0.55);

		// Elevated additions: magenta ink rim on the crescent edge + a denser flowing smoke layer.
		float rimband = clamp(ring * (1.0 - ring) * 4.0, 0.0, 1.0) * within;
		float sm2 = fbm(ev * 4.2 + vec2(-progress * 1.2, progress * 1.5));
		float smoke2 = outer * smoothstep(0.50, 0.86, sm2) * smoke_amt * 0.7;
		c1 += D_B1 * rimband * 0.9;
		c1 += (D_B1 * 0.5 + accent_color.rgb * 0.6) * smoke2;
		a1  = max(a1, smoke2 * 0.45);

		col = c1 * keep0;
		a   = a1 * keep0;
	} else {
		// ================= BEAT 2 - SLASH (elevated energy cross-slash) =================
		// Hand-choreographed cuts (angle/offset/time authored, not random): opposing
		// diagonals land as pairs, then accents fill in - dun-dun .. dun-dun.
		float ANG[8]  = float[8](1.05, 2.18, 0.26, 1.75, 0.70, 2.62, 1.48, 0.09);  // radians
		float OFFS[8] = float[8](0.10, -0.13, -0.22, 0.18, -0.20, 0.21, -0.06, 0.20); // off-centre
		float CTR[8]  = float[8](0.00, 0.00, 0.05, -0.05, 0.00, 0.00, 0.10, 0.00);  // slide along
		float LEN[8]  = float[8](0.44, 0.44, 0.36, 0.36, 0.34, 0.34, 0.36, 0.34);   // half-length
		float TIM[8]  = float[8](0.00, 0.06, 0.18, 0.24, 0.36, 0.42, 0.54, 0.62);   // strike time

		// Layered per blade: flowing cel colour, magenta ink lip + soul spine, soft aura,
		// motion-blur-to-sharp + a magenta flare as each blade swings in. No central flash.
		vec3  c2 = vec3(0.0);
		float cut = 0.0;
		for (int k = 0; k < 8; k++) {
			vec2 d    = vec2(cos(ANG[k]), sin(ANG[k]));
			vec2 pdir = vec2(-d.y, d.x);
			float along = dot(uv, d) - CTR[k];
			float perp  = dot(uv, pdir) - OFFS[k];
			float t_along = clamp(abs(along) / LEN[k], 0.0, 1.0);
			float taper = pow(1.0 - t_along, 0.8);                    // -> 0 at the tips = sharp points
			float jit   = fbm(vec2(along * 7.0, float(k) * 3.0)) * 0.010;
			float dtk   = (progress - (TIM[k] + 0.03)) / 0.06;
			float pulse = exp(-dtk * dtk);                            // swing-in blur peak -> settles sharp
			float halfw = (0.026 + jit) * taper * (1.0 + 2.4 * pulse);
			float dperp = abs(perp);
			float ap    = smoothstep(TIM[k], TIM[k] + 0.04, progress) * (1.0 - smoothstep(0.80, 1.0, progress));
			float core  = (1.0 - smoothstep(halfw * 0.55, halfw, dperp)) * ap;         // crisp sharp band
			float glow  = exp(-(dperp * dperp) / max(halfw * halfw * 2.2, 1e-6)) * ap; // soft aura
			float across = clamp(dperp / max(halfw, 1e-4), 0.0, 1.0);
			float flown = fbm(vec2(along * 5.0 - progress * 4.5, float(k) * 2.7 + perp * 6.0));
			float h = clamp(0.42 + 0.52 * flown - 0.30 * across, 0.0, 1.0);
			vec3 bc = ramp_dark(h);
			float lip = smoothstep(0.45, 0.82, across) * (1.0 - smoothstep(0.86, 1.04, across));
			bc += D_B1 * lip * 1.3;                                              // magenta ink lip
			bc += D_B1 * pulse * 0.8;                                           // magenta flare as it swings in
			bc += P_CORE * (1.0 - smoothstep(0.0, 0.24, across)) * core * 0.55;  // thin soul spine (on the blade)
			c2 += bc * core * (0.75 + 0.5 * flown);                             // living-energy body
			c2 += ramp_dark(0.55) * glow * 0.35;                               // dim purple aura for depth
			cut = max(cut, max(core, glow * 0.6));
		}
		// Closing reap-ring - perimeter only, never the centre (kept - Director).
		float pr    = mix(0.30, 0.47, easeOut2(clamp((progress - 0.5) / 0.5, 0.0, 1.0)));
		float pring = (1.0 - smoothstep(0.0, 0.018, abs(r - pr))) * smoothstep(0.5, 0.6, progress)
		            * (1.0 - smoothstep(0.9, 1.0, progress));
		c2 += (ramp_dark(0.82) * 0.7 + D_B1 * 0.5) * pring;

		col = c2;
		a   = clamp(max(cut, pring * 0.85), 0.0, 1.0);
	}

	// ---------- shared envelope: pop-in + soft square frame ----------
	float frame  = 1.0 - smoothstep(0.44, 0.50, max(abs(uv.x), abs(uv.y)));
	float appear = smoothstep(0.0, 0.05, progress);
	col *= appear * frame;
	a    = clamp(a * appear * frame, 0.0, 1.0);
	COLOR = vec4(col, a);
}
