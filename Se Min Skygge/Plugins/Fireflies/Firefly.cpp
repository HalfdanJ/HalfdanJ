#include "Firefly.h"


Firefly::Firefly(){

}

void Firefly::update(float step, int frameNum){
    //
    // Perlin
    //
    float div = *perlinSpeed*100.0; 
    float posX = noise->noise(pos.x* *perlinGridsize*10.0, pos.y* *perlinGridsize*10.0, (float)frameNum/div);
    float posY = noise->noise(pos.x* *perlinGridsize*10.0, pos.y* *perlinGridsize*10.0, (float)(frameNum+200)/div);
    float posZ = noise->noise(pos.x* *perlinGridsize*10.0, pos.y* *perlinGridsize*10.0, (float)(frameNum+1000)/div);
    
    a += ofxVec3f(posX,posY,posZ)* *perlinForce*0.06;     

    
    //
    // Center gravity
    //
    a += -pos * *gravityForce*0.01;
    
    
    //
    // Wortex force
    //
    ofxVec2f v1 = ofxVec2f(-pos.z, pos.x).normalize();
    ofxVec3f v2 = ofxVec3f(v1.x, 0, v1.y);
    a += v2 * *wortexForce;
    
    
    v += step*a;
    v *= 1.0- *damping*0.2;
    pos += v;
                           
    a = ofxVec3f();
    
    opacity = noise->noiseuf((float)(frameNum+2000)/((1-*opacitySpeed)*10.0), i*10.0) * *opacityNoise + (1-  *opacityNoise);
}

void Firefly::draw(bool front){
    float aa = pos.z*5;
    if(!front){
        aa = -pos.z*5;
    }
    aa = ofClamp(aa, 0, 1);
    aa *= opacity;
    
    ofSetColor(255,255,255,aa*255.0);
    glBlendFunc(GL_ONE, GL_ONE);
    glBlendFunc(GL_SRC_ALPHA,GL_ONE);
    
    float size = 1 + pos.z*0.5;
//    ofCircle(pos.x,pos.y,0.02);   
    glPushMatrix();
    glTranslated(pos.x, pos.y,0);
    glRotated(i*21.120123, 0,0,1);
    img->draw(0,0, 0.02*size, 0.02*size);
    glPopMatrix();
}


