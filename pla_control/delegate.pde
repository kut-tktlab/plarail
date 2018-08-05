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

//各プラレールの初期速度
void delegateInit() {
  setPow(0, 100);
  //setPow(1, 100);
  setPow(2, 100);
}

int pla_count[] = new int [3];
//各プラレールの時間計測用関数
void pla_count(){
  /*
  時間差発進　新幹線追加のためボツ
  for(int i = 0; i < pla_.length; i++) {
    pla_count[i]++;
  }
  */
}

//カウンタを使った時間差発進や位置調整用関数
void pla_restart() {
  /*
  時間差発進　新幹線追加のためボツ
  if(stop_pla != -1) {
      if(pla_[stop_pla] == 2 && (pla_[stop_pla^1] == 0 || pla_[stop_pla^1] == 1)){
        Message("senser 0or1 error: plarail "+ stop_pla +" strat");
        setPow(stop_pla, 100);
        stop_pla = -1;
        return;
      }

      if((pla_[stop_pla] == 0 || pla_[stop_pla] == 1) && pla_count[stop_pla] > 600) {
        Message("delay start: plarail "+ pla_[stop_pla] +" start");
        setPow(stop_pla, 100);
        stop_pla = -1;
        return;
      }
      
  }
  */
}

/* place: 0 ~ 2
   各センサーがプラレールを検出した時の処理
*/
void event(int plaNum, int place){
  println("gousya = " + plaNum + ", place = " + place);
  
  if(plaNum == 2 && place == 2) {
    //サーボモータを回転させる(回転角度, 0度に戻る時間 1秒 = 120フレーム)
    servo.servoRot(90, 155);
  }
  
  if(plaNum == 1 && place == 2) {
    servo.servoRot(90, 240);
    setPow(0, 95);
    setPow(2, 100);
  }
  
  if((place == 0 || place == 1) && plaNum != 1) {
    //通信遅延の対策として2回停止信号を送る
    setPow(plaNum, 0);
    setPow(plaNum, 0);
  }
}
