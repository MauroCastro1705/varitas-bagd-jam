shader_type canvas_item;
render_mode unshaded;

uniform float outline_width : hint_range(0.0, 32.0) = 4.0;
uniform vec4 outline_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// AtlasTexture region in atlas pixels
uniform vec2 atlas_region_pos = vec2(0.0);
uniform vec2 atlas_region_size = vec2(1.0);
uniform vec2 draw_size = vec2(1.0);

varying vec2 expanded_local_uv;
varying vec4 item_modulate;

vec2 resolved_region_size(vec2 atlas_size) {
    return atlas_region_size.x > 1.0 && atlas_region_size.y > 1.0
        ? atlas_region_size
        : atlas_size;
}

void vertex() {
    vec2 atlas_size = vec2(1.0) / TEXTURE_PIXEL_SIZE;
    vec2 region_size = resolved_region_size(atlas_size);
    vec2 region_uv_pos = atlas_region_pos / atlas_size;
    vec2 region_uv_size = region_size / atlas_size;
    
    // CALCULAR UV EXPANDIDO SIN MODIFICAR VERTEX
    expanded_local_uv = (UV - region_uv_pos) / region_uv_size;
    item_modulate = COLOR;
    
    // ELIMINAR LA MODIFICACIÓN DE VERTEX QUE ACHICA LA TEXTURA
    // VERTEX += (expanded_local_uv * 2.0 - 1.0) * outline_width;
}

void fragment() {
    vec2 atlas_size = vec2(1.0) / TEXTURE_PIXEL_SIZE;
    vec2 region_size = resolved_region_size(atlas_size);
    vec2 resolved_draw_size = max(draw_size, vec2(1.0));
    vec2 outline_size = vec2(outline_width);
    vec2 expanded_draw_size = resolved_draw_size + outline_size * 2.0;

    // Outline geometry and sampling use node-local draw pixels
    vec2 draw_pixel = expanded_local_uv * expanded_draw_size - outline_size;
    bool inside_source =
        draw_pixel.x >= 0.0 &&
        draw_pixel.y >= 0.0 &&
        draw_pixel.x < resolved_draw_size.x &&
        draw_pixel.y < resolved_draw_size.y;

    vec4 sampled_rgba = vec4(0.0);
    if (inside_source) {
        vec2 region_pixel = draw_pixel / resolved_draw_size * region_size;
        vec2 safe_pixel = clamp(region_pixel, vec2(0.5), region_size - vec2(0.5));
        sampled_rgba = texture(TEXTURE, (atlas_region_pos + safe_pixel) / atlas_size);
    }

    float outline_alpha = 0.0;
    if (outline_width > 0.0) {
        const int direction_count = 16;
        const int step_count = 4;
        for (int direction_index = 0; direction_index < direction_count; direction_index++) {
            float angle = TAU * float(direction_index) / float(direction_count);
            vec2 direction = vec2(cos(angle), sin(angle));
            for (int step_index = 1; step_index <= step_count; step_index++) {
                float step_ratio = float(step_index) / float(step_count);
                vec2 sample_draw_pixel = draw_pixel + direction * outline_size * step_ratio;
                bool sample_inside =
                    sample_draw_pixel.x >= 0.0 &&
                    sample_draw_pixel.y >= 0.0 &&
                    sample_draw_pixel.x < resolved_draw_size.x &&
                    sample_draw_pixel.y < resolved_draw_size.y;
                if (sample_inside) {
                    vec2 sample_pixel = sample_draw_pixel / resolved_draw_size * region_size;
                    vec2 safe_sample_pixel = clamp(sample_pixel, vec2(0.5), region_size - vec2(0.5));
                    outline_alpha = max(
                        outline_alpha,
                        texture(TEXTURE, (atlas_region_pos + safe_sample_pixel) / atlas_size).a);
                }
            }
        }
    }

    outline_alpha *= outline_tint.a * (1.0 - sampled_rgba.a);
    vec4 result_rgba = vec4(outline_tint.rgb, outline_alpha);
    result_rgba.rgb = mix(result_rgba.rgb, sampled_rgba.rgb, sampled_rgba.a);
    result_rgba.a = sampled_rgba.a + outline_alpha;
    COLOR = result_rgba * item_modulate;
}