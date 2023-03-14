import processing.serial.*;

// シリアルポートへのパスを自動検出
String findSerialPortPath() {
  StringList strout = new StringList();
  StringList strerr = new StringList();
  int res = shell(strout, strerr, "ls /dev/tty.usbmodem*");
  if (res != 0) {
    throw new RuntimeException("Serial port not found.");
  }
  String path = strout.get(0);
  return path;
}

void SetSerialPort() {
  // シリアルポートのパス
  String path = findSerialPortPath();

  // arduino = new Arduino(this, "シリアルポート", 通信速度);
  // arduino = new Arduino(this, "/dev/tty.usbmodem143241", 57600);
  arduino = new Arduino(this, path, 57600);
}

//サーボモータの数だけ生成
Servo servo;

void StartSetup(Arduino arduino) {
  //センサーの数を設定
  Senser_Number = 3;
  //白幅の終端幅の場所を設定  例:[白黒白黒白]なら3
  WhiteWidthPlace = 3;

  //MaBeeeの数を設定
  MaBeeeNumber = 3;
  //プラレール番号の順にMaBeee名と列車名を列挙
  MaBeeeNames = new String[]{"MaBeee015260", "MaBeee015261", "MaBeeeA08638"};
  PlaNames = new String[]{"新幹線", "サバンナ号", "貨物列車"};
  control = new MabeeControl(MaBeeeNames);

  //サーボモータの設定(arduino, 接続ポート番号)
  servo = new Servo(arduino, 9);
}

int[] fastSpeeds = {100, 100, 90};
int[] midlSpeeds = { 90, 90, 90};
int[] slowSpeeds = { 70, 70, 80};
int[] currentSpeeds = {0, 0, 0};
int[] passedGates = {-1, -1, -1};

boolean initPhase  = true;
boolean endPhase   = false;
boolean endPhaseDo = false;
boolean runningPhase = false;

//各プラレールの初期速度
void InitInitPower() {
  slowChange(0, 0, midlSpeeds[0], 300, 20);
}

void InitPower() {
  slowChangeTimer(0, 0, fastSpeeds[0], 120*1, 20, 120*4);
  setPow(1, 0);
  slowChangeTimer(2, 0, fastSpeeds[2], 120*3, 20, 120*4);

  //setPow(0, 100);
  //setPow(1, 100);
  //setPow(2, 70);
}

void resetTimer(int plaNum) {
  for (int i = Pla_Timer.size()-1; i >= 0; i--) {
    if (Pla_Timer.get(i).plaNum == plaNum) {
      Pla_Timer.remove(i);
    }
  }
}

void stopNow(int plaNum) {
  resetTimer(plaNum);
  for (int i = 0; i < 5; i++) setPow(plaNum, 0);
}

/*
    プラレールの速度を変える
 setPow(プラレール番号, 速度 0-100);

 プラレールに時間差で速度変更をさせる
 Pla_Timer.add(プラレール番号, 設定時間内の速度, 設定時間後の速度, 設定時間　1秒=120);

 サーボモータを回転させる
 回転させるサーボモータクラス.servoRot(回転角度 0-180, 0度に戻る時間 1秒 = 120フレーム)
 */

/*
   各センサーがプラレールを検出した時の処理

 plaNum = 検出されたプラレール番号
 place = 検出したセンサー番号
 */
void senser_event(int plaNum, int place) {
  println("gousya = " + plaNum + ", place = " + place);

  int prevPlace = place;
  passedGates[plaNum] = place;
  if (debugLog) println("The " + PlaNames[plaNum] + "(No." + plaNum + ")" +
    " has passed the gate " + place + " from gate" + prevPlace + ".");
  if (openLog) println(PlaNames[plaNum] + " が " + place + " 番ゲートを通過しました。");

  if (endPhase) {
    if (endPhaseDo) {
      if (place == 2) {
        if (plaNum == 1) {
          servo.servoRot(90, 120*10);
          slowChange(0, currentSpeeds[0], midlSpeeds[1], 120*2, 20);
          slowChange(1, currentSpeeds[1], midlSpeeds[1], 120*2, 20);
        }
        if (plaNum == 2) {
          servo.servoRot(90, 120*10);
          slowChange(0, currentSpeeds[0], midlSpeeds[0], 120*2, 20);
          slowChange(1, currentSpeeds[1], midlSpeeds[1], 120*2, 20);
          slowChange(2, currentSpeeds[2], midlSpeeds[2], 120*2, 20);
        }
      }
      if (place == 0) {
        if (plaNum == 0) {
          stopNow(0);
        }
        if (plaNum == 1) {
          stopNow(0);
          stopNow(1);
        }
        if (plaNum == 2) {
          stopNow(0);
          stopNow(1);
          stopNow(2);
        }
      } else {
        if (place == 2 && plaNum == 2) {
          println("停車処理を開始します。");
          endPhaseDo = true;
        }
      }
      endPhase = false;
      endPhaseDo = false;
      runningPhase = false;
      println("停車処理が完了しました。");
      return;
    }
  }

  if (initPhase) {
    if (place == 0) {
      stopNow(0);
    }
    if (place == 1) {
      if (plaNum == 1) stopNow(1);
    }
    if (place == 2) {
      if (plaNum == 0) {
        resetTimer(1);
        slowChange(1, 0, midlSpeeds[1], 300, 20);
        servo.servoRot(90, 120*10);
      }
      if (plaNum == 1) {
        servo.servoRotReset();
        resetTimer(2);
        slowChange(2, 0, midlSpeeds[2], 300, 20);
      }
      if (plaNum == 2) {
        stopNow(2);
        servo.servoRot(90, 120*10);
        InitPower();
        initPhase = false;
        runningPhase = true;
      }
    }
    return;
  }

  if (place == 2) {
    for (int i = 0; i < passedGates.length; i++) {
      if (i != plaNum && passedGates[i] == 2) emergencyBrake();
    }
    if (plaNum == 0) {
      servo.servoRot(90, 360);
      resetTimer(0);
      slowChange(0, currentSpeeds[0], slowSpeeds[0], 120*2, 10);
      resetTimer(2);
      slowChange(2, currentSpeeds[2], fastSpeeds[2], 120*1, 10);
    }
    if (plaNum == 1) {
      servo.servoRotReset();
      resetTimer(1);
      slowChange(1, currentSpeeds[1], slowSpeeds[1], 120*2, 10);
    }
    if (plaNum == 2) {
      servo.servoRot(90, 600);
      resetTimer(2);
      slowChange(2, currentSpeeds[2], slowSpeeds[2], 120*2, 10);
    }
  }

  if (place == 0) {
    if (plaNum != 0 && plaNum == 1) emergencyBrake();
    if (plaNum == 2) {
      stopNow(2);
      resetTimer(1);
      slowChange(1, currentSpeeds[1], fastSpeeds[1], 120*1, 10);
    }
  }

  if (place == 1) {
    if (plaNum != 1) emergencyBrake();
    if (plaNum == 1) {
      resetTimer(0);
      slowChange(0, currentSpeeds[0], fastSpeeds[0], 120*1, 10);
    }
  }

  if ((place == 0 || place == 1) && plaNum != 2) {
    stopNow(plaNum);
  }
}
