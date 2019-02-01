import processing.serial.*;

void StartSetup(Arduino arduino) {
  //センサーの数を設定
  Senser_Number = 3;
  //白幅の終端幅の場所を設定  例:[黒白黒白]なら2
  WhiteWidthPlace = 3;
  
  //サーボモータの数だけ生成(arduino, 接続ポート番号)
  servo = new Servo(arduino, 9);
}

//各プラレールの初期速度
void delegateInit() {
  setPow(0, 90);
  setPow(1, 100);
  setPow(2, 100);
}

/*
    プラレールに時間差で速度変更をさせる
    Pla_Timer.add(プラレール番号, 設定時間内の速度, 設定時間後の速度, 設定時間　1秒=120);
    
    サーボモータを回転させる
    回転させるサーボモータクラス.servoRot(回転角度, 0度に戻る時間 1秒 = 120フレーム)
*/

/* 
   各センサーがプラレールを検出した時の処理
   
   plaNum = 検出されたプラレール番号
   place = 検出したセンサー番号
*/
void senser_event(int plaNum, int place){
  println("gousya = " + plaNum + ", place = " + place);
    
  if(place == 0) {
    if(plaNum == 2 ) {
      addPlarailTimer(2, 60, 100, 250);
    }
  }else if(place == 2) {
    if(plaNum == 0) {
      servo.servoRot(90, 155);
      addPlarailTimer(0, 50, 100, 30);
      addPlarailTimer(1, 50, 90, 60);
    }
    
    if(plaNum == 1) {
      servo.servoRotReset();
    }
    
    if(plaNum == 2) {
      servo.servoRot(90, 240);
      setPow(0, 100);
      addPlarailTimer(1, 70, 90, 120);
    }
  }
  
  if((place == 0 || place == 1) && plaNum != 2) {
    //通信遅延の対策として2回停止信号を送る
    setPow(plaNum, 0);
    setPow(plaNum, 0);
  }
}
