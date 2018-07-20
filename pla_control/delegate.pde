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

// place: 0 ~ 2
int other_pla;
int pla_[] = new int[2];
int stop_pla = -1;
void event(int plaNum, int place){
  println("gousya = " + plaNum + ", place = " + place);
  
  if(stop_pla != -1) {
    setPow(stop_pla, 100);
    stop_pla = -1;
  }
  
  pla_[plaNum] = place;
  other_pla = plaNum^1;
  if(pla_[other_pla] == place || (pla_[other_pla] | place) == 1) {
    setPow(plaNum, 0);
    stop_pla = plaNum;
  }
}
