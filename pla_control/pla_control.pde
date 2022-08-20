// font Menlo

import processing.net.*;
import processing.serial.*;
import cc.arduino.*;
import org.firmata.*;
import http.requests.*;

int Senser_Number = 3;
int WhiteWidthPlace = 3;
int MaBeeeNumber = 3;
String[] MaBeeeNames;
String[] PlaNames;
MabeeControl control;
Sensor[] sensors;
Arduino arduino;
String msg[] = new String[9];

ArrayList<Plarail_Timer> Pla_Timer = new ArrayList<Plarail_Timer>();
void setup() {

  size(1600,800);
  frameRate(120);
  background(#000000);

  SetSerialPort();
  StartSetup(arduino);

  sensors = new Sensor[Senser_Number];

  //センサーの数だけ生成
  for(int i = 0; i < Senser_Number; i++) {
    sensors[i] = new Sensor(arduino, i);
  }

  //メッセージに空文字を挿入
  for(int i = 0; i < msg.length; i++) {
    msg[i] = "";
  }

  initPla();
}

void draw() {
  background(#000000);
  textSize(13);

  fill(#FFFFFF);

  for (Sensor s: sensors) {
    s.update();
  }

  for(int i = Pla_Timer.size()-1; i >= 0; i--) {
    Plarail_Timer pla_Timer = Pla_Timer.get(i);
    pla_Timer.TimerCont();
    if(pla_Timer.endTime == -1) Pla_Timer.remove(i);
  }

  //グラフ画面に文字を表示
  textSize(20);
  for(int i = 0; i < msg.length; i++) {
    //文字列に"error"が含まれる時、文字を赤に
    String[] m1 = match(msg[i], "error");
    if (m1 != null) fill(#FF0000); //match
    else fill(#FFFFFF);

    text(msg[i], 50, 320 - 30*i);
    fill(#FFFFFF);
  }
  servo.update();
}

//Mabeeeの接続設定 (詳しくはpla_utils内のMabeeControlクラスを参照)
void initPla() {

  control.init();
  println("finish init");

  control.scan();
  println("finish scan");
  control.waitAndSetDeviceAll();
  println("check device");
  control.connectAll();
  println("connected");
  control.makeReadyAll();
  println("ready");

  InitPower();
}

/*
  バツボタンを押した時の処理（停止ボタンではだめ）
  stop_plaと同じ処理であり、普通に動いている時は
  このスケッチの描画画面のバツボタンを押せばプラレールは止まる
  例外(nullpointerexceptionとか)や停止ボタンを押した場合は
  stop_plaを起動させて止める
*/
void dispose() {
  for(int i = 0; i < MaBeeeNumber; i++) {
    control.setDuty(i, 0);
    control.disconnect(i);
  }
}

//グラフ画面に文字を表示させる関数
void Message(String str) {
  for(int i = msg.length-1; i > 0; i--) {
   msg[i] = msg[i-1];
  }
  msg[0] = str;
}
