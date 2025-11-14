#version 330 core

out vec4 FragColor;

in vec3 Normal;
in vec3 FragPos;
in vec2 TexCoord;

uniform vec3 viewer_pos;

uniform vec3 light_pos;
uniform vec3 light_ambient;
uniform vec3 light_diffuse;
uniform vec3 light_specular;
uniform float light_gain;

uniform sampler2D diffuse_map;
uniform sampler2D specular_map;

uniform float material_shininess;

void main() {

	vec3 ambient_light = vec3(texture(diffuse_map, TexCoord)) * light_ambient;


	vec3 light_dir          = normalize(light_pos - FragPos);
	vec3 norm               = normalize(Normal);

	float diffuse_magnitude = max(dot(norm, light_dir), 0.0);

	vec3 diffuse_light      = texture(diffuse_map, TexCoord).rgb * (diffuse_magnitude * light_diffuse);

	
	vec3 view_dir    = normalize(viewer_pos - FragPos);
	vec3 reflect_dir = reflect(-light_dir, norm);

	float specular_magnitude = pow(max(dot(view_dir, reflect_dir), 0.0), material_shininess);

	vec3 specular_light = light_specular * specular_magnitude * texture(specular_map, TexCoord).rgb;


	vec3 result = light_gain * (ambient_light + diffuse_light + 
		specular_light);

	FragColor = vec4(result, 1.0);
} 