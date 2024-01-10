shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;

uniform float threshold = 0.1;

void fragment() {
	if(texture(screen_texture, UV).r < threshold){
		COLOR = vec4(vec3(0.0), texture(screen_texture, UV).a);
	}else{
		COLOR = vec4(vec3(1.0), texture(screen_texture, UV).a);
	}
}
