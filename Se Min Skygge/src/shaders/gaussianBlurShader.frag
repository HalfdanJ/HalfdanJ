uniform float sigma;     // The sigma value for the gaussian function: higher value means more blur
// A good value for 9x9 is around 3 to 5
// A good value for 7x7 is around 2.5 to 4
// A good value for 5x5 is around 2 to 3.5
// ... play around with this based on what you need :)

uniform float blurSize;  // This should usually be equal to
// 1.0f / texture_pixel_width for a horizontal blur, and
// 1.0f / texture_pixel_height for a vertical blur.

uniform sampler2DRect blurSampler;  // Texture that will be blurred by this shader

uniform float direction;

const float pi = 3.14159265;

void main() {
	float numBlurPixelsPerSide = 6.0;
	vec2  blurMultiplyVec      = vec2(1.0, 0.0);

    if(direction == 0.0){
		numBlurPixelsPerSide = 6.0;
		blurMultiplyVec      = vec2(0.0, 1.0);
	}
    // Incremental Gaussian Coefficent Calculation (See GPU Gems 3 pp. 877 - 889)
    vec3 incrementalGaussian;
    incrementalGaussian.x = 1.0 / (sqrt(2.0 * pi) * sigma);
    incrementalGaussian.y = exp(-0.5 / (sigma * sigma));
    incrementalGaussian.z = incrementalGaussian.y * incrementalGaussian.y;
    
    vec4 avgValue = vec4(0.0, 0.0, 0.0, 0.0);
    float coefficientSum = 0.0;
    
    // Take the central sample first...
    avgValue += texture2DRect(blurSampler, gl_TexCoord[0].st) * incrementalGaussian.x;
    coefficientSum += incrementalGaussian.x;
    incrementalGaussian.xy *= incrementalGaussian.yz;
    
    // Go through the remaining 8 vertical samples (4 on each side of the center)
    for (float i = 1.0; i <= numBlurPixelsPerSide; i++) { 

        avgValue += texture2DRect(blurSampler, gl_TexCoord[0].st - i * blurSize * 
                              blurMultiplyVec) * incrementalGaussian.x;         

        avgValue += texture2DRect(blurSampler, gl_TexCoord[0].st + i * blurSize * 
                              blurMultiplyVec) * incrementalGaussian.x;         
        coefficientSum += 2.0 * incrementalGaussian.x;
        incrementalGaussian.xy *= incrementalGaussian.yz;
    }
    
    gl_FragColor = avgValue / coefficientSum;
//gl_FragColor.g = 0.0;	
}
