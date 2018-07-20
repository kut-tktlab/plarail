# plarail
オープンキャンパスのプラレールのコード

# processingとarduinoの設定メモ

参考になりそうなサイト  
<http://yoppa.org/tau_bmaw13/4772.html>

#### PROCESSINGの設定

processingには2つの設定ファイルが必要。  
processingのライブラリというフォルダに入れる。  
1. processingからhttpリクエストをマビーに飛ばすためのもの  
<https://github.com/runemadsen/HTTP-Requests-for-Processing>  
2. processingとArduinoを連携させるためのもの  
<http://playground.arduino.cc/interfacing/processing>

---------

#### ARDUINOの設定

Arduinoをmacで動かすために必要(このページのmacの奴をダウンロード)  
<https://www.arduino.cc/en/Main/Software>

Arduino設定  
ファイル→スケッチ名→firmata→StandardFimataに設定  
ウィンドウが出る→繋ぐ→マイコンに書き込む  
※もしかしたら最初にエラーが出るかも→ボードかシリアルポートが違う設定になってるかも（Arduinoに書いてあるみたい　例：Megaなんとか）
