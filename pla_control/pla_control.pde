import processing.net.*;
import processing.serial.*;
import cc.arduino.*;
import org.firmata.*;
import http.requests.*;

Arduino arduino;
MabeeControl control = new MabeeControl();
Sensor[] sensors = new Sensor[3];
int pla_[] = new int[2];
Servo servo;

int servo1 = 9;
void setup() {

  size(1600,800);
  frameRate(120);  
  arduino = new Arduino(this, "/dev/tty.usbmodem143221", 57600);
  for(int i = 0; i < 3; i++) {
  sensors[i] = new Sensor(arduino, i);
  }
  
  servo = new Servo(arduino, servo1);
  
  for(int i = 0; i < 2; i++){
    pla_[i] = 0;
  }
  
  initPla();
}



void draw() {
  background(#000000);
  //sensors[0].update();
  for (Sensor s: sensors) {
    s.update();
  }
  text("pla1: "+pla_[0] + "   count: " + pla_count[0], 100, 100);
  text("pla2: "+pla_[1] + "   count: " + pla_count[1], 100, 200);
  text("stop pla: "+stop_pla, 100, 300);
  pla_count();
  pla_replace();
  pla_restart();
  servo.update();
}

void initPla() {
  control.init();
  println("finish init");
  
  control.scan();
  println("finish scan");
  control.waitDevice();
  println("check device");
  control.connect(1);
  control.connect(2);
  println("connected");
  control.makeReady(1);
  control.makeReady(2);
  println("ready");
  delegateInit();
  //control.setDuty(1, powerTable[0][high]);
  //control.setDuty(2, powerTable[1][low]);
  //control.setDuty(1,100);
  //control.setDuty(2,50);
  //delay(5000);
  //control.setDuty(1,0);
  //control.setDuty(2,0);
  //delay(5000);
  //control.setDuty(2,0);
  //control.disconnect();

}
