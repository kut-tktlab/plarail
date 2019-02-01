import http.requests.*;


class MabeeControl {
 
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
      print(".");
      delay(100);
      result = validRequestString("", "state", "PoweredOn");
    } while(!result);
  }
  
  void scan() {
    boolean result = false;
    do {
      print("."); 
      GetRequest get = new GetRequest("http://localhost:11111/" + "scan/start");
      get.send();
      delay(100);
      result = validRequestBoolean("scan/", "scan", true);
    } while(!result);
  }
  
  void waitDevice() {
    while(!existDevice()){
      print(".");
    }
  }
  
  void connect(int id) {
    boolean result = false;
    do {
      print(".");
      GetRequest get = new GetRequest("http://localhost:11111/devices/" + id +"/connect");
      get.send();
      delay(100);
      result = validRequestString("devices/" + id +"/", "state", "Connected");
    } while(!result);
  }
  
  void makeReady(int id) {
    GetRequest get = new GetRequest("http://localhost:11111/devices/" + id +"/connect");
    get.send();
    delay(100);
    get = new GetRequest("http://localhost:11111/scan/stop");
    get.send();
    delay(100);
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
  }
  
  JSONObject getJSON(String url) throws Exception {
    GetRequest get = new GetRequest("http://localhost:11111/" + url);
    get.send();
    return parseJSONObject(get.getContent());
  }
  
  boolean validRequestString(String url, String key, String value) {
    try {
      
      println(getJSON(url).getString(key));
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

void setup() {
  MabeeControl control = new MabeeControl();
  control.setDuty(1, 0);
  control.setDuty(2, 0);
  control.setDuty(3, 0);
  control.disconnect(1);
  control.disconnect(2);
  control.disconnect(3);
  exit();
}
