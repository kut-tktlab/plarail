import http.requests.*;
import cc.arduino.*;
import java.util.*;

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

  int updateCoolDownTime = 120;
  int sensorTimer = 0;

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

    graph = new MyGraph(2, tmpC, port);
  }

  void update() {
    int v = arduino.analogRead(port);
    int rV = round(map(v, 800, 1024, height * 0.1, height * 0.9));

    boolean whiteCond = rV < 450;
    graph.update(whiteCond ? 300:100);

    sensorTimer++;

    // Cool Down
    if (updateCoolDownTime != 0) {
      updateCoolDownTime--;
      return;
    }

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
          blackRead = false;
          checkCode = false;
          plaCode = 0;
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

      int plaNum = -1;
      if (plaCode == 0) plaNum = 1;
      if (plaCode == 1) plaNum = 0;
      if (plaCode == 2) plaNum = 2;
      println(sensorTimer);
      //println("read finish");
      updateCoolDownTime = 60;
      //println();
      senser_event(plaNum, place);
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
  final String mabeeeControlServerURL = "http://localhost:11111";

  State state = State.init;
  final int mabeeeNum;
  final int[] plaNum2mabeeeId;
  final HashMap<String, Integer> mabeeeName2plaNum;

  MabeeControl(String[] mabeeeNames) {
    mabeeeNum = mabeeeNames.length;
    mabeeeName2plaNum = new HashMap();
    for (int i = 0; i < mabeeeNum; i++) {
      mabeeeName2plaNum.put(mabeeeNames[i], i);
    }
    plaNum2mabeeeId = new int[mabeeeNum];
    Arrays.fill(plaNum2mabeeeId, -1);
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
      GetRequest get = new GetRequest(mabeeeControlServerURL + "/scan/start");
      get.send();
      delay(100);
      result = validRequestBoolean("scan/", "scan", true);
    } while(!result);
    state = State.scaned;
  }

  void waitAndSetDeviceAll() {
    // エラー（未検出のMaBeeeを示す）メッセージ
    String errMsg = "";

    while(true){
      try {
        JSONObject data = getJSON("devices");
        JSONArray devices = data.getJSONArray("devices");

        // 動作に必要なMaBeeeが全て検出できているか確認
        Set<String> set = new HashSet();
        for (int i = 0; i < devices.size(); i++) {
          JSONObject device = devices.getJSONObject(i);
          String name = device.getString("name");
          if (mabeeeName2plaNum.containsKey(name)) {
            set.add(name);
          }
        }

        // 動作に必要なMaBeeeが不足している場合はエラーメッセージを表示
        if (set.size() != mabeeeNum) {
          String curErrMsg = "";
          for (String s : mabeeeName2plaNum.keySet()) {
            if (!set.contains(s)) {
              String plaName = PlaNames[mabeeeName2plaNum.get(s)];
              curErrMsg += plaName + "(" + s + "), ";
            }
          }
          curErrMsg += "not found.";
          // 同じメッセージを連続で出力しないよう制御
          if (!errMsg.equals(curErrMsg)) {
            println(curErrMsg);
            errMsg = curErrMsg;
          }
          delay(100);
          continue;
        }

        // 動作に必要なMaBeeeが揃ったら、
        // プラレール番号をMaBeee番号に変換するデータを作成
        for (int i = 0; i < devices.size(); i++) {
          JSONObject device = devices.getJSONObject(i);
          String name = device.getString("name");
          int mabeeeId = device.getInt("id");
          int plaNum = mabeeeName2plaNum.get(name);
          plaNum2mabeeeId[plaNum] = mabeeeId;
        }
        break;
      } catch (Exception e) {
        println(e);
      }
    }

    state = State.connected;
  }

  private void connect(int mabeeeId) {
    boolean result = false;
    do {
      //print(".");
      GetRequest get = new GetRequest(mabeeeControlServerURL + "/devices/" + mabeeeId +"/connect");
      get.send();
      delay(100);
      result = validRequestString("devices/" + mabeeeId +"/", "state", "Connected");
    } while(!result);
    state = State.connected;
  }

  void connectAll() {
    for (int mabeeeId : plaNum2mabeeeId) {
      connect(mabeeeId);
    }
  }

  private void makeReady(int mabeeeId) {
    GetRequest get = new GetRequest(mabeeeControlServerURL + "/devices/" + mabeeeId +"/connect");
    get.send();
    delay(100);
    get = new GetRequest(mabeeeControlServerURL + "/scan/stop");
    get.send();
    delay(100);
    state = State.ready;
  }

  void makeReadyAll() {
    for (int mabeeeId : plaNum2mabeeeId) {
      makeReady(mabeeeId);
    }
  }

  void setDuty(int plaNum, int val) {
    int mabeeeId = plaNum2mabeeeId[plaNum];
    GetRequest get = new GetRequest(mabeeeControlServerURL + "/devices/" + mabeeeId + "/set?pwm_duty=" + val);
    get.send();
    //delay(50);
  }

  void disconnect(int plaNum) {
    int mabeeeId = plaNum2mabeeeId[plaNum];
    GetRequest get = new GetRequest(mabeeeControlServerURL + "/devices/" + mabeeeId + "/disconnect");
    get.send();
    delay(100);
    state = State.init;
  }

  JSONObject getJSON(String url) throws Exception {
    GetRequest get = new GetRequest(mabeeeControlServerURL + "/" + url);
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
  int h;
  MyGraph(int step, color graphColor, int h) {
    this.vals = new int[width / step];
    //this.vals = new int[width / 5]; // DEBUG:
    //this.step = 5;
    this.step = step;
    this.graphColor = graphColor;
    this.h = h;
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
    //translate(0, height - h * (height/3) + (height/9));
    translate(0, 120 + h * 120);//DEBUG:
    scale(1, -1);
    stroke(graphColor);

    for(int i = 0; i < array.length - 1; i++) {
      line(i * step, array[i], (i + 1) * step, array[i + 1]);
    }

    int preVal = 0; int preIndex = 0;
    //for(int i = 0; i < array.length - 1; i++) {
    //  //println(array[i]);
    //  int oneORzero = (array[i] != 0) ? 100 : 0;
    //  if (oneORzero != preVal) {
    //    line(preIndex * step, preVal, (i-1) * step, preVal);
    //    line((i-1) * step, preVal, i * step, oneORzero);
    //    preVal = oneORzero;
    //    preIndex = i;
    //  }
    //}
    //line(preIndex * step, preVal, (array.length-1) * step, preVal);

    scale(1, -1);
    textSize(30);
    text("ゲートxxx", 30, 0);
    popMatrix();
  }
}
