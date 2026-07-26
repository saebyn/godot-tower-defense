shader_type spatial;

uniform vec4 base_color : source_color = vec4(0.1, 0.1, 0.1, 1.0);
uniform vec4 inner_line_color : source_color;
uniform vec4 outer_line_color : source_color;

void fragment() {
  vec2 uv = UV;
  vec4 color;
  
  float x = uv.x;
  float y = uv.y;
  
  if (y > 0.91 && y <= 0.95 || y > 0.05 && y <= 0.09) {
    color = outer_line_color;
  } else if (y > 0.47 && y < 0.49 || y > 0.51 && y < 0.53) {
    color = inner_line_color;
  } else {
    color = base_color;
  }
  
  ALBEDO = vec3(color.rgb);
}
