shader_type canvas_item;

// Inspect-highlight outline (ui.md): silhouette border drawn on the sprite of
// the tower/enemy currently selected into a stats panel. First character-sprite
// shader in the project - assigned/removed at runtime by the two stats panels.
//
// Works on BOTH sprite kinds with no hardcoded asset dimensions:
// - AnimatedSprite2D whose frames are AtlasTexture regions on a packed sheet
//   (region_uv = current frame rect, script-fed on frame/animation change), and
// - plain Sprite2D full textures (region_uv = 0,0,1,1).
// The quad is grown by grow_px so the line survives art that touches the frame
// edge (Altare idle sheet, all enemy PNGs); sampling is contracted back around
// the frame center per-axis, which reproduces the un-grown mapping exactly, so
// the art keeps its original on-screen size and position. Samples outside the
// frame rect read as transparent - both the cross-frame bleed guard and the
// clamp-to-edge smear guard.
//
// Grow direction comes from vertex positions, NOT UV: flip_h swaps UVs, so a
// UV-derived direction would invert the grow on flipped (right-facing) enemies.
// quad_center_px = the sprite's `offset` (a centered sprite's quad center).

uniform vec4 line_color : source_color = vec4(0.85, 0.95, 1.0, 1.0);
uniform float thickness_px : hint_range(1.0, 12.0) = 4.0;
uniform float grow_px = 6.0; // keep >= thickness_px + 2 so the line never clips
uniform vec4 region_uv = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec2 quad_center_px = vec2(0.0, 0.0);
uniform float pulse_speed = 5.2; // rad/s (~1.2s cycle); 0.0 = static line
uniform float pulse_min : hint_range(0.0, 1.0) = 0.65;

const vec2 DIRS[8] = {
	vec2(1.0, 0.0), vec2(-1.0, 0.0), vec2(0.0, 1.0), vec2(0.0, -1.0),
	vec2(0.7071, 0.7071), vec2(0.7071, -0.7071),
	vec2(-0.7071, 0.7071), vec2(-0.7071, -0.7071)
};

void vertex() {
	VERTEX += sign(VERTEX - quad_center_px) * grow_px;
}

float frame_alpha(sampler2D tex, vec2 uv) {
	vec2 rmin = region_uv.xy;
	vec2 rmax = region_uv.xy + region_uv.zw;
	if (uv.x < rmin.x || uv.y < rmin.y || uv.x > rmax.x || uv.y > rmax.y) {
		return 0.0;
	}
	return texture(tex, uv).a;
}

void fragment() {
	// Contract sampling around the frame center to undo the vertex growth
	// (per-axis: enemy textures are non-square).
	vec2 cell_center = region_uv.xy + region_uv.zw * 0.5;
	vec2 cell_px = region_uv.zw / TEXTURE_PIXEL_SIZE;
	vec2 sample_uv = cell_center + (UV - cell_center) * (cell_px + 2.0 * grow_px) / cell_px;

	vec4 base = texture(TEXTURE, sample_uv);
	// Outside the frame rect the sprite contributes nothing.
	vec2 rmin = region_uv.xy;
	vec2 rmax = region_uv.xy + region_uv.zw;
	if (sample_uv.x < rmin.x || sample_uv.y < rmin.y || sample_uv.x > rmax.x || sample_uv.y > rmax.y) {
		base = vec4(0.0);
	}

	float neighbor = 0.0;
	vec2 t = thickness_px * TEXTURE_PIXEL_SIZE;
	for (int i = 0; i < 8; i++) {
		neighbor = max(neighbor, frame_alpha(TEXTURE, sample_uv + DIRS[i] * t));
	}

	float pulse = 1.0;
	if (pulse_speed > 0.0) {
		pulse = mix(pulse_min, 1.0, 0.5 + 0.5 * sin(TIME * pulse_speed));
	}
	// Line only where the sprite itself is (mostly) transparent; smoothstep
	// keeps the edge soft against semi-transparent art pixels.
	float line_mask = smoothstep(0.3, 0.6, neighbor) * (1.0 - smoothstep(0.3, 0.6, base.a));
	vec4 line = vec4(line_color.rgb, line_color.a * line_mask * pulse);

	COLOR = mix(line, base, base.a);
}
