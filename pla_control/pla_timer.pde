class Plarail_Timer {
  int plaNum;
  int f_speed;
  int e_speed;
  
  int count;
  int endTime;
  Plarail_Timer(int Num, int firstSpeed, int endSpeed, int Timer) {
    this.plaNum = Num;
    this.f_speed = firstSpeed;
    setPow(this.plaNum, this.f_speed);
    this.e_speed = endSpeed;
    this.endTime = Timer;
    this.count = 0;
  }
  
  void TimerCont() {
    if(this.count == this.endTime) {
      setPow(this.plaNum, this.e_speed);
      this.endTime = -1;
    }
    this.count++;
  }
  
}
