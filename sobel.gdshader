shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;

const mat3 sobel_h = mat3(vec3(1.0, 2.0, 1.0), vec3(0.0), vec3(-1.0, -2.0, -1.0));
const mat3 sobel_v = mat3(vec3(1.0, 0.0, -1.0), vec3(2.0, 0.0, -2.0), vec3(1.0, 0.0, -1.0));

void fragment() {
	float average_h = 0.0;
	float average_v = 0.0;
	for(int i = -1; i <= 1; i ++){
		for(int j = -1; j <= 1; j++){
			average_h += texture(screen_texture, UV + vec2(SCREEN_PIXEL_SIZE.x * float(i), SCREEN_PIXEL_SIZE.y * float(j))).r * sobel_h[i + 1][j +1];
			average_v += texture(screen_texture, UV + vec2(SCREEN_PIXEL_SIZE.x * float(i), SCREEN_PIXEL_SIZE.y * float(j))).r * sobel_v[i + 1][j +1];
		}
	}
	float average = sqrt(average_h * average_h + average_v * average_v);
	COLOR.rgb = vec3(average);
}
