shader_type spatial;
render_mode blend_mix, depth_draw_opaque, depth_test_default, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform sampler2D Texture2DParameter : source_color, repeat_enable;

void fragment() {
  vec2 uv = UV;
  vec4 color;
  color = texture(Texture2DParameter, uv);

  ALBEDO = vec3(color.rgb);
}
