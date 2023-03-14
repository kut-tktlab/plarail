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
String msg[] = new String[15];
Boolean debugLog = false;
Boolean openLog = true;
//PImage courseImage;

int[] updateGateStatus = new int[Senser_Number];
String allStatus = "---";
int updateAllStatus = int(frameRate);
boolean buttonOnePressed = false;
boolean buttonTwoPressed = false;
boolean forceStopDraw = false;

ArrayList<Plarail_Timer> Pla_Timer = new ArrayList<Plarail_Timer>();
void setup() {
  //size(600,700);
  //size(displayWidth, displayHeight);
  fullScreen();
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
  //courseImage = loadImage("course.png");

  initPla();
}

int frameCounter = 0;
int secondCounter = 0;
int dot1sec = 0;
void draw() {
  if (forceStopDraw) return;

  frameCounter++;
  if (frameCounter % 12 == 0) {
    dot1sec++;
  }
  if (dot1sec == 10) {
    secondCounter++;
    dot1sec = 0;
  }

  if (frameCounter % 1200 == 0) {
    allStatus = "debug secondCounter: " + secondCounter;
    updateAllStatus = int(frameRate);
  }

  textSize(15);
  fill(#FFFFFF);
  background(#000000);

  Message("[" + secondCounter + "." + dot1sec + "s] ここにログ " + frameRate + "fps");

  for (Sensor s: sensors) {
    //s.graph.update(3*frameCounter % 1000);
  }

  for (Sensor s: sensors) {
    try {s.update();}catch(Exception e) {emergencyBrake();print(e);stop();}
  }

  //if (Pla_Timer.size() != 0) println(Pla_Timer.get(0).endTime);
  for(int i = Pla_Timer.size()-1; i >= 0; i--) {
    Plarail_Timer pla_Timer = Pla_Timer.get(i);
    pla_Timer.TimerCont();
    if(pla_Timer.endTime == -1) Pla_Timer.remove(i);
  }

  //println(PFont.list());

  PFont font = createFont("Menlo", 30);
  textFont(font);

  textSize(15);
  text(nf(frameRate, 3, 2) + "fps", width - 100, 50);

  int offset = height/2;

  textSize(35);
  text("状態: ", width/2, offset);
  if (updateAllStatus > 0) {
    updateAllStatus--;
    if ((updateAllStatus / (120/5)) % 2 == 0) {
      fill(#000000);
      //fill(#FFFFFF);
    } else {
      //fill(#FFFF00);
      fill(#FFFFFF);
    }
  }
  text(allStatus, width/2 + 100, offset);
  offset+= 50;
  fill(#FFFFFF);

  stroke(#FFFFFF);
  line(width/2, offset - 25, width - 50, offset - 25); offset+= 50;

  for (int i = 0; PlaNames != null && i < PlaNames.length; i++) {
    textSize(35);
    if (PlaNames[i] != null) text(PlaNames[i], width/2 + 0, offset);
    textSize(30);
    text("速度: " + currentSpeeds[i] + "%", width/2 + 200, offset);
    text("ゲート" + passedGates[i] + "通過", width/2 + 400, offset);
    offset+= 50;
  }

  stroke(#FFFFFF);
  line(width/2, offset - 25, width - 50, offset - 25); offset+= 50;

  fill(#000000); stroke(#FFFFFF);
  rect(width/2, height-100, 300, 80); rect(width/2 + 300 + 50, height-100, 300, 80);
  fill(#FFFFFF);
  textSize(35);
  if (width/2 < mouseX && mouseX < width/2+300 && height-100 < mouseY && mouseY < height-100+80) {
    fill(#00FFFF);
    if (mousePressed && !buttonOnePressed) {
      if (initPhase) {
        Message("発車準備中です...");
      } else if (endPhase) {
        Message("停車中です...");
      } else if (runningPhase) {
        Message("発車します");
      } else {
        Message("停車します");
      }
    }
    buttonOnePressed = mousePressed;
  }
  text("停車/発車ボタン", width/2 + 20, height-100+55);
  fill(#FFFFFF);
  if (width/2 + 300 + 50 < mouseX && mouseX < width/2 + 300 + 50 + 300 && height-100 < mouseY && mouseY < height-100+80) {
    fill(#FF0000);
    if (mousePressed && !buttonTwoPressed) {
      Message("列車を強制停止させました。");
      Message("ESCでプログラムを終了させて下さい。");
      forceStopDraw = true;
    }
    buttonTwoPressed = mousePressed;
  }
  text("強制停止ボタン", width/2 + 300 + 50 + 20 + 10, height-100+55);

  //グラフ画面に文字を表示
  textSize(25);
  for(int i = 0; i < msg.length; i++) {
    //文字列に"error"が含まれる時、文字を赤に
    String[] m1 = match(msg[i], "error");
    if (m1 != null) fill(#FF0000); //match
    else fill(#FFFFFF);

    text(msg[i], 50, height - i*30 - 30);
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

  //InitPower();
  InitInitPower();
}

/*
  バツボタンを押した時の処理（停止ボタンではだめ）
  stop_plaと同じ処理であり、普通に動いている時は
  このスケッチの描画画面のバツボタンを押せばプラレールは止まる
  例外(nullpointerexceptionとか)や停止ボタンを押した場合は
  stop_plaを起動させて止める
*/
void dispose() {
  servo.servoRotReset();
  for(int i = 0; i < MaBeeeNumber; i++) {
    stopNow(i);
    control.disconnect(i);
  }
}

void emergencyBrake() {
  if (debugLog) println("Emergency Brake");
  if (openLog) println("緊急ブレーキを作動させました。");
  dispose();
}

//グラフ画面に文字を表示させる関数
void Message(String str) {
  for(int i = msg.length-1; i > 0; i--) {
   msg[i] = msg[i-1];
  }
  msg[0] = "[" + secondCounter + "." + dot1sec + "s] " + str;
}
