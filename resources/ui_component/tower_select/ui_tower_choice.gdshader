shader_type canvas_item;

uniform float radius : hint_range(0.0, 100.0) = 19.0;

void fragment() {
    vec2 size = vec2(1.0) / TEXTURE_PIXEL_SIZE;
    vec2 pos = UV * size;

    vec2 q = min(pos, size - pos);

    float alpha = 1.0;

    if (q.x < radius && q.y < radius) {
        vec2 corner = vec2(radius);
        if (distance(q, corner) > radius) {
            alpha = 0.0;
        }
    }

    vec4 tex = texture(TEXTURE, UV);
    COLOR = vec4(tex.rgb, tex.a * alpha);
}