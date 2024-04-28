shader_type canvas_item;

uniform sampler2D flood_image;

void fragment() {
	if(texture(flood_image, UV).r > 0.9 && texture(flood_image, UV).b < 0.1){
		//COLOR.rgba = vec4(1.0, 0.0, 0.0, 1.0);
		COLOR.rgb = mix(COLOR.rgb, vec3(1.0, 0.0, 0.0), 0.3);
	}
	//else{
		//COLOR.rgb = vec3(0.0);
	//}
	
//	COLOR.rgb = mix(COLOR.rgb, vec3(1.0, 0.0, 0.0), (1.0 - texture(flood_image, UV).r) / 5.0);
//
//	COLOR = texture(flood_image, UV);
}
