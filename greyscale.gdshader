shader_type canvas_item;

void fragment() {
	vec4 raw_color = texture(TEXTURE, UV);
	COLOR = vec4(vec3(0.299*raw_color.r + 0.587*raw_color.g + 0.114*raw_color.b), raw_color.a);
}
