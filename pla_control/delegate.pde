import processing.serial.*;

// plaNum: 0 ~ 2 gousya
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
