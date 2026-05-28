shader_type canvas_item;
render_mode blend_mix;

// Kiara-centered sword arc.
// The effect rect is centered on the tower. The arc sweeps around that center,
// so the slash reads like a sword swing instead of a projectile passing through
// the target cells.

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float scale_p : hint_range(0.01, 1.2) = 1.0;
uniform vec2 space_tiles = vec2(4.0, 4.0);
uniform int style_mode : hint_range(0, 2) = 0;
uniform int shape_mode : hint_range(0, 2) = 0;

uniform float arc_center_angle = 3.14159265;
uniform float arc_radius : hint_range(0.4, 2.0) = 1.12;
uniform float arc_thickness : hint_range(0.04, 0.45) = 0.15;
uniform float arc_span : hint_range(0.4, 1.8) = 1.18;
uniform float trail_angle : hint_range(0.2, 2.4) = 0.85;
uniform float shape_curve : hint_range(-0.8, 0.8) = 0.0;
uniform float shape_taper : hint_range(0.0, 1.0) = 0.35;
uniform float double_arc_offset : hint_range(0.0, 0.8) = 0.0;

uniform float flame_width : hint_range(0.05, 0.70) = 0.36;
uniform float roughness : hint_range(0.0, 1.0) = 0.35;
uniform float ember_amount : hint_range(0.0, 1.0) = 0.35;
uniform float feather_amount : hint_range(0.0, 1.0) = 0.35;
uniform float sparkle_amount : hint_range(0.0, 1.0) = 0.20;
uniform float ash_amount : hint_range(0.0, 1.0) = 0.10;
uniform float sacred_gold : hint_range(0.0, 1.0) = 0.45;
uniform float anime_band : hint_range(0.0, 1.0) = 0.65;
uniform float lick_amount : hint_range(0.0, 1.0) = 0.45;
uniform float brush_fill : hint_range(0.0, 1.0) = 0.65;
uniform float red_rim : hint_range(0.0, 1.0) = 0.55;
uniform float mint_accent : hint_range(0.0, 1.0) = 0.18;
uniform float shard_amount : hint_range(0.0, 1.0) = 0.35;
uniform float border_strength : hint_range(0.0, 1.0) = 0.55;
uniform float burst_amount : hint_range(0.0, 1.0) = 0.35;
uniform float round_start : hint_range(0.0, 1.0) = 0.45;
uniform int tail_shape_mode : hint_range(0, 1) = 0;
uniform float tail_taper : hint_range(0.0, 1.0) = 0.0;
uniform float tail_fade : hint_range(0.0, 1.0) = 0.0;
uniform float brightness : hint_range(0.6, 3.5) = 2.3;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

float ease_out3(float t) {
	return 1.0 - pow(1.0 - t, 3.0);
}

float swing_timing(float t) {
	if (t < 0.24) {
		float u = t / 0.24;
		return 0.05 * u * u;
	}
	if (t < 0.56) {
		float u = (t - 0.24) / 0.32;
		return mix(0.05, 0.90, pow(u, 0.48));
	}
	float u = (t - 0.56) / 0.44;
	return mix(0.90, 1.0, ease_out3(u));
}

float angle_diff(float a, float b) {
	return atan(sin(a - b), cos(a - b));
}

void fragment() {
	vec2 p = (UV - 0.5) * space_tiles / max(scale_p, 0.01);
	float r = length(p);
	float theta = atan(p.y, p.x);
	float a = angle_diff(theta, arc_center_angle);

	float sweep_t = clamp(progress / 0.82, 0.0, 1.0);
	float swing_t = swing_timing(sweep_t);
	float impact = 1.0 - smoothstep(0.00, 0.13, abs(swing_t - 0.86));
	float head = mix(-arc_span, arc_span, swing_t);
	float tail = head - trail_angle;

	float lead = smoothstep(tail - 0.12, tail + 0.08, a);
	float cut = 1.0 - smoothstep(head + 0.035, head + 0.13, a);
	float sweep_band = lead * cut;
	float arc_window = 1.0 - smoothstep(arc_span + 0.16, arc_span + 0.36, abs(a));
	float trail_u = clamp((a - tail) / max(head - tail, 0.001), 0.0, 1.0);
	float head_energy = smoothstep(0.35, 1.00, trail_u);
	float tail_position_fade = smoothstep(0.00, 0.50, trail_u);
	float arc_trail_fade = mix(1.0, tail_position_fade, tail_fade);
	float arc_tip_fade = mix(0.25, 1.0, head_energy);
	float triangle_tail = max(0.035, smoothstep(0.00, 0.62, trail_u));
	float kite_tail = max(0.04, smoothstep(0.00, 0.42, trail_u) * (1.0 - 0.48 * smoothstep(0.58, 1.00, trail_u)));
	float tail_shape = mix(triangle_tail, kite_tail, float(tail_shape_mode));
	float tail_width_scale = mix(1.0, tail_shape, tail_taper);

	float n = fbm(vec2(a * 2.4 + progress * 1.6, r * 3.2 - progress * 2.8));
	float radius_warp = (n - 0.5) * roughness * 0.18;

	float lick = sin(a * 9.0 - progress * 9.0) * 0.5 + 0.5;
	lick *= sin(a * 15.0 + progress * 5.0) * 0.5 + 0.5;
	float lick_push = (lick - 0.5) * lick_amount * 0.18 * (1.0 - trail_u);
	float curved_radius = arc_radius + shape_curve * (trail_u - 0.5) * (trail_u - 0.5) * 2.0 + lick_push;
	float shape_width = 1.0;
	if (shape_mode == 0) {
		float tail_grow = smoothstep(0.00, 0.24, trail_u);
		float arrow_shoulder = smoothstep(0.48, 0.78, trail_u) * (1.0 - smoothstep(0.78, 0.98, trail_u));
		float arrow_tip_point = mix(0.28, 1.0, 1.0 - smoothstep(0.86, 1.0, trail_u));
		shape_width = max(0.18, tail_grow * arrow_tip_point * (0.42 + arrow_shoulder * 1.25));
	} else if (shape_mode == 1) {
		float brush_bulge = sin(a * 4.0 - progress * 5.0) * 0.5 + 0.5;
		shape_width = 1.15 + brush_bulge * 0.42 * (1.0 - smoothstep(0.72, 1.0, trail_u));
	} else {
		float feather_wave = sin(a * 6.0 + progress * 3.0) * 0.5 + 0.5;
		shape_width = 0.72 + feather_wave * 0.28;
	}
	float tapered_thickness = arc_thickness * mix(1.0 + shape_taper, 0.35 + shape_taper * 0.35, trail_u) * shape_width * tail_width_scale;
	float core_dist = abs(r - (curved_radius + radius_warp));
	float double_dist = abs(r - (curved_radius - double_arc_offset + radius_warp * 0.45));
	float double_body = 0.0;
	if (double_arc_offset > 0.01) {
		double_body = 1.0 - smoothstep(tapered_thickness * 0.30, tapered_thickness * 1.20, double_dist);
		double_body *= 1.0 - smoothstep(0.22, 0.95, trail_u);
	}
	float blade_core = 1.0 - smoothstep(tapered_thickness * 0.30, tapered_thickness, core_dist);
	blade_core = max(blade_core, double_body * 0.75);
	float arrow_head = 0.0;
	if (shape_mode == 0) {
		float arrow_region = smoothstep(0.58, 0.82, trail_u) * (1.0 - smoothstep(0.96, 1.0, trail_u));
		float arrow_tip_width = tapered_thickness * mix(1.85, 0.12, smoothstep(0.72, 1.0, trail_u));
		arrow_head = (1.0 - smoothstep(arrow_tip_width * 0.25, arrow_tip_width, core_dist)) * arrow_region;
		blade_core = max(blade_core, arrow_head);
	}
	float local_flame_width = flame_width * mix(1.15, 0.65, trail_u) * mix(1.0, tail_width_scale, 0.85);
	float flame_body = exp(-core_dist / max(local_flame_width, 0.01));
	float flame_cut = smoothstep(0.18, 0.62, n + lick * 0.20);
	flame_body *= mix(1.0, flame_cut, anime_band * 0.72);
	float wispy = smoothstep(0.30, 0.72, n);

	float brush_width = max(flame_width * 1.28 * mix(1.0, tail_width_scale, 0.88), tapered_thickness * 2.65);
	float rounded_cap = mix(1.0, smoothstep(-0.02, 0.08, trail_u), 0.22 * round_start);
	float brush_mask = 1.0 - smoothstep(brush_width * 0.30, brush_width, core_dist);
	brush_mask *= rounded_cap;
	float brush_inner = 1.0 - smoothstep(0.00, brush_width * 0.38, core_dist);
	float brush_rim = smoothstep(brush_width * 0.42, brush_width * 0.74, core_dist) * (1.0 - smoothstep(brush_width * 0.74, brush_width, core_dist));
	float outer_border = smoothstep(brush_width * 0.80, brush_width * 1.02, core_dist) * (1.0 - smoothstep(brush_width * 1.02, brush_width * 1.28, core_dist));
	outer_border *= sweep_band * arc_window * arc_trail_fade * border_strength * (0.82 + impact * 0.18);
	float brush_streak_noise = fbm(vec2(a * 6.0 + progress * 3.2, r * 11.0 - progress * 4.0));
	float brush_streak = smoothstep(0.28, 0.72, brush_streak_noise + lick * 0.28);
	float brush_alpha = brush_mask * sweep_band * arc_window * arc_trail_fade * mix(0.72, brush_streak, brush_fill);
	if (shape_mode == 1) {
		float brush_gaps = smoothstep(0.18, 0.55, brush_streak_noise + lick * 0.42);
		brush_alpha *= mix(1.0, brush_gaps, 0.58);
	}
	float mint_zone = (1.0 - smoothstep(0.08, 0.44, trail_u)) * brush_inner * brush_alpha * mint_accent;

	float head_glow = 1.0 - smoothstep(0.00, 0.16, abs(a - head));
	head_glow *= 1.0 - smoothstep(arc_thickness * 0.40, arc_thickness * 2.1, core_dist);

	float body = max(blade_core, flame_body * mix(0.35, 1.0, wispy));
	body = max(body, brush_alpha * brush_fill * 0.90);
	body *= arc_trail_fade;
	body *= sweep_band * arc_window;
	body = max(body, head_glow * (0.85 + impact * 0.45));

	float trailing_alpha = arc_trail_fade * (1.0 - smoothstep(0.92, 1.00, trail_u));
	float razor_tip = head_glow * (1.0 - smoothstep(tapered_thickness * 0.25, tapered_thickness * 1.40, core_dist)) * (1.0 + impact * 0.55);
	float razor_tail = blade_core * trailing_alpha * (1.0 - smoothstep(0.35, 0.78, roughness));
	float afterimage = 1.0 - smoothstep(0.00, tapered_thickness * 2.0, abs(r - (curved_radius - 0.20)));
	afterimage *= sweep_band * arc_window * arc_trail_fade * (1.0 - smoothstep(0.72, 1.00, trail_u)) * 0.38;

	vec2 ember_space = vec2(a * 14.0, r * 8.0 + progress * 8.0);
	vec2 ember_cell = floor(ember_space);
	vec2 ember_local = fract(ember_space) - 0.5;
	float ember_seed = hash(ember_cell);
	float ember_gate = step(mix(0.98, 0.83, ember_amount), ember_seed);
	float ember_near_arc = 1.0 - smoothstep(0.15, 0.62, core_dist);
	float ember_dot = 1.0 - smoothstep(0.00, mix(0.10, 0.24, hash(ember_cell + vec2(9.0, 9.0))), length(ember_local));
	float ember = ember_gate * ember_near_arc * sweep_band * arc_window * ember_dot * ember_amount * arc_trail_fade * (1.0 + impact * 0.35);

	float feather_phase = fract((a + progress * 0.45 + 6.28318) * 3.4);
	float feather_stripe = 1.0 - smoothstep(0.00, 0.18, abs(feather_phase - 0.50));
	float feather_ridge = curved_radius + 0.22 + 0.09 * sin(a * 4.0 + progress * 2.0);
	float feather_radial = exp(-pow((r - feather_ridge) / 0.18, 2.0));
	float feather_taper = smoothstep(tail - 0.05, tail + 0.20, a) * (1.0 - smoothstep(head - 0.08, head + 0.22, a));
	float feather = feather_stripe * feather_radial * feather_taper * arc_window * feather_amount * mix(0.45, 1.0, wispy) * arc_trail_fade;
	float wing_mantle = exp(-pow((r - (curved_radius + 0.38 + 0.10 * sin(a * 3.0 + progress * 4.0))) / 0.36, 2.0));
	wing_mantle *= sweep_band * arc_window * smoothstep(0.10, 0.78, trail_u) * feather_amount * arc_trail_fade;
	vec2 feather_space = vec2(a * 10.0 - progress * 4.0, r * 5.0 + progress * 2.0);
	vec2 feather_cell = floor(feather_space);
	vec2 feather_local = fract(feather_space) - 0.5;
	float feather_seed = hash(feather_cell + vec2(71.0, 19.0));
	float feather_gate = step(mix(0.992, 0.82, feather_amount), feather_seed);
	float feather_out_r = curved_radius + mix(0.28, 0.78, hash(feather_cell + vec2(3.0, 11.0)));
	float feather_scatter_radial = 1.0 - smoothstep(0.00, 0.22, abs(r - feather_out_r));
	float feather_streak = (1.0 - smoothstep(0.05, 0.46, abs(feather_local.x))) * (1.0 - smoothstep(0.01, 0.10, abs(feather_local.y)));
	float feather_scatter = feather_gate * feather_streak * feather_scatter_radial * sweep_band * arc_window * arc_trail_fade * feather_amount;
	float feather_fan = 0.0;

	vec2 sparkle_space = vec2(a * 18.0 + progress * 6.0, r * 9.0 - progress * 2.0);
	vec2 sparkle_cell = floor(sparkle_space);
	vec2 sparkle_local = fract(sparkle_space) - 0.5;
	float sparkle_seed = hash(sparkle_cell + vec2(23.0, 41.0));
	float sparkle_gate = step(mix(0.995, 0.90, sparkle_amount), sparkle_seed);
	float sparkle_core = 1.0 - smoothstep(0.00, 0.08, length(sparkle_local));
	float sparkle_cross_x = (1.0 - smoothstep(0.00, 0.020, abs(sparkle_local.y))) * (1.0 - smoothstep(0.02, 0.28, abs(sparkle_local.x)));
	float sparkle_cross_y = (1.0 - smoothstep(0.00, 0.020, abs(sparkle_local.x))) * (1.0 - smoothstep(0.02, 0.28, abs(sparkle_local.y)));
	float sparkle = sparkle_gate * max(sparkle_core, max(sparkle_cross_x, sparkle_cross_y) * 0.55) * sweep_band * arc_window * sparkle_amount * arc_tip_fade * (1.0 + impact * 0.65);

	vec2 shard_space = vec2(a * 9.0 + progress * 5.0, r * 5.5 - progress * 2.0);
	vec2 shard_cell = floor(shard_space);
	vec2 shard_local = fract(shard_space) - 0.5;
	float shard_seed = hash(shard_cell + vec2(17.0, 63.0));
	float shard_gate = step(mix(0.995, 0.86, shard_amount), shard_seed);
	float shard_shape = (1.0 - smoothstep(0.12, 0.48, abs(shard_local.x))) * (1.0 - smoothstep(0.02, 0.11, abs(shard_local.y)));
	float shard_near = 1.0 - smoothstep(brush_width * 0.35, brush_width * 1.35, core_dist);
	float shard = shard_gate * shard_shape * shard_near * sweep_band * arc_window * arc_trail_fade * shard_amount;
	vec2 burst_space = vec2(a * 7.0 - progress * 3.0, r * 6.0 + progress * 8.0);
	vec2 burst_cell = floor(burst_space);
	vec2 burst_local = fract(burst_space) - 0.5;
	float burst_seed = hash(burst_cell + vec2(91.0, 37.0));
	float burst_gate = step(mix(0.996, 0.84, burst_amount), burst_seed);
	float burst_r = curved_radius + mix(0.24, 0.76, hash(burst_cell + vec2(13.0, 29.0)));
	float burst_radial = 1.0 - smoothstep(0.00, 0.16, abs(r - burst_r));
	float burst_wave = (1.0 - smoothstep(0.05, 0.55, abs(burst_local.x))) * (1.0 - smoothstep(0.02, 0.13, abs(burst_local.y)));
	float burst = burst_gate * burst_wave * burst_radial * sweep_band * arc_window * arc_trail_fade * burst_amount;
	float burst_wavefront_r = curved_radius + 0.46 + 0.10 * sin(a * 6.0 - progress * 8.0);
	float burst_wavefront = 1.0 - smoothstep(0.00, 0.055, abs(r - burst_wavefront_r));
	float burst_break = smoothstep(0.42, 0.78, fbm(vec2(a * 5.0 - progress * 4.0, r * 4.0 + progress * 2.0)) + lick * 0.18);
	burst_wavefront *= burst_break * sweep_band * arc_window * arc_trail_fade * burst_amount;
	burst_wavefront *= smoothstep(0.06, 0.50, trail_u) * (1.0 - smoothstep(0.80, 1.0, trail_u));
	burst = max(burst, burst_wavefront);

	vec2 ash_space = vec2(a * 9.0 - progress * 2.0, r * 7.0 + progress * 4.0);
	vec2 ash_cell = floor(ash_space);
	vec2 ash_local = fract(ash_space) - 0.5;
	float ash_seed = hash(ash_cell + vec2(5.0, 31.0));
	float ash_gate = step(mix(0.99, 0.88, ash_amount), ash_seed);
	float ash_near_arc = 1.0 - smoothstep(0.12, 0.78, core_dist);
	float ash_dot = 1.0 - smoothstep(0.00, 0.18, length(ash_local));
	float ash = ash_gate * ash_near_arc * sweep_band * arc_window * ash_dot * ash_amount * 0.55 * arc_trail_fade;
	float ghost_outer = 1.0 - smoothstep(0.00, 0.18, abs(r - (curved_radius + 0.35)));
	ghost_outer *= sweep_band * arc_window * arc_trail_fade * (1.0 - smoothstep(0.74, 1.00, trail_u)) * ash_amount;
	float ghost_inner = 1.0 - smoothstep(0.00, 0.12, abs(r - (curved_radius - 0.38)));
	ghost_inner *= sweep_band * arc_window * arc_trail_fade * smoothstep(0.05, 0.55, trail_u) * ash_amount * 0.8;

	float life = 1.0 - smoothstep(0.98, 1.0, progress);
	if (style_mode == 0) {
		body = max(max(max(razor_tip, arrow_head), max(razor_tail, afterimage * 0.45)), brush_alpha * 0.78) * life;
		feather *= 0.25;
		feather_scatter *= 0.20;
		ember *= 0.35;
		ash *= 0.10;
		sparkle *= 0.55;
	} else if (style_mode == 1) {
		body = max(body * 0.82, max(feather * 0.85, max(wing_mantle * 0.72, feather_scatter * 0.82))) * life;
		feather = max(max(feather, wing_mantle * 0.80), feather_scatter * 0.90);
		ember *= 0.75;
		ash *= 0.18;
		sparkle *= 0.70;
	} else {
		body = max(max(body * 0.72, head_glow * (0.95 + impact * 0.45)), max(max(ghost_outer * 0.50, ghost_inner * 0.42), feather_fan * 0.70)) * life;
		ember = max(ember, ghost_outer * 0.35);
		ash = max(ash, max(ghost_outer, ghost_inner) * 0.42);
		sparkle *= 1.15;
		feather = max(max(feather * 0.45, feather_scatter * 0.45), feather_fan * 0.95);
	}
	ember *= life;
	feather *= life;
	feather_fan *= life;
	sparkle *= life;
	ash *= life;
	wing_mantle *= life;
	feather_scatter *= life;
	ghost_outer *= life;
	ghost_inner *= life;
	brush_alpha *= life;
	brush_inner *= life;
	brush_rim *= life;
	outer_border *= life;
	mint_zone *= life;
	shard *= life;
	burst *= life;

	vec3 red = vec3(0.80, 0.08, 0.00);
	vec3 orange = vec3(1.00, 0.30, 0.03);
	vec3 gold = vec3(1.00, 0.78, 0.18);
	vec3 pale_yellow = vec3(1.00, 0.96, 0.58);
	vec3 white = vec3(1.00, 0.98, 0.78);
	vec3 mint = vec3(0.42, 1.00, 0.78);

	vec3 col = mix(red, orange, smoothstep(0.05, 0.35, body));
	col = mix(col, gold, smoothstep(0.32, 0.68, body));
	col = mix(col, white, smoothstep(0.68, 1.0, body + head_glow * 0.5));
	col = mix(col, gold, sacred_gold * 0.22);
	if (anime_band > 0.01) {
		float band = floor(clamp(body + head_glow * 0.35, 0.0, 1.0) * 4.0) / 3.0;
		vec3 band_col = mix(red, orange, smoothstep(0.00, 0.35, band));
		band_col = mix(band_col, gold, smoothstep(0.34, 0.70, band));
		band_col = mix(band_col, white, smoothstep(0.70, 1.00, band));
		col = mix(col, band_col, anime_band * 0.55);
	}

	vec3 rgb = col * body * brightness;
	rgb += vec3(1.00, 0.58, 0.08) * brush_alpha * brightness * 0.95;
	rgb += pale_yellow * brush_inner * brush_alpha * brightness * 1.12;
	rgb += red * brush_rim * red_rim * brightness * 1.25;
	rgb += vec3(1.00, 0.08, 0.00) * outer_border * brightness * 1.85;
	rgb += mint * mint_zone * brightness * 1.65;
	if (style_mode == 0) {
		rgb += vec3(1.00, 0.98, 0.78) * razor_tip * brightness * 1.7;
		rgb += vec3(1.00, 0.92, 0.36) * arrow_head * brightness * 1.25;
		rgb += vec3(1.00, 0.58, 0.10) * afterimage * brightness * 0.55;
	} else if (style_mode == 1) {
		rgb += vec3(1.00, 0.72, 0.18) * feather * brightness * (1.05 + sacred_gold);
		rgb += vec3(1.00, 0.35, 0.04) * wing_mantle * brightness * 0.95;
		rgb += vec3(1.00, 0.88, 0.34) * feather_scatter * brightness * 1.35;
	} else {
		rgb += vec3(1.00, 0.24, 0.04) * ember * brightness * 1.28;
		rgb += vec3(0.95, 0.12, 0.02) * ash * brightness * 0.82;
		rgb += vec3(1.00, 0.48, 0.10) * max(ghost_outer, ghost_inner) * brightness * 0.62;
		rgb += vec3(1.00, 0.80, 0.28) * feather_scatter * brightness * 0.80;
		rgb += vec3(1.00, 0.74, 0.22) * feather_fan * brightness * 1.12;
	}
	rgb += vec3(1.00, 0.98, 0.62) * sparkle * brightness * 1.6;
	rgb += vec3(1.00, 0.34, 0.04) * shard * brightness * 1.15;
	rgb += vec3(1.00, 0.44, 0.02) * burst * brightness * 1.35;

	float alpha = max(max(max(body, brush_alpha), outer_border), max(max(max(feather, feather_scatter), feather_fan), max(sparkle, max(ember, max(ash, max(shard, burst))))));
	COLOR = vec4(rgb, alpha);
}
