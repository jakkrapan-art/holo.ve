shader_type canvas_item;

uniform vec4 bg_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 border_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 image_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform float border_size : hint_range(1.0, 32.0) = 8.0;
uniform float corner_radius : hint_range(1.0, 64.0) = 26.0;
uniform float padding : hint_range(0.0, 64.0) = 12.0;

float rounded_box_sdf(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {

    vec2 size = vec2(1.0) / TEXTURE_PIXEL_SIZE;

    vec2 p = UV * size - size * 0.5;

    // rotate 45 degree
    float angle = radians(45.0);

    mat2 rot = mat2(
        vec2(cos(angle), sin(angle)),
        vec2(-sin(angle), cos(angle))
    );

    vec2 rp = rot * p;

    float shape_size = min(size.x, size.y) * 0.33;

    float d = rounded_box_sdf(
        rp,
        vec2(shape_size),
        corner_radius
    );

    // main diamond mask
    float shape_mask = 1.0 - smoothstep(
        0.0,
        1.5,
        d
    );

    // border mask
    float border_mask = 1.0 - smoothstep(
        border_size,
        border_size + 1.5,
        abs(d)
    );

    // ===== IMAGE =====

    // scale image inward with padding
    float image_scale = 1.0 - (padding / min(size.x, size.y));

    vec2 image_uv = (UV - 0.5) / image_scale + 0.5;

    vec4 tex = texture(TEXTURE, image_uv) * image_color;

    // remove outside uv
    if (
        image_uv.x < 0.0 ||
        image_uv.x > 1.0 ||
        image_uv.y < 0.0 ||
        image_uv.y > 1.0
    ) {
        tex.a = 0.0;
    }

    // ===== FINAL =====

    vec4 final_color = bg_color * shape_mask;

    // image inside
    final_color = mix(
        final_color,
        tex,
        tex.a * shape_mask
    );

    // border on top
    final_color.rgb = mix(
        final_color.rgb,
        border_color.rgb,
        border_mask * border_color.a
    );

    final_color.a = max(
        final_color.a,
        border_mask
    );

    COLOR = final_color;
}