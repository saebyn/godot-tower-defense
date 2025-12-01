shader_type spatial;
render_mode depth_draw_never, cull_back, unshaded;

uniform vec4 albedo_color : source_color = vec4(0.697, 0.521, 0.0, 1.0);
uniform float transparency : hint_range(0.0, 1.0) = 0.6;
uniform float dither_scale : hint_range(0.1, 4.0) = 1.0;

// Simple dither pattern for transparency without blending
float dither_pattern(vec2 coord) {
  // 4x4 Bayer matrix
  float bayer[16] = float[16](
    0.0/16.0, 8.0/16.0, 2.0/16.0, 10.0/16.0,
    12.0/16.0, 4.0/16.0, 14.0/16.0, 6.0/16.0,
    3.0/16.0, 11.0/16.0, 1.0/16.0, 9.0/16.0,
    15.0/16.0, 7.0/16.0, 13.0/16.0, 5.0/16.0
  );
  int x = int(coord.x) % 4;
  int y = int(coord.y) % 4;
  return bayer[y * 4 + x];
}

void fragment() {
  ALBEDO = albedo_color.rgb;
  
  // Discard pixels based on dither pattern to create transparency effect
  // without actual alpha blending - this prevents accumulation
  vec2 scaled_coord = FRAGCOORD.xy / dither_scale;
  float dither = dither_pattern(scaled_coord);
  if (dither > transparency) {
    discard;
  }
  
  ALPHA = 1.0; // Fully opaque for pixels that aren't discarded
}