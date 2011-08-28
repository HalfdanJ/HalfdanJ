#extension GL_ARB_texture_rectangle : enable
uniform sampler2DRect src_tex_unit0;
uniform sampler2DRect texRamp;
uniform sampler2DRect texBG;
uniform float inputGain;

void main()
{
 	vec4 i = texture2DRect(texBG, gl_TexCoord[0].st)-texture2DRect(src_tex_unit0, gl_TexCoord[0].st);	
	i.a = 1.0;
	i.rgb *= inputGain;
	
	vec4 color = vec4(texture2DRect(texRamp, vec2(i.r*255.0,0.0)).r, texture2DRect(texRamp, vec2(i.g*255.0,0.0)).g , texture2DRect(texRamp, vec2(i.b*255.0,0.0)).b ,1);

	//gl_FragColor = texture2DRect(texBG, gl_TexCoord[0].st) ;
	gl_FragColor  = vec4(color.r,color.g*1.0,color.b*1.0,1);
}
