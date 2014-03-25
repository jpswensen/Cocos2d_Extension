#ifdef GL_ES
precision highp float;
#endif

varying vec2 v_texCoord;

uniform float u_radius;

uniform sampler2D u_texture; // not sure where this comes from


#define M_PI 3.14159265358979323846

void main() {
    vec4 color = texture2D(u_texture,v_texCoord);
    
    float dx = v_texCoord.x - 0.5;
    float dy = v_texCoord.y - 0.5;
    
    float dmaxsquared = 0.5*0.5;
    float dminsquared = 0.15*0.15;
    float dsquared = dx*dx + dy*dy;
    
    if ( dsquared > dminsquared && dsquared < dmaxsquared )
    {
        float saturation = 2.0*sqrt(dsquared);
        float hue = (atan(dy,dx) + M_PI)*180.0/M_PI;
        float value = 1.0;
        
        float c = value * saturation;
        float h = hue/60.0;
        float x = c * (1.0 - abs( (mod(h,2.0) - 1.0)) );
        
        vec3 result;
        if (0.0 <= h && h < 1.0) {
            result = vec3(c, x, 0.0);
        } else if (1.0 <= h && h < 2.0) {
            result = vec3(x, c, 0.0);
        } else if (2.0 <= h && h < 3.0) {
            result = vec3(0.0, c, x);
        } else if (3.0 <= h && h < 4.0) {
            result = vec3(0.0, x, c);
        } else if (4.0 <= h && h < 5.0) {
            result = vec3(x, 0.0, c);
        } else if (5.0 <= h && h < 6.0) {
            result = vec3(c, 0.0, x);
        } else {
            result = vec3(0.0, 0.0, 0.0);
        }
        float Min = value - c;
        result.rgb += Min;
        
        gl_FragColor = vec4(result,1.0);
    }
    else
    {
        gl_FragColor = vec4(0.0,0.0,0.0,0.0); // turn everything transparent
    }
    
    
}