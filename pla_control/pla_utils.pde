import http.requests.*;
import cc.arduino.*;


final int low = 0;
final int high = 1;

class Sensor {
  Arduino arduino;
  MyGraph graph;
  int port;
  int place;
  final int t = 550;
  int whiteCount = 0;
  int blackCount = 0;
  int[] whiteWidths = new int[1000];
  int[] blackWidths = new int[1000];
  int whiteIndex = 0;
  int blackIndex = 0;
  
  boolean blackRead = false;
  boolean checkCode = false;
  int plaCode = 0;
  
  Sensor(Arduino arduino, int port) {
    this.arduino = arduino;
    this.port = port;
    this.place = port;
    color tmpC = #FFFFFF;
    switch (port) {
    case 0:
      tmpC = #FF0000;
      break;
    case 1:
      tmpC = #00FF00;
      break;
    case 2:
      tmpC = #0000FF;
      break;
    }
    
    graph = new MyGraph(2, tmpC);
  }
  
  void update() {
    int v = arduino.analogRead(port);
    int rV = round(map(v, 800, 1024, height * 0.1, height * 0.9));
    
    boolean whiteCond = rV < 500;

    graph.update(whiteCond ? 300:100);
    //白帯を検出した時, whiteCountを増やす
    if (whiteCond) {
      whiteCount++;
      
      //whiteIndex(白帯の検出数)が0の時, blackCountを0にする
      if(whiteIndex == 0) blackCount = 0;
      
      /*
        blackReadが真の時, blackWidths(黒帯の検出幅配列)の要素[blackIndex(黒帯検出数)]にblackCountを代入
        blackIndexを1増やしcheckCodeを真にしblackReadを負にする
        blackCountも0にする
      */
      if(blackRead){
        blackWidths[blackIndex] = blackCount;
        println("port:"+port+" black memory " + blackIndex+":"+blackWidths[blackIndex]);
        checkCode = true;
        blackRead = false;
        blackCount = 0;
        blackIndex++;
      }
      
    } else {
      //黒帯を検出した時, blackCountを増やす
      
      //もし黒帯が一定時間続いた時
      if (blackCount > frameRate * 0.35) {
        /*
          (白帯が3つの時)
          whiteIndex(白帯の検出数)が2だったなら終端の白帯の検出抜けのため
          whiteCountを2にする
        */
        if(whiteIndex == 2) {
          whiteCount = 2;
          println("port:"+port+" emergency white memory ");
        }else{
          //それ以外ならばノイズもしくは何も無い空間として検出前に戻す
          whiteIndex = 0;
          blackIndex = 0;
          blackCount = 0;
          checkCode = false;
        }
      }
      
      /*
        whiteCountが1以上(白帯が検出されている)の時, whiteWidths(白帯の検出幅配列)の要素[whiteIndex(白帯検出数)]にwhiteCountを代入
        whiteIndexを1増やしblackReadを真にする
        whiteCountを0にする
      */
      if (whiteCount > 1) {
        whiteWidths[whiteIndex] = whiteCount;
        println("port:"+port+" white memory " + whiteIndex+":"+whiteWidths[whiteIndex]);
        whiteIndex++;
        whiteCount = 0;
        blackRead = true;
      }
      blackCount++;
    }
    
    int bitSet;
    /*
      checkCodeが真の時
      whiteWidthsとblackWidthsの幅を比べる
      白幅が大きい時, 検出数に対応したbit数に1をセットする
      その後, checkCodeを負にする
    */
    if(checkCode) {
      bitSet = int(pow(2, whiteIndex-1));
      if(whiteWidths[whiteIndex-1] > blackWidths[blackIndex-1]) {
        println("bitSet:"+bitSet);
        plaCode = plaCode | bitSet;
      }
      checkCode = false;
    }
    
    /*
      白幅の終端幅の場所を設定  例:[黒白黒白]なら2
      whiteIndex(白帯検出数)が終端白帯の位置の時, event()を呼び出す
      その後, 各フラグや変数を検出前に戻す
    */
    if(whiteIndex == WhiteWidthPlace) {
      whiteIndex = 0;
      blackIndex = 0;
      checkCode = false;
      blackRead = false;
      println("plarail:"+plaCode+" passing the gate:"+place);
      println("read finish");
      println();
      senser_event(plaCode, place);
      plaCode = 0;
    }
  }
}

enum State {
  init,
  unknown,
  poweredOn,
  scaned,
  connected,
  ready,
  error,
}

class MabeeControl {
  State state = State.init;
 
  boolean existDevice() {
    try {
      JSONObject data = getJSON("devices");
      return data.getJSONArray("devices").size() == 1;
    } catch (Exception e) {}
    return false;
  }
  
  
  void init() {
    boolean result = false;
    do {
      delay(100);
      result = validRequestString("", "state", "PoweredOn");
    } while(!result);
    state = State.poweredOn;
  }
  
  void scan() {
    boolean result = false;
    do {
      //print("."); 
      GetRequest get = new GetRequest("http://localhost:11111/" + "scan/start");
      get.send();
      delay(100);
      result = validRequestBoolean("scan/", "scan", true);
    } while(!result);
    state = State.scaned;
  }
  
  void waitDevice() {
    while(!existDevice()){
      //print(".");
    }
    state = State.connected;
  }
  
  void connect(int id) {
    boolean result = false;
    do {
      //print(".");
      GetRequest get = new GetRequest("http://localhost:11111/devices/" + id +"/connect");
      get.send();
      delay(100);
      result = validRequestString("devices/" + id +"/", "state", "Connected");
    } while(!result);
    state = State.connected;
  }
  
  void makeReady(int id) {
    GetRequest get = new GetRequest("http://localhost:11111/devices/" + id +"/connect");
    get.send();
    delay(100);
    get = new GetRequest("http://localhost:11111/scan/stop");
    get.send();
    delay(100);
    state = State.ready;
  }
  
  void setDuty(int id, int val) {
    GetRequest get = new GetRequest("http://localhost:11111/devices/" + id + "/set?pwm_duty=" + val);
    get.send();
    //delay(50);
  }
  
  void disconnect(int id) {
    GetRequest get = new GetRequest("http://localhost:11111/devices/" + id + "/disconnect");
    get.send();
    delay(100);
    state = State.init;
  }
  
  JSONObject getJSON(String url) throws Exception {
    GetRequest get = new GetRequest("http://localhost:11111/" + url);
    get.send();
    return parseJSONObject(get.getContent());
  }
  
  boolean validRequestString(String url, String key, String value) {
    try {
      
      //println(getJSON(url).getString(key));
      return getJSON(url).getString(key).equals(value);
    } catch (Exception e) {
      println(e);
    }
    return false;
  }
  
  boolean validRequestBoolean(String url, String key, Boolean value) {
    try {
      return getJSON(url).getBoolean(key) == value;
    } catch (Exception e) {
      println(e);
    }
    return false;
  }
  
  
}

class MyGraph {
  int[] vals;
  int step;
  color graphColor;
  MyGraph(int step, color graphColor) {
    this.vals = new int[width / step];
    this.step = step;
    this.graphColor = graphColor;
  }
  
  void update(int val) {
    addShiftArray(vals, val);
    stroke(graphColor);
    drawArray(vals);
  }
  
  private void addShiftArray(int[] array, int val) {
    System.arraycopy(array, 0, array, 1, array.length - 1);
    array[0] = val;
  }
  
  private void drawArray(int[] array) {
    pushMatrix();
    translate(0, height);
    scale(1, -1);
    stroke(graphColor);
    for(int i = 0; i < array.length - 1; i++) {
      line(i * step, array[i], (i + 1) * step, array[i + 1]);
    }
  
    popMatrix();
  }
}
