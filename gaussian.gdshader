shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;

const mat3 gaussian_3x3 = mat3(vec3(1.0, 2.0, 1.0), vec3(2.0, 4.0, 2.0), vec3(1.0, 2.0, 1.0));

const float sigma = 10.0;
const float coefficient = 1.0 / (2.0 * PI * sigma * sigma);

float gaussian(float x, float y){
	return coefficient * pow(E, -(x*x + y*y)/(2.0*sigma*sigma));
}

void fragment() {
	float total = 0.0;
	for(float i = -3.0 * sigma; i <= 3.0 * sigma; i ++){
		for(float j = -3.0 * sigma; j <= 3.0 * sigma; j++){
			total += texture(screen_texture, UV + vec2(SCREEN_PIXEL_SIZE.x * i, SCREEN_PIXEL_SIZE.y * j)).r * gaussian(i, j);
//			total += texture(screen_texture, UV + vec2(SCREEN_PIXEL_SIZE.x * float(i), SCREEN_PIXEL_SIZE.y * float(j))).r * gaussian_3x3[i + 1][j +1] / 16.0;
		}
	}
	COLOR.rgb = vec3(total);
}
