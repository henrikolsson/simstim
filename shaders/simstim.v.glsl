#version 150 
in vec3 vert;

void main(void) {                        
    gl_Position = vec4(vert, 1);
}
