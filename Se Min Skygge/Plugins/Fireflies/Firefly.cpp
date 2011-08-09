#include "Firefly.h"


Firefly::Firefly(){

}

void Firefly::update(float step, int frameNum){
    //
    // Perlin
    //
    float div = 100; 
    float posX = noise->noise(pos.x*10, pos.y*10, (float)frameNum/div);
    float posY = noise->noise(pos.x*10, pos.y*10, (float)(frameNum+200)/div);
    float posZ = noise->noise(pos.x*10, pos.y*10, (float)(frameNum+1000)/div);
    
    a += ofxVec3f(posX,posY,posZ)*0.06;     

    
    //
    // Center gravity
    //
    a += -pos * 0.01;
    
    
    v += step*a;
    v *= 0.9;
    pos += v;
                           
    a = ofxVec3f();
}

void Firefly::draw(bool front){
    float a = pos.z;
    if(front){
        a = -pos.z;
    }
    ofSetColor(255,255,0,ofClamp(a,0,1)*255);
    ofCircle(pos.x,pos.y,0.02);   
}


