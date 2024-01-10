shader_type canvas_item;


const mat3 basic_laplacian = mat3(vec3(0.0, 1.0, 0.0), vec3(1.0, -4.0, 1.0), vec3(0.0, 1.0, 0.0));
const mat3 stable_laplacian = mat3(vec3(0.25, 0.5, 0.25), vec3(0.5, -3.0, 0.5), vec3(0.25, 0.5, 0.25));

const mat3 gaussian = mat3(vec3(1.0, 2.0, 1.0), vec3(2.0, 4.0, 2.0), vec3(1.0, 2.0, 1.0)) / 16.0;

void fragment() {
	//Laplacian
	float total = 
	for(int i = 0; i < 3; i ++){
		for(int j = 0; j < 3; j++){
			
		}
	}
	
	//Gaussian
	
	//Threshold
}
