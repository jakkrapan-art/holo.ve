shader_type canvas_item;
render_mode blend_add;

// Josuiji Shinri "Bull Eyes" crit pierce-arrow VFX - NORMAL tier.
// Citrine comet: head orb + seamless tapered tail + release flash + Burst & Streak particles.
// Lane-static: the head travels across the 1x4 lane via `progress` (0->1); the controller
// (shinri_skill_effect.gd) orients the quad toward the crit target. Driven by progress/scale_p,
// never internal TIME. (Evolve = shinri_evo_skill_effect.gdshader, premultiplied.)

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float scale_p  : hint_range(0.01, 1.2) = 1.0;
uniform float lane_pad : hint_range(0.0, 0.5) = 0.25;   // must match the controller LANE_PAD

uniform float head_r       : hint_range(0.01, 0.12) = 0.030;
uniform float tail_len     : hint_range(0.10, 1.20) = 0.50;
uniform float beam_width   : hint_range(0.008, 0.12) = 0.035;
uniform float intensity    : hint_range(0.0, 2.5)   = 1.1;
uniform float spark_amount : hint_range(0.0, 1.5)   = 0.6;
uniform float origin_soft  : hint_range(0.0, 0.30)  = 0.08;   // soft tail fade at the lane origin (was a hard scissor at the tower)

const vec3 NM_BODY = vec3(1.00, 0.95, 0.55);   // Citrine
const vec3 NM_EDGE = vec3(1.00, 0.78, 0.26);
const vec3 PCORE   = vec3(1.00, 0.99, 0.86);

float hash11(float x){ return fract(sin(x * 127.1) * 43758.5453); }
float headx_at(float p){ return smoothstep(0.08, 0.95, p) * (1.0 + lane_pad * 0.35); }

void fragment(){
	float x = mix(-lane_pad, 1.0 + lane_pad, UV.x);
	float y = UV.y - 0.5;

	float head_x = headx_at(progress);
	float launch = smoothstep(0.0, 0.10, progress);
	float life   = 1.0 - smoothstep(0.88, 1.0, progress);
	float pop    = mix(0.6, 1.0, smoothstep(0.0, 0.55, clamp(scale_p, 0.01, 1.2)));
	float tower_gate = smoothstep(0.0, origin_soft, x);   // soft fade-in instead of a hard cut at the origin

	float dx = head_x - x;
	float bw = max(beam_width, 1e-3);
	float hr = max(head_r, 1e-3);
	float L  = max(tail_len, 1e-3);
	float tt = clamp(dx / L, 0.0, 1.0);
	float born = launch * pop;

	vec3 col = vec3(0.0);

	float head_d = length(vec2(dx / hr, y / bw));
	float head = exp(-head_d * head_d) * born;
	col += mix(NM_BODY, NM_EDGE, smoothstep(0.25, 1.0, head_d)) * head * 1.2;

	float tgate = smoothstep(0.0, hr * 2.0, dx) * step(dx, L) * step(0.0, x);
	float tw = bw * (1.0 - 0.70 * tt);
	float tail = exp(-(y * y) / (2.0 * max(tw, 1e-4) * max(tw, 1e-4))) * pow(1.0 - tt, 1.35) * tgate * born;
	col += mix(NM_BODY, NM_EDGE, 0.25 + 0.60 * tt) * tail * 1.05;

	float flash = exp(-(dx * dx) / (2.0 * (hr * 1.6) * (hr * 1.6)))
			* exp(-(y * y) / (2.0 * (bw * 1.6) * (bw * 1.6))) * (1.0 - smoothstep(0.0, 0.18, progress));
	col += PCORE * flash * 1.3 * tower_gate;

	// release burst from the bow
	float bl = clamp(progress / 0.28, 0.0, 1.0);
	for (int j = 0; j < 6; j++){
		float fj = float(j);
		float s = hash11(fj * 6.1 + 1.3);
		float bx = 0.02 + s * 0.10 * bl;
		float by = (hash11(fj * 2.7) - 0.5) * bw * (1.5 + bl * 9.0);
		float bd = length(vec2((x - bx) / 0.022, (y - by) / 0.008));
		col += mix(NM_BODY, PCORE, 0.4) * exp(-bd * bd) * (1.0 - bl) * spark_amount * 1.5 * tower_gate;
	}
	// fast motion-stretched streak-sparks (decoupled timing)
	for (int i = 0; i < 8; i++){
		float fi = float(i);
		float seed = hash11(fi * 4.7);
		float pe = 0.04 + seed * 0.85;
		float local = progress - pe;
		float plife = 0.22 + seed * 0.12;
		float k = clamp(local / plife, 0.0, 1.0);
		float emX = headx_at(pe);
		float sx = emX - 0.30 * local - seed * 0.03;
		float sy = (hash11(fi * 8.3) - 0.5) * bw * 1.0 + (hash11(fi * 3.1) - 0.5) * bw * 7.0 * k;
		float alive = step(0.0, local) * step(local, plife) * step(0.0, x);
		float sd = length(vec2((x - sx) / 0.030, (y - sy) / 0.0065));
		col += NM_BODY * exp(-sd * sd) * (1.0 - k) * alive * spark_amount * 1.6;
	}

	col *= intensity * life * tower_gate;
	COLOR = vec4(col, 1.0);
}
