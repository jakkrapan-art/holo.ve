// Shared lane-effect shader helpers (Holo.Ve) - functions only, NO uniforms (each shader
// keeps its own uniforms + ranges). #include this into lane-static directional skill-VFX
// shaders so the bug-prone frame/origin math lives in ONE corner-free place.

// Soft fade-in at the lane origin. Replaces a hard step(0.0, lane_x) scissor at the caster,
// which clipped the head/tail into a hard edge. softness = fade band in lane-x units.
float lane_origin_gate(float lane_x, float softness) {
	return smoothstep(0.0, max(softness, 1e-4), lane_x);
}

// Corner-free frame vignette. Replaces the axis-aligned ex*ey product, which leaves straight
// rect edges + sharp corners (the recurring "rectangle behind the effect" bug).
// fade_x / fade_y = fade band width per axis in UV units (x measured past aspect*0.5,
// y past 0.5). IDENTICAL to ex*ey ON the edges (fy=0 -> 1-fx; fx=0 -> 1-fy) where content
// lives; only the corner (both axes fading at once) is rounded by the Euclidean combine,
// so a square corner can never appear.
float lane_frame_mask(vec2 uv, float aspect, float fade_x, float fade_y) {
	float fx = smoothstep(aspect * 0.5 - fade_x, aspect * 0.5, abs(uv.x));
	float fy = smoothstep(0.5 - fade_y, 0.5, abs(uv.y));
	return 1.0 - min(1.0, length(vec2(fx, fy)));
}

// Lane coordinate: UV.x -> lane-x in [-lane_pad, 1+lane_pad] (0 = caster/muzzle, 1 = range
// end), and lane-y centred at 0. The standard mapping every lane shader hand-rolled.
vec2 lane_coord(vec2 uv_in, float lane_pad) {
	return vec2(mix(-lane_pad, 1.0 + lane_pad, uv_in.x), uv_in.y - 0.5);
}
