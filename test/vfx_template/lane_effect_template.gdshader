shader_type canvas_item;
// blend_add suits bright/warm palettes. If the palette has DARK bands
// (violet/crimson/deep magenta), switch to blend_premul_alpha - blend_add
// only ADDS luminance, so dark bands vanish over the lit map (Kiara
// Hinotori lesson, docs/shader.md Section 3). Verify over the real map.
render_mode blend_add;

#include "res://resources/tower/shared/lane_fx.gdshaderinc"

// ================================================================
// LANE SKILL-VFX SHADER TEMPLATE (copy me) - godot-2dfx skill
// Placeholder look: a bolt rushing down the lane with a bounded trail,
// white-hot core, and spark scatter. Replace the LAYER blocks with the
// real effect; keep the frame/envelope structure.
//
// Rules baked in (docs/shader.md Section 2 + lane checklist):
//   - progress / scale_p uniforms drive ALL motion - never TIME
//   - lane_coord / lane_origin_gate / lane_frame_mask come from the
//     shared include - never hand-roll frame/origin math, never step()
//     at the origin or a step()-bounded content fill
//   - multi-layer: each element adds into col, coverage a = max(...)
//   - bounded tail: clean cut behind the head, no long faded drag
// ================================================================

// REQUIRED on every skill effect (docs/shader.md Section 2):
uniform float progress : hint_range(0.0, 1.0) = 0.0;   // whole sequence (controller tween)
uniform float scale_p  : hint_range(0.01, 1.2) = 1.0;  // elastic pop-in
uniform float aspect   : hint_range(1.0, 6.0)  = 2.8;  // rect width/height (controller passes)
uniform float lane_pad : hint_range(0.0, 1.0)  = 0.25; // MUST match controller LANE_PAD

// Effect-specific tunables - rename/replace for your effect, keep them uniforms:
uniform vec4  core_color : source_color = vec4(1.0, 0.97, 0.82, 1.0);
uniform vec4  rim_color  : source_color = vec4(1.0, 0.70, 0.22, 1.0);
uniform float bolt_len   : hint_range(0.1, 1.2)  = 0.45; // trail length behind the head (lane units)
uniform float bolt_hw    : hint_range(0.05, 0.5) = 0.16; // bolt half-width (lane-y units)

float easeOut3(float t) { return 1.0 - pow(1.0 - t, 3.0); }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	// aspect-true author frame for the vignette (pop scales the frame)
	vec2 uv = (UV - 0.5) * vec2(aspect, 1.0) / max(scale_p, 0.01);
	// gameplay-true lane coords: x 0 = caster -> 1 = range end, y centred at 0
	vec2 lane = lane_coord(UV, lane_pad);
	// pop the THICKNESS only - the footprint along the lane stays true
	float ly = lane.y / max(scale_p, 0.01);

	// head rushes caster -> range end (all motion from progress, never TIME)
	float head = easeOut3(progress) * (1.0 + lane_pad * 0.5);
	float dx = lane.x - head;

	// bolt body: bounded trail behind the head, soft origin, no step()
	float across  = abs(ly) / max(bolt_hw, 1e-3);
	float width_m = 1.0 - smoothstep(0.55, 1.0, across);
	float front   = 1.0 - smoothstep(0.0, 0.04, dx);
	float tail    = smoothstep(head - bolt_len, head - bolt_len + 0.14, lane.x);
	float body    = width_m * front * tail * lane_origin_gate(lane.x, 0.15);

	vec3 col = vec3(0.0);
	float a = 0.0;

	// LAYER 1 - coloured body
	col += rim_color.rgb * body * 1.1;
	a = max(a, body * 0.85);

	// LAYER 2 - white-hot core + head flash (energy focal point)
	float core = (1.0 - smoothstep(0.0, 0.45, across)) * body;
	float head_glow = 1.0 - smoothstep(0.0, 0.20, length(vec2(dx * 0.8, ly)));
	head_glow *= lane_origin_gate(lane.x, 0.1);
	col += core_color.rgb * (core * 1.5 + head_glow * 2.2);
	a = max(a, max(core, head_glow));

	// LAYER 3 - spark scatter peeling off behind the head
	vec2 sg = vec2(lane.x * 9.0, ly * 7.0);
	vec2 cellv = floor(sg);
	vec2 lp = fract(sg) - 0.5;
	float seed = hash(cellv);
	float behind = smoothstep(head, head - bolt_len * 1.7, lane.x) * (1.0 - smoothstep(0.0, 0.02, dx));
	float tw = sin(progress * 12.6 + seed * 6.28) * 0.5 + 0.5;
	float spread = 1.0 - smoothstep(1.2, 2.4, across);
	float spark = step(0.88, seed) * (1.0 - smoothstep(0.0, 0.30, length(lp))) * behind * tw * spread;
	spark *= lane_origin_gate(lane.x, 0.15);
	col += rim_color.rgb * spark * 1.6;
	a = max(a, spark);

	// envelope: fade-in, fade-out, corner-free frame - applied to the stack
	float life = smoothstep(0.0, 0.06, progress) * (1.0 - smoothstep(0.72, 1.0, progress));
	float mask = lane_frame_mask(uv, aspect, 0.14, 0.10) * life;
	col *= mask;
	a *= mask;

	COLOR = vec4(col, a);
}
