shader_type canvas_item;
render_mode blend_premul_alpha;   // dark body must survive the lit map
                                  // (Hinotori lesson)

// ================================================================
// Banzoin Hakka · "Obey my omen, in hymns allure" (EVOLVE) —
// "Burning Sutra" (E3c, Director-approved 2026-07-18, 4 design rounds).
// The FIELD-family evolve zone: a roaring cyclone of value-INVERTED
// black flame (near-black body, brightness only at the tongue lips)
// over the 5x5 ward, garnished with the exorcist's rite —
//   - GARNISH: white glowing juzu prayer beads counting the perimeter
//     + white script columns ("in hymns allure") rising and charring
//     away as they climb. Crow feathers ride the storm.
//   - COLOUR (round-3 verdict): smooth value-inverted ramp (cel bands
//     were TRIED AND REJECTED for Hakka), refined by colour theory —
//     analogous hue FLOW indigo -> violet -> hot-pink (#ff06c2) bridge
//     -> lavender -> white lip (no dead jumps), faint warm ember in the
//     depths for richness.
//   - REFUND BEAT: on NATURAL expiry only, the ward overloads — beads
//     flash/snap, script is sung skyward, ONE white feather rises. This
//     is gated by `refund_beat` (see below), NOT by `expire` alone.
//
// LAYER model (drawn twice by the controller): fx_layer 0 = flame sea +
// beads (ground, under enemies), 1 = script columns + rising feather
// (front, above towers/enemies).
//
// refund_beat: `expire` sweeps on BOTH exit paths (natural AND wave-end
// cancel). The refund is granted only on natural expiry, so the
// controller forces refund_beat=0 on cancel — the celebratory beat
// (overload, skyward accel, feather) then plays ONLY when Energy is
// actually refunded. Default 1.0 keeps the natural path faithful.
//
// NOTE: TAU / PI / E are BUILT-IN Godot shader constants — never
// redeclare (a `const float TAU = ...` collides with the builtin and
// fails the whole compile: the effect falls back to a plain white
// square, no crash — check the Output panel if the zone renders blank).
// ================================================================

uniform int   fx_layer   = 0;
uniform float plant      : hint_range(0.0, 1.0) = 1.0;
uniform float loop_time  = 0.0;
uniform float expire     : hint_range(0.0, 1.0) = 0.0;
uniform float refund_beat : hint_range(0.0, 1.0) = 1.0; // 1 = natural expiry (play refund beat), 0 = cancel
uniform float scale_p    : hint_range(0.01, 1.2) = 1.0;
uniform float aspect     : hint_range(1.0, 4.0) = 1.0;

uniform vec4 black_color    : source_color = vec4(0.05, 0.02, 0.09, 1.0);
uniform vec4 deep_color     : source_color = vec4(0.22, 0.08, 0.40, 1.0);
uniform vec4 violet_color   : source_color = vec4(0.56, 0.36, 0.94, 1.0); // Hakka DNA
uniform vec4 lavender_color : source_color = vec4(0.80, 0.64, 1.00, 1.0);
uniform vec4 white_color    : source_color = vec4(1.00, 0.97, 1.00, 1.0);
uniform vec4 seal_color     : source_color = vec4(0.85, 0.16, 0.22, 1.0);
uniform vec4 ember_color    : source_color = vec4(0.48, 0.08, 0.12, 1.0); // smoulder depths
uniform vec4 teal_color     : source_color = vec4(0.55, 0.95, 0.92, 1.0); // gem glint
uniform vec4 pink_color     : source_color = vec4(1.00, 0.02, 0.76, 1.0); // #ff06c2 hot-pink accent (Director sample)

uniform float ring_radius : hint_range(0.2, 0.5) = 0.425;
uniform float ellipse     : hint_range(1.0, 1.8) = 1.22;
uniform float storm_speed : hint_range(0.0, 2.0) = 0.55;
uniform float pool_alpha  : hint_range(0.0, 1.0) = 0.62;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x),
	           mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) { float v = 0.0; float amp = 0.5; for (int i = 0; i < 4; i++) { v += amp * noise(p); p *= 2.0; amp *= 0.5; } return v; }
// ridged fbm: sharp creases - the metal-jagged flame-tongue profile (rock register)
float rfbm(vec2 p) {
	float v = 0.0; float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		v += amp * (1.0 - abs(2.0 * noise(p) - 1.0));
		p *= 2.1; amp *= 0.5;
	}
	return v;
}
mat2 rot(float a) { float s = sin(a); float c = cos(a); return mat2(vec2(c, -s), vec2(s, c)); }
float ease_out3(float t) { return 1.0 - pow(1.0 - t, 3.0); }

// Smooth value-INVERTED flame ramp (NOT cel-quantized — cel bands were dropped
// round 2 for Hakka). h = flame intensity; smoulder = warm ember undertone in
// the darkest band only. Analogous hue flow with a #ff06c2 pink bridge; clean
// near-white lip at the crests.
vec3 flame_ramp(float h, float smoulder) {
	vec3 c = mix(black_color.rgb, ember_color.rgb * 0.55, smoulder * (1.0 - smoothstep(0.40, 0.55, h)));
	c = mix(c, deep_color.rgb,     smoothstep(0.45, 0.60, h) - smoothstep(0.72, 0.84, h));
	c = mix(c, violet_color.rgb,   smoothstep(0.72, 0.84, h) - smoothstep(0.90, 0.96, h));
	c = mix(c, pink_color.rgb, smoothstep(0.84, 0.92, h) - smoothstep(0.94, 0.98, h)); // hot-pink bridge (#ff06c2)
	c = mix(c, lavender_color.rgb, smoothstep(0.90, 0.96, h));
	c += white_color.rgb * smoothstep(0.965, 1.0, h) * 0.8;
	return c;
}

// feather: leaf silhouette with rachis, local frame (+y = tip)
vec2 feather_mask(vec2 lp, vec2 hs) {
	float t = clamp(lp.y / hs.y * 0.5 + 0.5, 0.0, 1.0);
	float w = hs.x * (smoothstep(0.0, 0.30, t) - smoothstep(0.30, 1.0, t) * 0.75);
	float body = (1.0 - smoothstep(w * 0.7, max(w, 1e-4), abs(lp.x))) * step(abs(lp.y), hs.y);
	float rachis = (1.0 - smoothstep(0.0008, 0.0022, abs(lp.x))) * body;
	return vec2(body, rachis);
}

// pseudo-kanji column: stacked dashes of varying width in a narrow frame.
// Returns glyph mask; seedv varies the "characters" per column.
float script_column(vec2 lp, vec2 hs, float seedv) {
	float frame_m = step(abs(lp.x), hs.x) * step(abs(lp.y), hs.y);
	float row = floor((lp.y / hs.y * 0.5 + 0.5) * 6.0);
	float rw = 0.35 + 0.65 * hash(vec2(row, seedv));                // per-row width
	float dash = step(abs(lp.x), hs.x * rw);
	float gap = step(0.25, fract((lp.y / hs.y * 0.5 + 0.5) * 6.0)); // row separation
	return frame_m * dash * gap;
}

void fragment() {
	vec2 uv = (UV - 0.5) * vec2(aspect, 1.0) / max(scale_p, 0.01);
	vec2 ev = uv * vec2(1.0, ellipse);
	float r = length(ev);
	float ang = atan(ev.y, ev.x);

	float pe = ease_out3(plant);
	float xe = ease_out3(expire);
	float tighten = 1.0 - 0.6 * smoothstep(0.0, 0.6, xe);
	float rad_live = ring_radius * tighten;
	float disc = 1.0 - smoothstep(rad_live * 0.66, rad_live * 0.96, r);
	float live = pe * (1.0 - smoothstep(0.45, 0.75, xe));

	vec3 col = vec3(0.0);
	float a = 0.0;

	// spin ramps UP as the ward dies — but the skyward accel is a REFUND beat,
	// so gate the accel term with refund_beat (base spin unchanged on cancel).
	float spin = loop_time * storm_speed * (1.0 + 1.5 * smoothstep(0.0, 0.6, xe) * refund_beat);
	// refund overload: beads flash + snap — natural expiry only.
	float overload = smoothstep(0.15, 0.45, xe) * (1.0 - smoothstep(0.5, 0.75, xe)) * refund_beat;

	if (fx_layer == 0) {
		// ---------- flame sea: E3 cyclone motion, smooth value-inverted ramp ----------
		vec2 sv = rot(spin + r * 5.5) * ev;
		float warp = fbm(sv * 2.6 + vec2(loop_time * 0.20, -loop_time * 0.14));
		float ridge = rfbm(sv * 3.2 + warp * 1.3 + vec2(0.0, -loop_time * 0.5));
		float erupt = 1.0 + 0.8 * pow(1.0 - pe, 1.5);
		float h = clamp(ridge * 1.15 * erupt, 0.0, 1.0) * disc;

		float smoulder = (0.35 + 0.30 * sin(loop_time * 0.7 + r * 7.0))
		               * smoothstep(0.3, 0.7, warp);
		vec3 fc = flame_ramp(h, smoulder);

		float sea = disc * live * (pool_alpha + 0.30 * ridge);
		col += fc * sea;
		a = sea;

		// perimeter flame wall: tongues thrown outward past the rim
		float wall = rfbm(vec2(ang * 3.0 - spin * 0.8, r * 7.0 - loop_time * 1.6));
		float wzone = smoothstep(rad_live * 0.85, rad_live * 1.0, r)
		            * (1.0 - smoothstep(rad_live * 1.0, rad_live * 1.24, r));
		float tongues = wzone * smoothstep(0.55, 0.9, wall) * live;
		col += mix(black_color.rgb, violet_color.rgb, wall * wall) * tongues;
		col += lavender_color.rgb * smoothstep(0.88, 0.98, wall) * wzone * live * 0.6;
		a = max(a, tongues * 0.9);

		// ---------- GARNISH half 1: juzu prayer-bead ring, slow count ----------
		// White + glow halo, at the perimeter radius so they read as the boundary
		// over the dark wall tongues (Director round-3 fix).
		float rr = rad_live * 0.98;
		float bead_ring = 0.0;
		float bead_glow = 0.0;
		float bead_hi = 0.0;
		float bead_th = -loop_time * 0.12 - overload * 2.0;         // refund: snaps around
		for (int i = 0; i < 14; i++) {
			float fi = float(i);
			float th = bead_th + fi * TAU / 14.0;
			vec2 bp = vec2(cos(th), sin(th)) * rr;
			float d = length(ev - bp);
			float bead = 1.0 - smoothstep(0.012, 0.017, d);   // x2 size (Director round 4)
			bead_ring = max(bead_ring, bead);
			bead_glow = max(bead_glow, pow(max(0.0, 1.0 - d / 0.048), 2.0));
			// one "mother bead" counts: brightest where the count is now
			float lead = exp(-mod(fi * TAU / 14.0 - loop_time * 0.5, TAU) * 2.0);
			bead_hi = max(bead_hi, bead * lead);
		}
		float cord = 1.0 - smoothstep(0.0012, 0.0028, abs(r - rr));
		col = mix(col, white_color.rgb, max(bead_ring, cord * 0.45) * live);
		col += lavender_color.rgb * bead_glow * live * 0.75;        // bright halo
		col += white_color.rgb * bead_hi * live * 0.9;              // counting pulse
		col += white_color.rgb * bead_ring * overload;              // refund flash
		a = max(a, max(max(bead_ring, bead_glow * 0.6), cord * 0.5) * live);

		// plant stamp: crimson seal flash (exorcist identity)
		float flash = pow(1.0 - pe, 2.0);
		float snap = flash * pow(max(0.0, 1.0 - r / 0.16), 2.0);
		col += seal_color.rgb * snap * 0.9 + white_color.rgb * snap * snap * 0.6;
		a = max(a, snap);
	} else {
		// ---------- GARNISH half 2: rising script columns (front) ----------
		// rise accel ("sung skyward") is a REFUND beat — gate with refund_beat.
		float rise_speed = 1.0 + 3.0 * smoothstep(0.15, 0.5, xe) * refund_beat;
		vec3 scol = vec3(0.0);
		float sa2 = 0.0;
		for (int i = 0; i < 5; i++) {
			float fi = float(i);
			float cyc = fract(loop_time * (0.16 + 0.05 * hash(vec2(fi, 5.1))) * rise_speed + fi * 0.21);
			float th = fi * 2.51 + hash(vec2(fi, 3.7)) * TAU + loop_time * 0.10;
			float rad = rad_live * (0.35 + 0.35 * hash(vec2(fi, 9.9)));
			vec2 base = vec2(cos(th), sin(th)) * rad;
			vec2 gp = base + vec2(0.012 * sin(loop_time * 1.1 + fi), -cyc * 0.16); // climbs
			vec2 lp = ev - gp;
			float glyph = script_column(lp, vec2(0.0075, 0.036), fi * 7.0 + floor(cyc * 3.0));
			float lifef = sin(cyc * PI);                            // fade in, burn out high
			float burn = smoothstep(0.55, 1.0, cyc);                // chars away as it climbs
			// WHITE script with a soft glow halo behind each column
			float halo = pow(max(0.0, 1.0 - length(lp) / 0.055), 2.0);
			scol = mix(scol, white_color.rgb, glyph * lifef);
			scol += lavender_color.rgb * halo * lifef * 0.7;
			sa2 = max(sa2, max(glyph, halo * 0.55) * lifef * (1.0 - burn * 0.4));
		}
		sa2 *= pe * (1.0 - smoothstep(0.5, 0.7, xe));
		col = mix(col, scol, min(sa2, 1.0) * 0.95);
		a = max(a, sa2 * 0.9);

		// ---------- REFUND signature: ONE white feather rises (front) ----------
		// Gated by refund_beat so it plays ONLY on natural expiry (= refund).
		if (expire > 0.0) {
			float ft = smoothstep(0.45, 1.0, xe);
			vec2 fp = ev - vec2(0.0, 0.02 - ft * 0.14);
			vec2 lp = rot(0.25 * sin(ft * 6.0)) * fp;
			vec2 fm = feather_mask(lp, vec2(0.016, 0.052));
			float fglow = pow(max(0.0, 1.0 - length(fp) / 0.10), 2.0);
			float fa = ft * (1.0 - smoothstep(0.92, 1.0, xe)) * refund_beat;
			col += white_color.rgb * fm.x * fa * 1.1;
			col += violet_color.rgb * fm.y * fa * 0.7;
			col += lavender_color.rgb * fglow * fa * 0.6;
			a = max(a, max(fm.x, fglow * 0.6) * fa);
		}
	}

	// ---------- spark flecks off the crests: both layers, split ----------
	float spark = 0.0;
	for (int i = 0; i < 8; i++) {
		float fi = float(i);
		if (int(mod(fi, 2.0)) != fx_layer) { continue; }
		float cyc = fract(loop_time * (0.55 + 0.35 * hash(vec2(fi, 6.1))) + fi * 0.13);
		float sa = hash(vec2(fi, 2.9)) * TAU + loop_time * storm_speed * 0.8;
		float sr = rad_live * (0.45 + 0.45 * hash(vec2(fi, 7.7)) + cyc * 0.25);
		vec2 sp2 = vec2(cos(sa), sin(sa)) * sr;
		float g = pow(max(0.0, 1.0 - length(ev - sp2) / 0.013), 2.0) * sin(cyc * PI);
		spark = max(spark, g);
	}
	spark *= live;
	col += mix(white_color.rgb, lavender_color.rgb, 0.4) * spark * 0.9;
	a = max(a, spark * 0.8);

	// ---------- feathers riding the storm + teal rachis glint ----------
	float fglow2 = 0.0;
	vec3 fcol = vec3(0.0);
	for (int i = 0; i < 10; i++) {
		float fi = float(i);
		if (int(mod(fi, 2.0)) != fx_layer) { continue; }
		float ph = fi * 2.4 + hash(vec2(fi, 8.8)) * TAU;
		float sp = loop_time * (0.5 + 0.35 * hash(vec2(fi, 4.4))) + ph;
		float rad = rad_live * (0.30 + 0.55 * (0.5 + 0.5 * sin(loop_time * 0.35 + ph)));
		vec2 gp = vec2(cos(sp), sin(sp)) * rad;
		float spin2 = loop_time * (2.0 + hash(vec2(fi, 5.5))) + fi;
		vec2 lp = rot(spin2) * (ev - gp);
		vec2 fm = feather_mask(lp, vec2(0.010, 0.028));
		fcol = mix(fcol, black_color.rgb, fm.x);
		float glint = 0.4 + 0.4 * sin(spin2 * 1.7);        // iridescence turns with the feather
		fcol += mix(lavender_color.rgb, teal_color.rgb, glint) * fm.y * 0.8;
		fglow2 = max(fglow2, fm.x);
	}
	fglow2 *= disc * live;
	col = mix(col, fcol, min(fglow2, 1.0) * 0.85);
	a = max(a, fglow2 * 0.85);

	float frame = 1.0 - smoothstep(0.47, 0.499, length(uv));
	col *= frame;
	a = clamp(a * frame, 0.0, 1.0);
	COLOR = vec4(col, a);
}
