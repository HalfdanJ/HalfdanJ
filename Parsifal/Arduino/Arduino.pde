int lastMsg = 0;

void setup(){
  pinMode(5, INPUT);
  pinMode(7, INPUT);
  
  digitalWrite(5,HIGH);
  digitalWrite(7,HIGH);
  
  Serial.begin(250000);
}

void loop(){
  if(digitalRead(5) == LOW && lastMsg != 5){
    Serial.println(5);
    lastMsg = 5;
  } else if(digitalRead(7) == LOW && lastMsg != 7){
    Serial.println(7);
    lastMsg = 7;
  } else {
   lastMsg = 0; 
  }
}
