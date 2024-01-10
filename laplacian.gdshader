shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;

const mat3 basic_laplacian = mat3(vec3(0.0, 1.0, 0.0), vec3(1.0, -4.0, 1.0), vec3(0.0, 1.0, 0.0));
const mat3 stable_laplacian = mat3(vec3(0.25, 0.5, 0.25), vec3(0.5, -3.0, 0.5), vec3(0.25, 0.5, 0.25));
const mat3 generalized_laplacian = mat3(vec3(-1.0, -1.0, -1.0), vec3(-1.0, 8.0, -1.0), vec3(-1.0, -1.0, -1.0));

void fragment() {
	float total = 0.0;
	for(int i = -1; i <= 1; i ++){
		for(int j = -1; j <= 1; j++){
			total += texture(screen_texture, UV + vec2(SCREEN_PIXEL_SIZE.x * float(i), SCREEN_PIXEL_SIZE.y * float(j))).r * generalized_laplacian[i + 1][j +1];
		}
	}
	COLOR.rgb = vec3(total);
}
