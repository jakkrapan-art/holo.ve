shader_type canvas_item;
render_mode blend_add;

#include "res://resources/tower/shared/lane_fx.gdshaderinc"

// ================================================================
// Altare - Gun Blade Slash (skill beat 1) - normal skill VFX
//
// First artist-drawn-base effect: the hand-drawn frames ARE the
// effect, shader work bends/moves/decorates them - never redraws.
//   blade_tex  skill1/02.png  blade smear, tip at the RIGHT edge
//   shard_tex  skill1/06.png  chevron shard (real alpha, tinted here)
//
// The blade is bent along a polar arc by sampling blade_tex with
// arc coordinates (u = angle behind the swing front, v = across
// the band) - the curve lives in UV space, no mesh node needed.
//
// Look: crescent sweeping bottom -> top (the character slashes UP),
// flat side leads / pointed side trails (artist intent), afterimage
// ghosts, hard-cut vanish at full extension (violent slash leaves
// no hanging tail), ember-mist chevron field drifting off the cut
// (kiara ember-spray model: two staggered layers, per-cell life).
//
// Convention (kiara_skill_effect): progress 0->1 drives everything,
// scale_p pops the frame; author frame is horizontal, controller
// rotates it onto the 3x1 row (author -y = forward).
// ================================================================

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float scale_p  : hint_range(0.01, 1.2) = 1.0;
uniform float aspect   : hint_range(1.0, 6.0)  = 2.4;
// +1 / -1, set by the controller: the rect rotation flips the author
// frame's vertical when the tower aims LEFT, which would turn the
// up-swing into a down-swing on screen - this flips it back so the
// slash always reads bottom -> top whichever side the tower faces.
uniform float sweep_flip : hint_range(-1.0, 1.0) = 1.0;

uniform sampler2D blade_tex : filter_linear;
uniform sampler2D shard_tex : filter_linear;

uniform vec4  core_color : source_color = vec4(0.93, 0.98, 1.00, 1.0);
uniform vec4  rim_color  : source_color = vec4(0.30, 0.52, 1.00, 1.0);
uniform float arc_radius : hint_range(0.8, 6.0) = 1.9;   // bigger = gentler curve
uniform float arc_span   : hint_range(0.3, 1.2) = 0.62;  // half angular extent (rad)
uniform float blade_th   : hint_range(0.05, 0.4) = 0.17; // band half-thickness

const float APEX_Y = -0.08;

float easeOut3(float t) { return 1.0 - pow(1.0 - t, 3.0); }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
mat2 rot2(float a) { float c = cos(a); float s = sin(a); return mat2(vec2(c, s), vec2(-s, c)); }

// artist blade bent along the arc: u = angle behind the front, v = across the band
vec4 blade_arc(vec2 rel, float R, float front_ang, float tail_len, float th) {
	float rr  = length(rel);
	float ang = atan(rel.x, -rel.y);
	float u = 1.0 - (front_ang - ang) / max(tail_len, 1e-3);
	float v = 0.5 + (rr - R) / (2.0 * max(th, 1e-3));
	if (u < 0.0 || u > 1.0 || v < 0.0 || v > 1.0) { return vec4(0.0); }
	// artist intent: FLAT side leads, pointed side trails - texture tip is at
	// the right edge, so flip u to put the flat left edge on the swing front
	vec4 s = textureLod(blade_tex, vec2(1.0 - u, v), 0.0);
	s.a *= smoothstep(0.0, 0.07, u) * smoothstep(0.0, 0.04, 1.0 - u);
	return s;
}

void fragment() {
	vec2 uv = (UV - 0.5) * vec2(aspect, 1.0) / max(scale_p, 0.01);
	vec3 col = vec3(0.0);
	float a = 0.0;

	// mirrored x: the character animation slashes UP -> sweep bottom -> top
	// (sweep_flip re-mirrors when the tower aims left - see uniform note)
	vec2 uv1 = vec2(-uv.x * sweep_flip, uv.y);
	float R = arc_radius;
	vec2 cen = vec2(0.0, APEX_Y + R);
	vec2 rel = uv1 - cen;
	// swing keeps advancing through the vanish (no stop-then-fade); the
	// blade hard-cuts right after full extension - only the mist remains
	float swing = easeOut3(clamp(progress / 0.62, 0.0, 1.0));
	float front = mix(-arc_span - 0.15, arc_span + 0.55, swing);
	float tail_len = arc_span * 1.35;
	float bl_env = 1.0 - smoothstep(0.48, 0.60, progress);

	// unity gain - the artist frame carries its own core/glow; extra
	// multipliers over blend_add read brighter than authored (artist flag)
	vec4 b = blade_arc(rel, R, front, tail_len, blade_th);
	col += b.rgb * b.a * bl_env;
	a = max(a, b.a * bl_env);

	for (int i = 1; i <= 2; i++) {                        // afterimage ghosts
		float fi = float(i);
		vec4 g = blade_arc(rel, R - 0.02 * fi, front - 0.32 * fi, tail_len, blade_th * (1.0 - 0.12 * fi));
		float ga = g.a * (0.40 / fi) * bl_env;
		col += g.rgb * ga * vec3(0.55, 0.65, 1.05);        // ghosts drift cooler/violet
		a = max(a, ga);
	}

	vec2 tip = cen + vec2(sin(front), -cos(front)) * R;   // leading-edge glow
	float tg = 1.0 - smoothstep(0.0, 0.22, length(uv1 - tip));
	tg *= smoothstep(0.02, 0.10, progress) * (1.0 - smoothstep(0.42, 0.58, progress));
	col += core_color.rgb * tg * 0.9;
	a = max(a, tg);

	// ember-mist debris (kiara ember-spray model): two staggered chevron
	// fields drift off the swing and float like fine embers
	float rr1 = length(rel);
	float ang1 = atan(rel.x, -rel.y);
	for (int k = 0; k < 2; k++) {
		float fk = float(k);
		vec2 grid = mix(vec2(9.0, 7.0), vec2(14.0, 11.0), fk);   // coarse + fine layer
		vec2 drift = mix(vec2(2.3, -1.5), vec2(3.2, -2.4), fk);  // parallax = staggered float
		vec2 eg = uv1 * grid - progress * drift;
		vec2 cellv = floor(eg);
		vec2 lp = fract(eg) - 0.5;
		float seed = hash(cellv + fk * 37.0);
		if (seed < 0.92) { continue; }                            // sparse mist
		float seed2 = hash(cellv + 91.0);                         // independent of density cut
		float behind = smoothstep(front, front - 1.3, ang1) * (1.0 - smoothstep(front, front + 0.05, ang1));
		float band = 1.0 - smoothstep(0.30, 0.55, abs(rr1 - R));
		// staggered per-cell life - embers overlap, never in sync; quick vanish
		float cell_env = smoothstep(0.10, 0.25, progress)
			* (1.0 - smoothstep(0.38 + seed2 * 0.20, 0.62 + seed2 * 0.12, progress));
		float rotc = seed2 * 6.28 + progress * (seed2 - 0.5) * 5.0; // slow tumble
		vec2 t = (rot2(-rotc) * lp) / 0.72 + 0.5;
		if (t.x < 0.0 || t.x > 1.0 || t.y < 0.0 || t.y > 1.0) { continue; }
		float sa = textureLod(shard_tex, t, 0.0).a;
		sa *= behind * band * cell_env * (1.0 - 0.35 * fk);       // fine layer dimmer
		col += mix(core_color.rgb, rim_color.rgb, 0.45 + 0.25 * fk) * sa;
		a = max(a, sa);
	}

	// envelope: fade-in/out + corner-free frame over the whole stack
	float life_env = smoothstep(0.0, 0.05, progress) * (1.0 - smoothstep(0.88, 1.0, progress));
	float maskf = lane_frame_mask(uv, aspect, 0.16, 0.12) * life_env;
	col *= maskf;
	a *= maskf;

	COLOR = vec4(col, a);
}
