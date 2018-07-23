import processing.serial.*;

// plaNum: 0 ~ 1 gousya
// val: Mabeee's power 0 ~ 100
void setPow(int plaNum, int val) {
  if (plaNum == 0) {
    control.setDuty(1, val);
  } else if (plaNum == 1) {
    control.setDuty(2, val); 
  }
}

void delegateInit() {
  setPow(0, 100);
  setPow(1, 75);
}

int pla_count[] = new int [2];
void pla_count(){
  for(int i = 0; i < pla_.length; i++) {
    pla_count[i]++;
  }
}

void pla_replace() {
  for(int i = 0; i < pla_.length; i++) {
    if(pla_[i] == 2 && pla_count[i] >= 240) {
      pla_[i] = i;// atode
    }
  }
}

void pla_restart() {
  if(stop_pla != -1) {
      if(pla_[stop_pla] == 2 && (pla_[stop_pla^1] == 0 || pla_[stop_pla^1] == 1)){
        setPow(stop_pla, 100);
        stop_pla = -1;
      }
  }
}

// place: 0 ~ 2
int other_pla;
int stop_pla = -1;
void event(int plaNum, int place){
  arduino.servoWrite(7,40);
  println("gousya = " + plaNum + ", place = " + place);
  
  if(place == 2 && plaNum == 1) {
    // rot:0-180, frameRate: 120
    servo.servoRot(90, 80);
  }
  
  if(stop_pla != -1) {
    if (stop_pla == 0) setPow(stop_pla, 80);
    else setPow(stop_pla, 100);
    stop_pla = -1;
  }
  
  pla_count[plaNum] = 0;
  pla_[plaNum] = place;
  other_pla = plaNum^1;
  
  if(pla_[other_pla] == place || (pla_[other_pla] | place) == 1) {
    setPow(plaNum, 0);
    stop_pla = plaNum;
  }
}
