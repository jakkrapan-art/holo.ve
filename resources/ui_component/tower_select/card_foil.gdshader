shader_type canvas_item;

// Rainbow foil sheen for the EVOLVE tower-select card (subtle, seamless loop).
// Lives on a ColorRect overlay above the portrait: a ColorRect has no TEXTURE,
// so the card size arrives via rect_size for the rounded-corner mask, which
// must match ui_tower_choice.gdshader (same radius) or the foil leaks past the
// card corners.
uniform vec2 rect_size = vec2(300.0, 440.0);
uniform float radius : hint_range(0.0, 100.0) = 19.0;
uniform float strength : hint_range(0.0, 1.0) = 0.16;
uniform float speed : hint_range(0.0, 2.0) = 0.25;
uniform float bands : hint_range(0.5, 6.0) = 1.5;

void fragment() {
    vec2 pos = UV * rect_size;
    vec2 q = min(pos, rect_size - pos);
    float mask = 1.0;
    if (q.x < radius && q.y < radius && distance(q, vec2(radius)) > radius) {
        mask = 0.0;
    }

    // Diagonal hue position; fract() keeps the TIME loop seamless.
    float d = fract((UV.x + UV.y) * bands * 0.5 - TIME * speed);
    vec3 rainbow = clamp(abs(mod(d * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    // Soft sheen band riding the hue cycle so the sweep reads as light, not tint.
    float sheen = smoothstep(0.35, 0.5, d) * smoothstep(0.65, 0.5, d);
    COLOR = vec4(rainbow, strength * (0.55 + 0.45 * sheen) * mask);
}
