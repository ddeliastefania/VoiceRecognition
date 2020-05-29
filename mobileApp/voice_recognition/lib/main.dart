import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:permission_handler/permission_handler.dart';
// import 'package:path/path.dart';
import 'package:flutter_sound/flutter_sound.dart' as flutterSound;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
// import 'package:random_string/random_string.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:simple_permissions/simple_permissions.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;

/// This "Headless Task" is run when app is terminated.
void backgroundFetchHeadlessTask(String taskId) async {
  Dio dio = new Dio();
  Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  await dio.post(
  'http://127.0.0.1:5000/send_location',
  data: { 
        "latitudine": position.latitude.toString(),
        "longitudine": position.longitude.toString()
    }
  )
  .then((response) => print(response))
  .catchError((error) => print(error));
  BackgroundFetch.finish(taskId);
}

void main(){ 
  runApp(MyApp());
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
} 

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;  


  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
//flutter background fetch
  bool _enabled = true;
  int _status = 0;
  List<DateTime> _events = [];


  @override
  void initState() {
    super.initState();
    initRecorder();
    initPlatformState();
  }

  
Future<void> initRecorder() async {
  print('open audio session');
   myRecorder = await flutterSound.FlutterSoundRecorder().openAudioSession();
   myPlayer = await flutterSound.FlutterSoundPlayer().openAudioSession();
}
  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Configure BackgroundFetch.
    BackgroundFetch.configure(BackgroundFetchConfig(
        minimumFetchInterval: 15,
        stopOnTerminate: false,
        enableHeadless: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
        requiredNetworkType: NetworkType.NONE
    ), (String taskId) async {

      // This is the fetch-event callback.
      print("[BackgroundFetch] Event received $taskId");
      Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      print(position);
        Dio dio = new Dio();
          dio.options.headers['Content-Type'] = 'application/json';
          // FormData formData = FormData.from({
          //   "location": {
          //     "longitude": "27.5900351",
          //     "latitude": "47.1537225"
          //   }
          // });
          await dio.post(
          'http://127.0.0.1:5000/send_location',
          data: {
              "latitudine": position.latitude.toString(),
              "longitudine": position.longitude.toString()
            }

    )
    .then((response) => print(response))
    .catchError((error) => print(error));
      setState(() {
        _events.insert(0, new DateTime.now());
      });
      // IMPORTANT:  You must signal completion of your task or the OS can punish your app
      // for taking too long in the background.
      BackgroundFetch.finish(taskId);
    }).then((int status) {
      print('[BackgroundFetch] configure success: $status');
      setState(() {
        _status = status;
      });
    }).catchError((e) {
      print('[BackgroundFetch] configure ERROR: $e');
      setState(() {
        _status = e;
      });
    });

    // Optionally query the current BackgroundFetch status.
    int status = await BackgroundFetch.status;
    setState(() {
      _status = status;
    });

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  void _onClickEnable(enabled) {
    setState(() {
      _enabled = enabled;
    });
    if (enabled) {
      BackgroundFetch.start().then((int status) {
        print('[BackgroundFetch] start success: $status');
      }).catchError((e) {
        print('[BackgroundFetch] start FAILURE: $e');
      });
    } else {
      BackgroundFetch.stop().then((int status) {
        print('[BackgroundFetch] stop success: $status');
      });
    }
  }


//flutter sound

flutterSound.FlutterSoundPlayer myPlayer = flutterSound.FlutterSoundPlayer();
flutterSound.FlutterSoundRecorder myRecorder = flutterSound.FlutterSoundRecorder();
bool _isRecording = false;
bool _isListening = false;
bool canListen = false;
//  String _playerTxt = '';
bool _loading = false;
// String _path;
var _recorderSubscription;
var _playerSubscription;
File outputFile;
String dirloc = "";

String txt = '';

  // String baseUrl = 'http://andrei1299.pythonanywhere.com';

  Future<String> fileUploadMultipart() async {
    print("FETCH");
    print(outputFile.path);
    String uri = 'http://127.0.0.1:5000/communicate';
    
    // var request = new MultipartRequest("POST", uri);

    Dio dio = new Dio();
    // dio.options.headers['Content-Type'] = 'application/json';
    FormData formData = FormData.fromMap({
      "Audio": await MultipartFile.fromFile(outputFile.path,filename: 'mesaj.wav')
    });
    // dio.options.headers['Content-Type'] = 'audio/mpeg';
    await dio.post(
    uri,
    data: formData,
    onSendProgress: (received, total) {
      if (total != -1) {
        print((received / total * 100).toStringAsFixed(0) + "%");
      }
    },
  )
  .then((response) {
    print(response.data);
      setState(() {
        canListen = true;
        _loading = false;
      // _outputFile = file;
        // _recorderSubscription = null;

      });
      downloadMp3();
  })
  .catchError((error) { 
    setState(() {
      _loading = false;
    });
    print(error); });
    }


    Future<void> downloadMp3() async  {
      // Dio dio = Dio();
      // Permission permission1 = Permission.WriteExternalStorage;
      //  bool checkPermission1 =
      //     await SimplePermissions.checkPermission(permission1);
      // // print(checkPermission1);
      // if (checkPermission1 == false) {
      //   await SimplePermissions.requestPermission(permission1);
      //   checkPermission1 = await SimplePermissions.checkPermission(permission1);
      // }
      // FileUtils.mkdir([dirloc]);

            HttpClient client = new HttpClient();
            var _downloadData = List<int>();
            Directory tempDir = await getTemporaryDirectory();
            File file = File ('${tempDir.path}/response.mp3');
            await client.getUrl(Uri.parse('http://127.0.0.1:5000/communicate'))
            .then((HttpClientRequest request) {
              return request.close();
            })
            // .then((HttpClientResponse response) {
            //   response.listen((d) => _downloadData.addAll(d),
            //     onDone: () {
            //       file.writeAsBytes(_downloadData);
            //     }
            //   );
            // });
            .then((HttpClientResponse response) {
              response.pipe(file.openWrite());
            });
            print(file.path);
            setState(() {
              outputFile = file;
            });
            print(outputFile.path);
            // return file.path;

      // var request = new http.Request("GET", Uri.parse('http://127.0.0.1:5000/communicate'));
      // var response = await request.send();
      // response.stream.transform(utf8.decoder).listen((value) {
      //   _outputFile = value.;
      // });
      // setState(() {
      //   _outputFile = File(dirloc + "output.mp3");
      // });
    
    }

    Future startRecording() async {

      print("START");
      PermissionStatus status = await Permission.microphone.request();
      if (status != PermissionStatus.granted)
              throw flutterSound.RecordingPermissionException("Microphone permission not granted");
      print("START 2");
      Directory tempDir = await getTemporaryDirectory();
      setState(() {
        _isRecording = true;
        outputFile = File('${tempDir.path}/flutter_sound-tmp.wav');
      });
      await myRecorder.startRecorder(toFile: outputFile.path, codec: flutterSound.Codec.pcm16WAV,);
      print("START 3");
      print("START 4");
    }

  Future stopRecording() async {

    print("STOP");

    await myRecorder.stopRecorder();
    if (_recorderSubscription != null)
    {
      _recorderSubscription.cancel();
      _recorderSubscription = null;
    }

    // print('stopRecorder: $result');
      setState(() {
        _isRecording = false;
        _loading = true;
        // _recorderSubscription = null;
      });
      await fileUploadMultipart();
  }

 Future startPlaying() async {
   
  this.setState(() {
      this._isListening = true;
      // this._playerTxt = txt.substring(0, 7);
    });   
  await myPlayer.startPlayer(fromURI: outputFile.path, codec: flutterSound.Codec.mp3, 
    whenFinished: () {
      this.setState(() {
        this._isListening = false;
      }); 
    });
  // print(outputFile.path);
  // Future<String> result = (await flutterSound.startPlayer(_outputFile.path)) as Future<String>;

  // result.then((path) {
  //   print('startPlayer: $path');

  //   _playerSubscription = flutterSound.onPlayerStateChanged.listen((e) {
  //     if (e != null) {
  //       DateTime date = new DateTime.fromMillisecondsSinceEpoch(e.currentPosition.toInt());
  //       String txt = DateFormat('mm:ss:SS', 'en_US').format(date);
  //       this.setState(() {
  //         this._isListening = true;
  //         this._playerTxt = txt.substring(0, 8);
  //       });
  //     }
  //   });
  // });

}

clearRecord() {
   setState(() {
    _isListening = false;
    // _playerTxt = '';
    // _path = '';
    _recorderSubscription = null;
    _playerSubscription = null;
    outputFile = null;
    canListen = false;
    // txt = '';
   });

}

@override
void dispose()
{
  print("dispose");
        if (myRecorder != null)
        {
            myRecorder.closeAudioSession();
            myPlayer = null;
        }
        super.dispose();
}

//   final spinkit = SpinKitSquareCircle(
//   color: Colors.white,
//   size: 50.0,
//   controller: AnimationController(vsync: this, duration: const Duration(milliseconds: 1200)),
// );

  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: const Text('Send your location', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blue,
          brightness: Brightness.light,
          actions: <Widget>[
            Switch(value: _enabled, onChanged: _onClickEnable),
          ]
        ),
        body: Center(
          child: !_loading ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: FloatingActionButton(
                            backgroundColor: _isRecording || canListen
                                ? Colors.redAccent
                                : Colors.blueAccent,
                            child: canListen
                                ? Icon(Icons.clear, size: 30)
                                : _isRecording
                                    ? Icon(Icons.stop, size: 30)
                                    : Icon(Icons.mic, size: 30),
                            onPressed: () {
                              if(canListen) {
                                clearRecord();
                              } else 
                                if (!_isRecording) {
                                  startRecording();
                                } else {
                                  stopRecording();
                                }
                            }),
                      ),
                    ],
                  )),
              Text(
                '  ',
                style: Theme.of(context).textTheme.headline4,
              ),
              canListen == true
                  ? Column(
                    children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: FloatingActionButton(
                                backgroundColor: Colors.greenAccent,
                                child: Icon(Icons.hearing, size: 30),
                                onPressed: () {
                                  startPlaying();
                                }),
                          ),
                        ],
                      )),
                    ],
                  )
                  : Container()
            ],
          ) : 
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Color.fromRGBO(0, 0, 0, 0.4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SpinKitWave(
                  color: Colors.white,
                  size: 50.0,
                )
            ],),
          ),
        ),
      ),
    );
  }
}
