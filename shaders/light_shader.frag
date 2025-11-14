#version 330 core

out vec4 FragColor;

uniform vec3 light_color_diff;
uniform vec3 light_color_spec;
uniform float gain;

void main() {

	vec3 light_color = (0.25 * light_color_diff + 0.75 * light_color_spec) * gain;
	FragColor = vec4(light_color, 1);
} 