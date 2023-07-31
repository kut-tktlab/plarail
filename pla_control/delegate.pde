import processing.serial.*;

// plaNum: 0 ~ 2 gousya
// val: Mabeee's power 0 ~ 100
void setPow(int plaNum, int val) {
  //println("set duty " + PlaNames[plaNum] + " " + val);
  currentSpeeds[plaNum] = val;
  String msg = "";
  for (int i = 0; i < PlaNames.length; i++)
    msg += PlaNames[i] + ": gate" + passedGates[i] + " speed" + currentSpeeds[i] + " / ";
  //println(msg);
  control.setDuty(plaNum, val);
}

void addPlarailTimer(int plaNum, int startSpd, int endSpd, int time) {
  Pla_Timer.add(new Plarail_Timer(plaNum, startSpd, endSpd, time));
  //println("addPlarailTimer " + PlaNames[plaNum] + " time:" + time);
}

void slowChange(int plaNum, int startSpd, int endSpd, int time, int n) {
  //n = 10;
  for (int i = 1; i <= n; i++) {
    Pla_Timer.add(new Plarail_Timer(plaNum, startSpd, startSpd + ((endSpd-startSpd)/n) * i, (time/n) * i));
  }
}

void slowChangeTimer(int plaNum, int startSpd, int endSpd, int time, int n, int timerTime) {
  //n = 10;
  for (int i = 1; i <= n; i++) {
    Pla_Timer.add(new Plarail_Timer(plaNum, startSpd, startSpd + ((endSpd-startSpd)/n) * i, timerTime + (time/n) * i));
  }
}
