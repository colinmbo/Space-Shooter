shader_type canvas_item;

uniform vec4 color : source_color;
uniform float scale = 0.0;
uniform float fade_inner_dist = 0.1;
uniform float fade_outer_dist = 0.1;

void fragment() {
	float value = distance(UV, vec2(0.5));
	COLOR = vec4(color.rgb, smoothstep(scale-fade_inner_dist, scale+fade_outer_dist, value));
	
}
