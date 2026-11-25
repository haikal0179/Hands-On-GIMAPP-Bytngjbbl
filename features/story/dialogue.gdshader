shader_type canvas_item;

uniform float line_count : hint_range(40.0, 300.0) = 110.0;
uniform float line_opacity : hint_range(0.0, 1.0) = 0.32;
uniform vec4 tint_color : source_color = vec4(0.25, 1.0, 0.55, 1.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.10;

void fragment() {
	float wave = sin(UV.y * line_count * 6.28318);
	float is_line = step(0.0, wave);
	vec3 col = mix(tint_color.rgb, vec3(0.0), is_line * 0.85);
	float alpha = mix(tint_strength, line_opacity, is_line);
	COLOR = vec4(col, alpha);
}