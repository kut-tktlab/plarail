import cc.arduino.*;

class Servo{
    Arduino arduino;
    int port;
    int time;
    int count;
    boolean rot;
    
    Servo(Arduino arduino, int port) {
      this.arduino = arduino;
      this.port = port;
      this.time = 0;
      this.count = 0;
      this.rot = false;
      
      arduino.pinMode(this.port, Arduino.SERVO);
      arduino.servoWrite(this.port, 0);
      println("servo port:" + this.port+ " reset");
    }
    
    void update() {
      if (rot) {
        if(this.time == this.count) {
          this.servoRotReset();
        }
        this.count++;
      }
    }
    
    void servoRot(int angle, int time) {
      this.rot = true;
      this.time = time;
      this.count = 0;
      arduino.servoWrite(this.port, angle);
    }
    
    void servoRotReset() {
      this.rot = false;
      arduino.servoWrite(this.port, 0);
    }
}
