attribute vec4 a_position; // kCCAttributeNamePosition
attribute vec2 a_texCoord; // kCCAttributeNameTexCoord

//uniform float u_radius;

varying mediump vec2 v_texCoord;
//varying float v_radius;

void main() {
    gl_Position = CC_MVPMatrix * a_position; // set the position
    v_texCoord = a_texCoord; // send the texture coordinates to the fragment shader
}