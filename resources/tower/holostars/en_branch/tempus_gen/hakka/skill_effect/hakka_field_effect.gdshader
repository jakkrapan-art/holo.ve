shader_type canvas_item;
render_mode blend_premul_alpha;   // dark pool must survive the lit map
                                  // (docs/shader.md Section 3, Hinotori lesson)

// ================================================================
// Banzoin Hakka · "Exocirst Field" (normal) — persistent purifying zone.
// First FIELD-family skill VFX (persistent ground zone): 7 white ofuda
// talismans orbit the boundary (fan out on plant, fly back to his hand
// on expire) with violet ribbon trails, over a CONTINUOUS spirit-vortex
// pool (spiral smoke drawn toward the exorcist - no interval flicker,
// Karthus Defile reference) with teal soul fireflies drifting up.
// Drawn TWICE by the controller (digital-paint layers): fx_layer 0 =
// the whole zone behind the tower, fx_layer 1 = front-assigned
// fireflies only. Ofuda anatomy: paper strip, ink script dashes,
// crimson seal, gold end-band.
//
// NOTE: TAU / PI are BUILT-IN Godot shader constants — never redeclare
// (a `const float TAU = ...` collides with the builtin and fails the
//  whole compile: the effect then falls back to a plain white square).
// ================================================================

uniform int   fx_layer   = 0;                            // 0 base zone, 1 front fireflies
uniform float plant      : hint_range(0.0, 1.0) = 1.0;  // stamp-down beat, 0->1
uniform float loop_time  = 0.0;                          // seconds, game-time (controller delta)
uniform float expire     : hint_range(0.0, 1.0) = 0.0;  // end-of-life fade, 0->1
uniform float scale_p    : hint_range(0.01, 1.2) = 1.0; // plant pop
uniform float aspect     : hint_range(1.0, 4.0) = 1.0;  // square footprint

uniform vec4 body_color  : source_color = vec4(0.56, 0.36, 0.94, 1.0); // Hakka violet
uniform vec4 ink_color   : source_color = vec4(0.12, 0.06, 0.22, 1.0); // script near-black
uniform vec4 paper_color : source_color = vec4(0.98, 0.97, 1.00, 1.0);
uniform vec4 gold_color  : source_color = vec4(1.00, 0.84, 0.42, 1.0);
uniform vec4 seal_color  : source_color = vec4(0.85, 0.16, 0.22, 1.0); // crimson stamp
uniform vec4 deep_color  : source_color = vec4(0.13, 0.06, 0.26, 1.0);
uniform vec4 soul_color  : source_color = vec4(0.55, 0.95, 0.92, 1.0); // firefly teal (his gem)
// 0.425 = +25% over the inscribed 0.34 (Director 2026-07-18): the circular
// zone in the SQUARE 3x3 hitbox left corner gaps where enemies took damage
// while looking outside the circle - the ring now overshoots the box's flat
// edges slightly to shrink the corner gap to an accepted level. Visual frame
// may exceed the code-side AOE (shader.md house rule).
uniform float ring_radius : hint_range(0.2, 0.5) = 0.425;
uniform float ellipse     : hint_range(1.0, 1.8)  = 1.22; // ground perspective
uniform float orbit_speed : hint_range(0.0, 2.0)  = 0.55;
uniform float pool_alpha  : hint_range(0.0, 1.0)  = 0.42;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x),
	           mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) { float v = 0.0; float amp = 0.5; for (int i = 0; i < 4; i++) { v += amp * noise(p); p *= 2.0; amp *= 0.5; } return v; }
mat2 rot(float a) { float s = sin(a); float c = cos(a); return mat2(vec2(c, -s), vec2(s, c)); }
float ease_out3(float t) { return 1.0 - pow(1.0 - t, 3.0); }

float rect_sdf(vec2 p, vec2 hs) {
	vec2 d = abs(p) - hs;
	return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0);
}

// Talisman anatomy in card-local space (long axis = y, half-size hs).
// Returns: x = paper, y = ink script dashes, z = crimson seal, w = gold band.
vec4 ofuda_masks(vec2 lp, vec2 hs) {
	float paper = 1.0 - smoothstep(0.0, 0.006, rect_sdf(lp, hs));
	float col_m = 1.0 - smoothstep(0.0035, 0.0055, abs(lp.x));
	float in_body = step(abs(lp.y), hs.y * 0.55);
	float dash = step(0.38, fract((lp.y / hs.y) * 5.5));
	float ink = col_m * in_body * dash * paper;
	float seal = 1.0 - smoothstep(0.0, 0.004, rect_sdf(lp - vec2(0.0, hs.y * 0.72), vec2(0.0050, 0.0050)));
	float band = 1.0 - smoothstep(0.0, 0.004, rect_sdf(lp + vec2(0.0, hs.y * 0.92), vec2(hs.x, 0.0045)));
	return vec4(paper, ink, seal * paper, band);
}

void fragment() {
	vec2 uv = (UV - 0.5) * vec2(aspect, 1.0) / max(scale_p, 0.01);
	vec2 ev = uv * vec2(1.0, ellipse);
	float r = length(ev);
	float ang = atan(ev.y, ev.x);

	float pe = ease_out3(plant);
	float xe = ease_out3(expire);
	float disc = 1.0 - smoothstep(ring_radius * 0.70, ring_radius * 0.96, r);

	vec3 col = vec3(0.0);
	float a = 0.0;

	if (fx_layer == 0) {
		// ---------- base zone: everything behind the tower ----------
		float orbit = loop_time * orbit_speed * TAU * 0.16 + (1.0 - pe) * 2.6;
		float rad_f = ring_radius * pe * (1.0 - xe);   // fan out / fly back home

		vec4 om = vec4(0.0);
		float trail = 0.0;
		for (int i = 0; i < 7; i++) {
			float fi = float(i);
			float th = orbit + fi * TAU / 7.0;
			float bob = 0.010 * sin(loop_time * 2.2 + fi * 1.7);
			vec2 c = vec2(cos(th), sin(th)) * (rad_f + bob);
			vec2 lp = rot(-(th + PI * 0.5)) * (ev - c);   // card local, tangential
			om = max(om, ofuda_masks(lp, vec2(0.013, 0.046)));
			float behind = mod(th - ang, TAU);
			trail = max(trail, exp(-behind * 3.2));
		}

		float band = 1.0 - smoothstep(0.0, 0.014, abs(r - rad_f));
		float ring_a = band * (0.20 + 0.55 * trail) * step(0.05, rad_f);

		// SPIRIT VORTEX pool: spiral shear (twist grows toward center) +
		// faint rings crawling inward - souls drawn to the exorcist.
		// Continuous living territory, no interval flicker.
		vec2 pv = rot(loop_time * 0.30 + r * 6.5) * ev;
		float warp = fbm(pv * 3.0 + vec2(loop_time * 0.12, -loop_time * 0.07));
		float sm = fbm(pv * 2.6 + warp * 0.9);
		float inflow = 0.5 + 0.5 * sin(r * 34.0 + loop_time * 1.9);
		sm += smoothstep(0.55, 0.95, inflow) * 0.18;
		float pool_hi = smoothstep(0.60, 0.84, sm) * disc;
		float pool = disc * pe * (1.0 - xe) * (pool_alpha + 0.26 * sm);

		// plant beat: a snap flash at Hakka's hand as the fan opens
		float flash = pow(1.0 - pe, 2.0);
		float snap = flash * pow(max(0.0, 1.0 - r / 0.14), 2.0);

		col = deep_color.rgb * pool
		    + body_color.rgb * (ring_a + pool * 0.55 * sm + pool_hi * 0.28)
		    + paper_color.rgb * om.x * 0.95
		    + gold_color.rgb * om.w * 0.95
		    + seal_color.rgb * om.z * 0.95
		    + paper_color.rgb * snap * 0.8;
		col += (ink_color.rgb - paper_color.rgb) * om.y * 0.85; // ink prints ON paper
		a = max(max(om.x * 0.95, ring_a), max(pool + pool_hi * 0.20, snap));
	}

	// ---------- fireflies: on BOTH layers, split per particle ----------
	float glow = 0.0;
	for (int i = 0; i < 8; i++) {
		float fi = float(i);
		if (int(mod(fi, 2.0)) != fx_layer) { continue; }  // even = back, odd = front
		float cyc = fract(loop_time * (0.07 + 0.03 * hash(vec2(fi, 1.7))) + fi * 0.23);
		vec2 gp = vec2(
			(hash(vec2(fi, 3.1)) - 0.5) * ring_radius * 1.6
				+ 0.05 * sin(loop_time * 0.7 + fi * 2.2),
			(0.55 - cyc) * ring_radius * 1.5
		);
		float twinkle = 0.55 + 0.45 * sin(loop_time * (2.0 + hash(vec2(fi, 9.4)) * 2.5) + fi * 1.9);
		float g = pow(max(0.0, 1.0 - length(ev - gp) / 0.026), 2.0) * sin(cyc * PI) * twinkle;
		glow = max(glow, g);
	}
	glow *= disc * pe * (1.0 - xe);
	col += soul_color.rgb * glow * 0.9 + paper_color.rgb * glow * glow * 0.5;
	a = max(a, glow * 0.8);

	// 0.47 start: the +20% ring (cards reach ~0.456 at the flat edges) must
	// not be dimmed by the pad-edge vignette.
	float frame = 1.0 - smoothstep(0.47, 0.499, length(uv));
	float keep = 1.0 - smoothstep(0.75, 1.0, expire); // cards fade late in flight
	col *= frame * keep;
	a = clamp(a * frame * keep, 0.0, 1.0);
	COLOR = vec4(col, a);
}
