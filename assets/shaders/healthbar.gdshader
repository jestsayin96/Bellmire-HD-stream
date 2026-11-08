shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled, shadows_disabled;
// One quad that always faces the camera; the fill is drawn in the fragment
// so a single shared material serves every bar (per-bar values are instance uniforms).
instance uniform float fill : hint_range(0.0, 1.0) = 1.0;
instance uniform float hostile = 0.0;
void vertex() {
    MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
    MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}
void fragment() {
    vec2 uv = UV;
    float bx = 0.035;
    float by = 0.22;
    bool border = uv.x < bx || uv.x > 1.0 - bx || uv.y < by || uv.y > 1.0 - by;
    float inner_x = (uv.x - bx) / (1.0 - 2.0 * bx);
    vec3 good = hostile > 0.5 ? vec3(0.86, 0.22, 0.18) : vec3(0.25, 0.85, 0.30);
    vec3 low = hostile > 0.5 ? vec3(0.55, 0.10, 0.08) : vec3(0.95, 0.25, 0.15);
    vec3 mid = hostile > 0.5 ? vec3(0.80, 0.30, 0.15) : vec3(0.95, 0.80, 0.20);
    vec3 col = fill > 0.5 ? mix(mid, good, (fill - 0.5) * 2.0) : mix(low, mid, fill * 2.0);
    if (border) {
        ALBEDO = vec3(0.04);
    } else if (inner_x <= fill) {
        ALBEDO = col;
    } else {
        ALBEDO = vec3(0.12, 0.10, 0.10);
    }
    ALPHA = 0.92;
}
