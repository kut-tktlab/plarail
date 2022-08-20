import processing.serial.*;

// plaNum: 0 ~ 2 gousya
// val: Mabeee's power 0 ~ 100
void setPow(int plaNum, int val) {
  control.setDuty(plaNum, val);
}

void addPlarailTimer(int plaNum, int startSpd, int endSpd, int time) {
  Pla_Timer.add(new Plarail_Timer(plaNum, startSpd, endSpd, time));
}
