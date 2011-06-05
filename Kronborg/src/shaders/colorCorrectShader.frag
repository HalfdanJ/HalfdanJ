uniform sampler2DRect src_tex_unit0;
uniform float min;
uniform float max;

uniform vec2 start;
uniform vec2 middle;
uniform vec2 end;

vec2 bezier(float t){
	return (1.0-t)*(1.0-t)*start + 2.0*t*(1.0-t)*middle + t*t*end;
}

void main( void )
{  
	vec2 st = gl_TexCoord[0].st;
	
	vec4 color = texture2DRect(src_tex_unit0, st );
    
	vec2 ret = bezier(color.r);
	color.r = ret.y;
    
	ret = bezier(color.g);
	color.g = ret.y;
    
	ret = bezier(color.b);
	color.b = ret.y;
	
	float size = max - min;	
	color.rgb -= vec3(min);	
	color.rgb /= vec3(size);	
    
	gl_FragColor = color;
}