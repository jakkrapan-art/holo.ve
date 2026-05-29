shader_type canvas_item;
render_mode blend_add;

// ════════════════════════════════════════════════════════════════
// Kiara · Flame Slash — normal skill VFX
// A single leaf-tapered crescent blade swung along an arc (วงฟัน):
//   • blade reveals angularly front→tail, bounded clean tail (no
//     long faded drag), subtle fbm flame texture on the body
//   • white-hot→gold→orange→red gradient across the blade
//   • gold rim flares on the leading edge
//   • ember spray peels off behind the swing
//
// MULTI-LAYER composition (art direction): each element is its own
// premultiplied layer accumulated into `col`, with `a = max(...)`
// coverage — digital-art style stacking, never one flat field. New
// layers (sparks, smoke, decals) slot in by adding another block.
//
// Convention (amelia_skill_effect): progress 0→1 drives the swing,
// scale_p does the elastic pop-in. Author frame is horizontal; the
// controller (kiara_skill_effect.gd) rotates the rect to face the
// target lane and lands it on the 3×1 tile area.
// ════════════════════════════════════════════════════════════════

uniform float progress   : hint_range(0.0, 1.0) = 0.0;
uniform float scale_p    : hint_range(0.01, 1.2) = 1.0;
uniform float aspect     : hint_range(1.0, 4.0)  = 2.4;
uniform float arc_radius : hint_range(0.8, 4.0)  = 1.9;   // bigger = gentler curve
uniform float arc_span   : hint_range(0.3, 1.2)  = 0.62;  // half angular extent (rad)

const float APEX_Y   = -0.08;
const float TAIL_LEN = 0.95;   // blade length behind the swing front (rad) — bounds the tail

const vec3 C_CORE   = vec3(1.00, 0.99, 0.86);  // white-hot
const vec3 C_GOLD   = vec3(1.00, 0.82, 0.24);
const vec3 C_ORANGE = vec3(1.00, 0.43, 0.07);
const vec3 C_RED    = vec3(0.82, 0.11, 0.02);

float easeOut3(float t) { return 1.0 - pow(1.0 - t, 3.0); }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i),               hash(i + vec2(1.0, 0.0)), f.x),
	           mix(hash(i + vec2(0.0,1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) { v += a * noise(p); p *= 2.0; a *= 0.5; }
	return v;
}

void fragment() {
	vec2 uv = (UV - 0.5) * vec2(aspect, 1.0) / max(scale_p, 0.01);

	// ── Polar arc frame (centre below → bows up like ∩) ──────
	float R   = arc_radius;
	float cy  = APEX_Y + R;
	vec2  rel = uv - vec2(0.0, cy);
	float rr  = length(rel);
	float ang = atan(rel.x, -rel.y);   // 0 at apex, + to the right

	float swing     = easeOut3(clamp(progress / 0.45, 0.0, 1.0));
	float front_ang = mix(-arc_span - 0.12, arc_span + 0.12, swing);

	// ── Single crescent shape (leaf-tapered band) ────────────
	float an     = ang / arc_span;
	float tip    = sqrt(max(0.0, 1.0 - an * an));     // 0 at tips, 1 mid
	float half_t = 0.17 * tip;
	float d_band = abs(rr - R);
	float across = d_band / max(half_t, 1e-3);        // 0 centre → 1 edge
	float inSpan = step(abs(ang), arc_span + 0.04);
	float blade  = (1.0 - smoothstep(0.82, 1.0, across)) * inSpan;
	float reveal = 1.0 - smoothstep(front_ang, front_ang + 0.06, ang);

	// ── Trailing edge: clean cut a bounded distance behind the
	//    swing front (no long faded tail). Light flame texture
	//    only — flow kept subtle, never a dissolving fade. ──────
	float tail  = smoothstep(front_ang - TAIL_LEN, front_ang - TAIL_LEN + 0.20, ang);
	float nz    = fbm(vec2(ang * 4.0 - progress * 2.0, d_band * 8.0));
	float flame = mix(1.0, smoothstep(0.12, 0.62, nz), 0.28);  // subtle, keeps body solid
	float body  = blade * reveal * tail * flame;

	// hotter near the swing front
	float trail = smoothstep(front_ang - 1.0, front_ang, ang);

	vec3  col = vec3(0.0);
	float a   = 0.0;

	// ── LAYER 1 — flame body (gradient across the blade) ─────
	vec3 grad = C_CORE;
	grad = mix(grad, C_GOLD,   smoothstep(0.05, 0.35, across));
	grad = mix(grad, C_ORANGE, smoothstep(0.35, 0.70, across));
	grad = mix(grad, C_RED,    smoothstep(0.70, 1.00, across));
	col += grad * body * (1.4 + 1.0 * trail);
	a = max(a, body);

	// ── LAYER 2 — gold rim on the leading edge ──────────────
	float rim = smoothstep(0.10, 0.0, abs(ang - front_ang)) * blade;
	col += C_GOLD * rim * 2.2;
	a = max(a, rim);

	// ── LAYER 3 — ember spray peeling off behind ────────────
	vec2  eg     = uv * vec2(16.0, 12.0) + vec2(progress * 6.0, -progress * 3.0);
	vec2  cell   = floor(eg);
	vec2  lp     = fract(eg) - 0.5;
	float seed   = hash(cell);
	float behind = smoothstep(front_ang, front_ang - 1.3, ang) * step(ang, front_ang) * inSpan;
	float tw     = sin(progress * 6.28318 + seed * 6.28318) * 0.5 + 0.5;
	float ember  = step(0.90, seed) * (1.0 - smoothstep(0.0, 0.32, length(lp))) * behind * (0.4 + 0.6 * tw);
	col += C_ORANGE * ember * 1.8;
	a = max(a, ember);

	// ── Envelope + life applied to the whole stack ───────────
	float ex   = 1.0 - smoothstep(aspect * 0.5 - 0.12, aspect * 0.5 - 0.02, abs(uv.x));
	float ey   = 1.0 - smoothstep(0.44, 0.49, abs(uv.y));
	float life = smoothstep(0.0, 0.05, progress) * (1.0 - smoothstep(0.66, 1.0, progress));
	float mask = ex * ey * life;
	col *= mask;
	a   *= mask;

	COLOR = vec4(col, a);
}
