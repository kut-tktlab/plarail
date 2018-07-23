import http.requests.*;
import cc.arduino.*;
int[] lastPass = {1, 1};

int placeCount = 0;
int[][] powerTable = {{0, 90}, {0, 75}};

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
  int widthIndex = 0;
  
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
    boolean whiteCond = rV < 550;
    graph.update(whiteCond ? 300:100);
    if (whiteCond) {
      whiteCount++;
    } else {
      if (blackCount > frameRate * 10) {
        widthIndex = 0;
        blackCount = 0;
        //print("-");
      }
      
      if (whiteCount > 1) {
        whiteWidths[widthIndex] = whiteCount;
        widthIndex++;
        whiteCount = 0;
      }
      
      blackCount++;
    }
    
    if (widthIndex > 1 && abs(whiteWidths[0] - whiteWidths[1]) > 1) {
      
      //println(">>" + whiteWidths[0] + ", " + whiteWidths[1]);
      //print("place: " + place);
      //println(whiteWidths[0] > whiteWidths[1] ? "==== 1 ====" : "==== 2 ====");
      
      int plaNum = whiteWidths[0] > whiteWidths[1] ? 0 : 1;
      
      event(plaNum, place);
      
      widthIndex = 0;
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
    delay(100);
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
