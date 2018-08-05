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
   
    /*
      angle: 0-180, time: framerate = 120
      このメソッドが呼ばれた時, update()のcountがスタート
      countとtimeが同値の時, servoRotReset()が実行 s
    */
    void servoRot(int angle, int time) {
      this.rot = true;
      this.time = time;
      this.count = 0;
      arduino.servoWrite(this.port, angle);
    }
    
    //サーボモータの角度を0度にするメソッド
    void servoRotReset() {
      this.rot = false;
      arduino.servoWrite(this.port, 0);
    }
}
