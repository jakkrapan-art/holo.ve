shader_type canvas_item;
render_mode blend_add;

#include "res://resources/tower/shared/lane_fx.gdshaderinc"

// ================================================================
// Altare - Gun Volley (skill beat 2) - normal skill VFX
//
// Artist-drawn-base: the hand-drawn frames ARE the effect.
//   body_tex  skill2/05.png  energy streak, bright end at the LEFT
//   head_tex  skill2/11.png  chevron head, pointing LEFT
//   star_tex  skill2/09.png  4-point star - the impact burst
// Head/body are flipped in-sample so the shot travels lane +x.
//
// FORMAT TRAP: 09.png is a BLACK-BG additive sheet - alpha is solid
// 255 across the whole image, the shape lives in RGB. Read
// brightness, never alpha, or the sample renders as a square.
// (05/11.png carry real alpha.)
//
// Look ("Speed Rush", Director-picked): barely any charge - a short
// glint at the muzzle - then one massive round accelerates down the
// lane, trail erodes muzzle -> end, 4-point star burst + 3 scattered
// stars finish at the lane end. No speed lines (Director cut).
//
// Lane family conventions: progress/scale_p drive all motion, lane
// helpers from the shared include, lane_aniso corrects square
// sprites (lane-x and lane-y units differ), muzzle_x comes from
// Utility.MUZZLE_OFFSET_TILES via the controller - the same knob as
// the homing basic attack.
// ================================================================

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float scale_p  : hint_range(0.01, 1.2) = 1.0;
uniform float aspect   : hint_range(1.0, 6.0)  = 2.8;
uniform float lane_pad : hint_range(0.0, 1.0)  = 0.25; // MUST match controller LANE_PAD
uniform float lane_aniso : hint_range(0.5, 4.0) = 1.875; // LANE_LEN_CELLS / VISUAL_W_CELLS
uniform float muzzle_x : hint_range(0.0, 0.5) = 0.167;  // MUZZLE_OFFSET_TILES / LANE_LEN_CELLS

uniform sampler2D head_tex : filter_linear;
uniform sampler2D body_tex : filter_linear;
uniform sampler2D star_tex : filter_linear;

uniform vec4 core_color : source_color = vec4(0.93, 0.98, 1.00, 1.0);
uniform vec4 rim_color  : source_color = vec4(0.30, 0.52, 1.00, 1.0);

// impact star scatter - hand-authored: (x off, y off, size, delay)
const vec4 IMP_ST[3] = vec4[](
	vec4( 0.035, -0.14, 0.10, 0.00),
	vec4( 0.065,  0.10, 0.07, 0.03),
	vec4(-0.030,  0.05, 0.05, 0.06));

float easeOut3(float t) { return 1.0 - pow(1.0 - t, 3.0); }
mat2 rot2(float ang) { float c = cos(ang); float s = sin(ang); return mat2(vec2(c, s), vec2(-s, c)); }

// circular distance around a lane point (y-units), aniso-corrected
float cdist(vec2 lane_ly, vec2 pos) {
	return length(vec2((lane_ly.x - pos.x) * lane_aniso, lane_ly.y - pos.y));
}

// chevron head at hx, flipped to point +x; square via lane_aniso.
// Full RGBA - the artist's blue ring colours ARE the head; tinting it
// with a core colour read brighter/whiter than authored (artist flag).
vec4 head_s(vec2 lane, float hx, float yoff, float hs) {
	vec2 t = vec2((lane.x - hx) / max(hs, 1e-4), (lane.y - yoff) / max(hs * lane_aniso, 1e-4)) + 0.5;
	if (t.x < 0.0 || t.x > 1.0 || t.y < 0.0 || t.y > 1.0) { return vec4(0.0); }
	return textureLod(head_tex, vec2(1.0 - t.x, t.y), 0.0);
}

// streak body behind the head, bright end at the head (tex flipped)
vec4 body_s(vec2 lane, float hx, float yoff, float tr_len, float bw) {
	float u = (lane.x - (hx - tr_len)) / max(tr_len, 1e-3);
	float v = 0.5 + (lane.y - yoff) / (2.0 * max(bw, 1e-3));
	if (u < 0.0 || u > 1.0 || v < 0.0 || v > 1.0) { return vec4(0.0); }
	vec4 s = textureLod(body_tex, vec2(1.0 - u, v), 0.0);
	s.a *= smoothstep(0.0, 0.15, u);   // soft tail end
	return s;
}

// star sprite (black-bg sheet: brightness IS the shape - see header)
float star_a(vec2 lane_ly, vec2 pos, float rot, float size) {
	vec2 l = vec2((lane_ly.x - pos.x) * lane_aniso, lane_ly.y - pos.y);
	vec2 t = (rot2(-rot) * l) / max(size, 1e-4) + 0.5;
	if (t.x < 0.0 || t.x > 1.0 || t.y < 0.0 || t.y > 1.0) { return 0.0; }
	vec3 s = textureLod(star_tex, t, 0.0).rgb;
	return dot(s, vec3(0.34, 0.40, 0.26));
}

void fragment() {
	vec2 uv = (UV - 0.5) * vec2(aspect, 1.0) / max(scale_p, 0.01);
	vec2 lane = lane_coord(UV, lane_pad);
	float ly = lane.y / max(scale_p, 0.01);
	vec2 lp2 = vec2(lane.x, ly);
	vec2 muz = vec2(muzzle_x, 0.0);
	vec3 col = vec3(0.0);
	float a = 0.0;

	// lance: fires near-instantly - the skill hitbox lands at spawn, so
	// the visual must not lag behind it (Director in-game feedback)
	float s2 = clamp((progress - 0.06) / 0.14, 0.0, 1.0);
	float hx = muzzle_x + pow(s2, 1.6) * (1.02 - muzzle_x);
	float henv = max(1.0 - smoothstep(0.22, 0.32, progress), smoothstep(0.98, 1.0, hx) * (1.0 - smoothstep(0.26, 0.38, progress)));
	vec4 hd = head_s(lp2, hx, 0.0, 0.20);
	float h = hd.a * henv;
	vec4 b = body_s(lp2, hx, 0.0, max(hx - muzzle_x, 0.2), 0.16);   // trail back to the muzzle
	float erode = smoothstep(0.22, 0.55, progress);                 // evaporate muzzle -> end
	float ba = b.a * lane_origin_gate(lane.x - muzzle_x + 0.06, 0.10)
		* smoothstep(erode * 1.1 - 0.1, erode * 1.1 + 0.08, lane.x)
		* (1.0 - smoothstep(0.50, 0.66, progress));
	// unity gain - artist frames carry their own core/glow (artist flag)
	col += b.rgb * ba + hd.rgb * h;
	a = max(a, max(ba, h));

	// blink-short muzzle glint - pure velocity, no charge pose
	float p_chg = clamp(progress / 0.08, 0.0, 1.0);
	float chg_off = 1.0 - smoothstep(0.08, 0.12, progress);
	float g = (1.0 - smoothstep(0.0, 0.05 + 0.05 * p_chg, cdist(lp2, muz))) * p_chg * chg_off;
	col += core_color.rgb * g * 1.2;
	a = max(a, g);

	// star burst impact + scattered small stars
	float w_imp = clamp((progress - 0.18) / 0.14, 0.0, 1.0);
	float sb = star_a(lp2, vec2(1.0, 0.0), 0.0, mix(0.08, 0.30, easeOut3(w_imp)));
	sb *= smoothstep(0.18, 0.21, progress) * (1.0 - smoothstep(0.30, 0.46, progress));
	col += core_color.rgb * sb * 1.3;
	a = max(a, sb);
	for (int i = 0; i < 3; i++) {
		vec4 st = IMP_ST[i];
		float wl = clamp((progress - 0.24 - st.w) / 0.24, 0.0, 1.0);
		if (wl <= 0.0) { continue; }
		vec2 pos = vec2(1.0, 0.0) + vec2(st.x, st.y) * (0.6 + 0.8 * easeOut3(wl));
		float ss = star_a(lp2, pos, 0.0, st.z * (1.0 - 0.3 * wl));
		ss *= (1.0 - smoothstep(0.55, 1.0, wl));
		col += mix(core_color.rgb, rim_color.rgb, 0.4) * ss;
		a = max(a, ss);
	}

	// envelope: fade-in/out + corner-free frame over the whole stack
	float life_env = smoothstep(0.0, 0.03, progress) * (1.0 - smoothstep(0.85, 1.0, progress));
	float maskf = lane_frame_mask(uv, aspect, 0.14, 0.10) * life_env;
	col *= maskf;
	a *= maskf;

	COLOR = vec4(col, a);
}
