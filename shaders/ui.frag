#version 330 core

in vec2 vUV;
in vec4 vColor;

uniform sampler2D uTex;

out vec4 FragColor;

void main() {
        float alpha = texture(uTex, vUV).r;
        FragColor = vec4(vColor.rgb, vColor.a * alpha);
}