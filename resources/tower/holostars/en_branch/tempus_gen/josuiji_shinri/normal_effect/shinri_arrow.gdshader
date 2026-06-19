shader_type canvas_item;
render_mode blend_add;

// Josuiji Shinri - normal-attack bullet (dynamic arrow). First production bullet drawn
// entirely in-shader (no sprite texture sampled, so no black rim), mirroring Watson
// Amelia's Soft Glow. A swept arrowHEAD (triangle minus a back notch -> two arms + concave
// back) UNIONed with a thin TAIL spike that tapers to a back point + a soft additive glow.
// STATIC by design (no internal TIME) - the motion is the projectile's transform. The bullet
// .tscn quad is authored WIDE (154x64) so the long axis = local +X = travel/forward; the
// Projectile node (projectile.gd) rotates to face its target. White/blue-white only =>
// blend_add is safe (shader.md). Do NOT use MODULATE (custom-COLOR fragment won't apply it).
//
// attack_controller._applyBulletVisual pushes core_color / mid_color / glow_softness from the
// tower's attack_config (YAML). arm_hh / notch / tail_hh / intensity are NOT pushed, so their
// defaults below ARE the shipped shape (V1) - tune the shape here, tune colour/glow in YAML.

uniform vec4  core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4  mid_color  : source_color = vec4(0.90, 0.94, 1.0, 1.0);
uniform float arm_hh  : hint_range(0.25, 0.50) = 0.46;     // arrowhead arm spread (half-height)
uniform float notch   : hint_range(0.0, 0.85) = 0.50;      // back V-notch depth (arm separation)
uniform float tail_hh : hint_range(0.03, 0.20) = 0.11;     // tail spike thickness
uniform float glow_softness : hint_range(0.0, 0.5) = 0.12; // glow halo width past the silhouette
uniform float intensity : hint_range(0.0, 2.5) = 1.20;     // baked (config never pushes this)
uniform float alpha_mul : hint_range(0.0, 1.0) = 1.0;      // spawn-in / fade hook

void fragment() {
	vec2 q = UV - 0.5;          // -0.5..0.5; +x = forward (tip), y = across
	float ay = abs(q.y);
	float aa = 0.010;

	float tipx  = 0.48;         // front point
	float hbx   = -0.10;        // arrowhead base x (arm tips sit here, swept back)
	float tailx = -0.48;        // tail back point
	float tf    = 0.06;         // tail front x (overlaps the head base so they fuse)

	// ARROWHEAD: outer triangle (tip -> base) minus a back notch = two swept arms.
	float in_head = step(hbx, q.x) * step(q.x, tipx);
	float oh = arm_hh * clamp((tipx - q.x) / (tipx - hbx), 0.0, 1.0);
	float outer = (1.0 - smoothstep(oh - aa, oh + aa, ay)) * in_head;
	float nx = mix(hbx, tipx - 0.08, notch);
	float in_notch = step(hbx, q.x) * step(q.x, nx);
	float nh = arm_hh * clamp((nx - q.x) / max(nx - hbx, 0.001), 0.0, 1.0);
	float notch_a = (1.0 - smoothstep(nh - aa, nh + aa, ay)) * in_notch;
	float head = clamp(outer - notch_a, 0.0, 1.0);

	// TAIL: thin spike tapering from the head base to a back point.
	float in_tail = step(tailx, q.x) * step(q.x, tf);
	float th = tail_hh * clamp((q.x - tailx) / (tf - tailx), 0.0, 1.0);
	float tail = (1.0 - smoothstep(th - aa, th + aa, ay)) * in_tail;

	float body = clamp(max(head, tail), 0.0, 1.0);

	// GLOW: halo hugging the outer silhouette (arms + tail), kept out of the carved notch.
	float head_glow = clamp((1.0 - smoothstep(oh, oh + glow_softness, ay)) * in_head - notch_a, 0.0, 1.0);
	float tail_glow = (1.0 - smoothstep(th, th + glow_softness, ay)) * in_tail;
	float glow = max(head_glow, tail_glow);
	float tip_bloom = (1.0 - smoothstep(0.0, 0.09, length(q - vec2(tipx, 0.0)))) * 0.35;

	float a = clamp(max(body, max(glow * 0.5, tip_bloom)), 0.0, 1.0);
	vec3 col = mix(mid_color.rgb, core_color.rgb, body) * intensity;
	COLOR = vec4(col, a * alpha_mul);
}
