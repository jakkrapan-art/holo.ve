shader_type canvas_item;
render_mode blend_premul_alpha;

// Ninomae Ina'nis - normal-attack bullet, "Wet Nib" ink stroke. Second production
// bullet family after Amelia's Soft Glow and Shinri's arrow, and the first to draw
// its own IMPACT beat as well as the projectile.
//
// Ina the illustrator: the bullet is a WET BRUSH STROKE flying point-first, thinning
// as the ink runs out, with a lit violet core line down its middle and two lagging
// afterimages selling the speed. The hit is an ink splat whose droplets arc down
// under gravity - ink flung at a page.
//
// TWO BEATS, ONE SHADER via `phase` (0 = bullet, 1 = impact) - the Calliope evo
// pattern. Uniform branching does not create a second pipeline, so the single
// attack_config.vfx_shader warm (resource_manager.gd) covers the impact too.
//
// blend_premul_alpha, NOT blend_add: the palette is ink-dark and blend_add only adds
// luminance, so the ink bands would vanish over a lit map.
// Do NOT use MODULATE - a custom-COLOR canvas_item fragment does not apply it.
//
// NO internal TIME. `life` (seconds in flight) is pushed each frame by
// AttackController._onBulletMove via ProjectileCallback.onMove, so the dry-out rides
// the same _process delta as the projectile: pause-frozen and x2-correct for free.
// `progress` (impact 0->1) is tweened by AttackController._spawnImpact.
//
// Director calls, 2026-07-20: cut the cream rim, the gold tip flick, and the impact
// rune ring. The read is ink and violet only - the silhouette carries the shot.

uniform float phase : hint_range(0.0, 1.0) = 0.0;      // 0 = bullet, 1 = impact
uniform float progress : hint_range(0.0, 1.0) = 0.0;   // impact beat 0->1
uniform float life = 0.0;                              // seconds in flight

uniform vec4 ink_color  : source_color = vec4(0.05, 0.03, 0.10, 1.0);  // wet ink core
uniform vec4 body_color : source_color = vec4(0.42, 0.22, 0.72, 1.0);  // Ina violet
uniform vec4 nib_color  : source_color = vec4(0.80, 0.62, 1.00, 1.0);  // lit core line
uniform vec4 rim_color  : source_color = vec4(0.93, 0.90, 0.82, 1.0);  // parchment cream (droplets)

uniform float stroke_hh : hint_range(0.10, 0.48) = 0.34;  // stroke half-height at its fattest
uniform float taper     : hint_range(0.0, 1.0)   = 0.65;  // 0 = even width, 1 = whip-thin tail
uniform float bristle   : hint_range(0.0, 1.0)   = 0.55;  // dry split-bristle gaps in the tail
uniform float dry_rate  : hint_range(0.0, 1.0)   = 0.45;  // how fast the ink thins in flight
uniform float nib_core  : hint_range(0.0, 1.0)   = 0.85;  // lit core-line strength
uniform float alpha_mul : hint_range(0.0, 1.0)   = 1.0;

const float AA = 0.012;
const float TIPX = 0.46;
const float BACKX = -0.48;

// Half-height of the brush at lane position x. Leaf-tapered both ends: the two edges
// converge to a rounded apex, never a stuck-on cap (vfx-craft.md "Tapered tip").
float brush_hh(float x, float hh_scale) {
	float t = clamp((TIPX - x) / (TIPX - BACKX), 0.0, 1.0);   // 0 at tip, 1 at tail end
	float front = smoothstep(0.0, 0.13, t);
	float fall = mix(1.0 - t, (1.0 - t) * (1.0 - t), taper);
	float press = 1.0 - dry_rate * clamp(life * 1.6, 0.0, 1.0) * 0.4;   // ink runs out
	return stroke_hh * hh_scale * front * fall * press;
}

// One stroke's coverage. xshift slides it BACK along the lane for the afterimages -
// it must stay negative: a positive shift pushes the ghost tip past the quad edge,
// where the scissor turns it into a flat lit cap on the head.
float stroke_body(vec2 q, float hh_scale, float xshift) {
	vec2 s = q - vec2(xshift, 0.0);
	float ay = abs(s.y);
	float hh = brush_hh(s.x, hh_scale);
	float body = 1.0 - smoothstep(hh - AA, hh + AA, ay);

	// Dry split bristles: thin gaps that only appear in the back half.
	float t = clamp((TIPX - s.x) / (TIPX - BACKX), 0.0, 1.0);
	float dry_zone = smoothstep(0.32, 0.95, t);
	float gaps = smoothstep(0.55, 0.96, abs(sin(s.y * 46.0)));
	body *= 1.0 - dry_zone * gaps * bristle;
	return clamp(body, 0.0, 1.0);
}

void draw_stroke(vec2 q, out vec3 col, out float a) {
	float t = clamp((TIPX - q.x) / (TIPX - BACKX), 0.0, 1.0);
	col = mix(ink_color.rgb, body_color.rgb, smoothstep(0.0, 0.55, t));

	float body = stroke_body(q, 1.0, 0.0);

	// Lit core line: keeps a dark stroke off a dark map without adding a bright rim.
	float hh = max(brush_hh(q.x, 1.0), 1e-3);
	float core = (1.0 - smoothstep(hh * 0.20, hh * 0.50, abs(q.y))) * body;
	col = mix(col, nib_color.rgb, core * nib_core);

	// Two lagging afterimages: reads as speed even at a slow travel rate.
	float g1 = stroke_body(q, 0.82, -0.10) * 0.30;
	float g2 = stroke_body(q, 0.64, -0.20) * 0.14;
	float ghosts = max(g1, g2);
	col = mix(col, ink_color.rgb, clamp(ghosts - body, 0.0, 1.0) * 0.8);

	a = clamp(max(body, ghosts), 0.0, 1.0);
}

// Impact. Drawn on a SQUARE quad: length()/atan() on UV-0.5 are only isotropic there.
// Spawned unrotated, so the droplet gravity below actually reads as "down".
void draw_impact(vec2 q, out vec3 col, out float a) {
	float p = clamp(progress, 0.0, 1.0);
	float r = length(q) * 2.0;
	float ang = atan(q.y, q.x);

	// Splat: an irregular blob that snaps open, then holds.
	float grow = smoothstep(0.0, 0.30, p);
	float wob = 0.07 * sin(ang * 7.0) + 0.045 * sin(ang * 11.0 + 1.7);
	float rad = (0.16 + 0.20 * grow) + wob * grow;
	float blob = 1.0 - smoothstep(rad - 0.035, rad + 0.035, r);

	// Droplets: flung outward, falling in an arc, still drifting through the fade
	// (no stop-then-vanish).
	float drops = 0.0;
	for (int i = 0; i < 7; i++) {
		float fi = float(i);
		float a0 = fi * 0.897 + 0.4;
		float dist = 0.22 + 0.46 * smoothstep(0.0, 0.75, p) * (0.7 + 0.3 * sin(fi * 2.3));
		vec2 c = vec2(cos(a0), sin(a0)) * dist * 0.5;
		c.y += 0.30 * p * p;   // gravity
		float sz = (0.030 + 0.016 * sin(fi * 1.7)) * (1.0 - 0.35 * p);
		drops = max(drops, 1.0 - smoothstep(sz, sz + 0.012, length(q - c)));
	}

	col = mix(body_color.rgb, ink_color.rgb, smoothstep(0.0, 0.5, r));
	col = mix(col, rim_color.rgb, drops * 0.35);
	col = mix(col, nib_color.rgb, blob * (1.0 - smoothstep(0.0, 0.25, p)) * 0.5);

	a = clamp(max(blob, drops), 0.0, 1.0);
	a *= 1.0 - smoothstep(0.5, 1.0, p);
}

void fragment() {
	vec2 q = UV - 0.5;
	vec3 col = vec3(0.0);
	float a = 0.0;

	if (phase < 0.5) {
		draw_stroke(q, col, a);
	} else {
		draw_impact(q, col, a);
	}

	a *= alpha_mul;
	COLOR = vec4(col * a, a);   // premultiplied
}
