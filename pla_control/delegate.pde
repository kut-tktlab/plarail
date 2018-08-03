import processing.serial.*;

// plaNum: 0 ~ 1 gousya
// val: Mabeee's power 0 ~ 100
void setPow(int plaNum, int val) {
  if (plaNum == 0) {
    control.setDuty(1, val);
  } else if (plaNum == 1) {
    control.setDuty(2, val); 
  } else {
    control.setDuty(3, val); 
  }
}

void delegateInit() {
  setPow(0, 100);
  setPow(1, 100);
  setPow(2, 100);
  Message("start plarail 0");
  Message("start plarail 1");
}

int pla_count[] = new int [3];
void pla_count(){
  for(int i = 0; i < pla_.length; i++) {
    pla_count[i]++;
  }
}


void pla_restart() {
  /*
  if(stop_pla != -1) {
      if(pla_[stop_pla] == 2 && (pla_[stop_pla^1] == 0 || pla_[stop_pla^1] == 1)){
        Message("senser 0or1 error: plarail "+ stop_pla +" strat");
        setPow(stop_pla, 100);
        stop_pla = -1;
        return;
      }
      */
      /*
      //時間差発進　新幹線追加のためボツ
      if((pla_[stop_pla] == 0 || pla_[stop_pla] == 1) && pla_count[stop_pla] > 600) {
        Message("delay start: plarail "+ pla_[stop_pla] +" start");
        setPow(stop_pla, 100);
        stop_pla = -1;
        return;
      }
      
  }
  */
}

// place: 0 ~ 2
int other_pla;
int stop_pla[] = {0, 0};
int empty_place = 0;
void event(int plaNum, int place){
  println("gousya = " + plaNum + ", place = " + place);
  
  if(plaNum == 2 && place == 2) {
    servo.servoRot(90, 140);
  }
  
  if(plaNum == 1 && place == 2) {
    setPow(0, 100);
    setPow(2, 100);
    servo.servoRot(90, 240);
  }
  
  //pla_count[plaNum] = 0;
  //pla_[plaNum] = place;
  
  if((place == 0 || place == 1) && plaNum != 1) {
    setPow(plaNum, 0);
    stop_pla[0] = stop_pla[1];
    stop_pla[1] = plaNum;
  }
  
  
}
