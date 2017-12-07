import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'drawer.dart';
import 'firebase_utils.dart';
import 'const.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const time_limit = const Duration(seconds: 20);
  final DatabaseReference _controlRef =
      FirebaseDatabase.instance.reference().child(kControlRef);
  final DatabaseReference _statusRef =
      FirebaseDatabase.instance.reference().child(kStatusRef);
  final DatabaseReference _startupRef =
      FirebaseDatabase.instance.reference().child(kStartupRef);
  final DatabaseReference _fcmRef =
      FirebaseDatabase.instance.reference().child(kTokenIDsRef);
  final FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();

  StreamSubscription<Event> _controlSub;
  StreamSubscription<Event> _statusSub;
  StreamSubscription<Event> _startupSub;

  Map _fbJsonMap;
  String _infoConfig = "";
  String _homeScreenText = "Waiting for token...";
  bool _connected = false;

  Map<String, Object> _control = {
    'alarm': false,
    'radio_learn': false,
    'radio_update': false,
    'reboot': false,
    'time': 0,
  };
  Map<String, Object> _status = {
    'alarm': false,
    'heap': 0,
    'humidity': 0,
    'monitor': false,
    'temperature': 0,
    'time': 0,
  };
  Map<String, Object> _startup = {
    'bootcnt': 0,
    'time': 0,
    'version': '',
  };

  @override
  void initState() {
    super.initState();
    _connected = false;
    configFirefase().then((value) {
      _fbJsonMap = value;
      _infoConfig =
          'project_number ${_fbJsonMap["project_info"]['project_number']}\n'
          'firebase_url ${_fbJsonMap["project_info"]['firebase_url']}\n'
          'project_id ${_fbJsonMap["project_info"]['project_id']}\n'
          'storage_bucket ${_fbJsonMap["project_info"]['storage_bucket']}\n';
    });
    signInWithGoogle().then((onValue) {
      _firebaseMessaging.configure(
        onMessage: (Map<String, dynamic> message) {
          print("onMessage: $message");
          // _showItemDialog(message);
        },
        onLaunch: (Map<String, dynamic> message) {
          print("onLaunch: $message");
          // _navigateToItemDetail(message);
        },
        onResume: (Map<String, dynamic> message) {
          print("onResume: $message");
          // _navigateToItemDetail(message);
        },
      );
      _firebaseMessaging.requestNotificationPermissions(
          const IosNotificationSettings(sound: true, badge: true, alert: true));
      _firebaseMessaging.onIosSettingsRegistered
          .listen((IosNotificationSettings settings) {
        print("Settings registered: $settings");
      });
      _firebaseMessaging.getToken().then((String token) {
        assert(token != null);
        setState(() {
          _homeScreenText = "Push Messaging token: $token";
        });
        _fcmRef.once().then((DataSnapshot onValue) {
          print("once: ${onValue.value}");
          Map map = onValue.value;
          bool tokenFound = false;
          if (map != null) {
            map.forEach((key, value) {
              if (value == token) {
                print("key test: $key");
                tokenFound = true;
              }
            });
          }
          if (tokenFound == false) {
            _fcmRef.push().set(token);
            print("token saved: $token");
          }
          // at the end, not before
          FirebaseDatabase.instance.setPersistenceEnabled(true);
          FirebaseDatabase.instance.setPersistenceCacheSizeBytes(10000000);
        });
        print(_homeScreenText);
        _connected = true;
      });

      _controlSub = _controlRef.onValue.listen(_onValueControl);
      _statusSub = _statusRef.onValue.listen(_onValueStatus);
      _startupSub = _startupRef.onValue.listen(_onValueStartup);
    });
    print('_MyHomePageState');
  }

  @override
  void dispose() {
    super.dispose();
    _controlSub.cancel();
    _statusSub.cancel();
    _startupSub.cancel();
  }

  @override
  Widget build(BuildContext context) {
    String alarmButton;
    if (_status["alarm"] == true) {
      if (_control["alarm"] == true) {
        alarmButton = "DEACTIVATE";
      } else {
        alarmButton = "DISARMING";
      }
    } else {
      if (_control["alarm"] == false) {
        alarmButton = "ACTIVATE";
      } else {
        alarmButton = "ARMING";
      }
    }
    String monitorButton;
    if (_control["radio_learn"] == true) {
      monitorButton = "DEACTIVATE";
    } else {
      monitorButton = "ACTIVATE";
    }
    DateTime current = new DateTime.now();
    DateTime _startupTime = new DateTime.fromMillisecondsSinceEpoch(
        int.parse(_startup['time'].toString()) * 1000);
    DateTime _heartbeatTime = new DateTime.fromMillisecondsSinceEpoch(
        int.parse(_status['time'].toString()) * 1000);
    return new Scaffold(
        drawer: drawer,
        appBar: new AppBar(
          title: new Text(widget.title),
        ),
        body: (_connected == true)
            ? (new ListView(children: <Widget>[
                new Card(
                  child: new Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      new ListTile(
                        leading: (current.difference(_heartbeatTime) >
                                time_limit)
                            ? (new Icon(Icons.album, color: Colors.red[200]))
                            : (new Icon(Icons.album, color: Colors.green[200])),
                        title: const Text('Device Status'),
                      ),
                      new ListTile(
                        leading: (_status['alarm'] == true)
                            ? (new Icon(Icons.lock_outline,
                                color: Colors.red[200]))
                            : (new Icon(Icons.lock_open,
                                color: Colors.green[200])),
                        title: const Text('Alarm Status'),
                        subtitle: new Text(
                            '${_status["alarm"] ? "ACTIVE" : "INACTIVE"}'),
                        trailing: new ButtonTheme.bar(
                          // make buttons use the appropriate styles for cards
                          child: new ButtonBar(
                            children: <Widget>[
                              new FlatButton(
                                child: new Text(alarmButton),
                                onPressed: () {
                                  _control['alarm'] = !_control['alarm'];
                                  DateTime now = new DateTime.now();
                                  _control['time'] =
                                      now.millisecondsSinceEpoch ~/ 1000;
                                  _controlRef.set(_control);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                new Card(
                  child: new Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      new ListTile(
                        leading: const Icon(Icons.show_chart),
                        title: const Text('Temperature/Humidity'),
                        subtitle: new Text(
                            '${_status["temperature"]}°C / ${_status["humidity"]}%'),
                      ),
                    ],
                  ),
                ),
                new Card(
                  child: new Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      new ListTile(
                        leading: const Icon(Icons.network_check),
                        title: const Text('RF monitoring'),
                        subtitle: new Text(
                            '${_control["radio_learn"] ? "ACTIVE" : "INACTIVE"}'),
                        trailing: new ButtonTheme.bar(
                          // make buttons use the appropriate styles for cards
                          child: new ButtonBar(
                            children: <Widget>[
                              new FlatButton(
                                child: new Text(monitorButton),
                                onPressed: () {
                                  _control['radio_learn'] =
                                      !_control['radio_learn'];
                                  DateTime now = new DateTime.now();
                                  _control['time'] =
                                      now.millisecondsSinceEpoch ~/ 1000;
                                  _controlRef.set(_control);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      new ListTile(
                        leading: const Icon(Icons.link),
                        title: const Text('HeartBeat'),
                        subtitle: new Text('${_heartbeatTime.toString()}'),
                      ),
                      new ListTile(
                        leading: (_control['reboot'] == 3)
                            ? (new LinearProgressIndicator(
                                value: null,
                              ))
                            : (const Icon(Icons.flash_on)),
                        title: const Text('Update Node'),
                        subtitle: new Text('Configuration'),
                        trailing: new ButtonTheme.bar(
                          child: new ButtonBar(
                            children: <Widget>[
                              new FlatButton(
                                child: const Text('UPDATE'),
                                onPressed: () {
                                  _control['reboot'] = 3;
                                  _controlRef.set(_control);
                                  DateTime now = new DateTime.now();
                                  _control['time'] =
                                      now.millisecondsSinceEpoch ~/ 1000;
                                  _controlRef.set(_control);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      new ListTile(
                        leading: (_control['reboot'] == 1)
                            ? (new LinearProgressIndicator(
                                value: null,
                              ))
                            : (const Icon(Icons.power)),
                        title: const Text('PowerUp'),
                        subtitle: new Text('${_startupTime.toString()}'),
                        trailing: new ButtonTheme.bar(
                          child: new ButtonBar(
                            children: <Widget>[
                              new FlatButton(
                                child: const Text('RESTART'),
                                onPressed: () {
                                  _control['reboot'] = 1;
                                  _controlRef.set(_control);
                                  DateTime now = new DateTime.now();
                                  _control['time'] =
                                      now.millisecondsSinceEpoch ~/ 1000;
                                  _controlRef.set(_control);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      new ListTile(
                        leading: (_control['reboot'] == 2)
                            ? (new LinearProgressIndicator(
                                value: null,
                              ))
                            : (const Icon(Icons.flash_on)),
                        title: const Text('Firmware Version'),
                        subtitle: new Text('${_startup["version"]}'),
                        trailing: new ButtonTheme.bar(
                          child: new ButtonBar(
                            children: <Widget>[
                              new FlatButton(
                                child: const Text('UPGRADE'),
                                onPressed: () {
                                  _control['reboot'] = 2;
                                  _controlRef.set(_control);
                                  DateTime now = new DateTime.now();
                                  _control['time'] =
                                      now.millisecondsSinceEpoch ~/ 1000;
                                  _controlRef.set(_control);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                new Card(
                  child: new Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      new Text('Node Heap Memory: ${_status["heap"]}'),
                      new Text('Firebase info'),
                      new Text(_infoConfig),
                      new Text('Firebase Messaging info'),
                      new Text(_homeScreenText),
                    ],
                  ),
                ),
              ]))
            : (new LinearProgressIndicator(
                value: null,
              )));
  }

  void _onValueControl(Event event) {
    setState(() {
      _control = event.snapshot.value;
    });
  }

  void _onValueStatus(Event event) {
    // update control time to keep up node
    DateTime now = new DateTime.now();
    setState(() {
      _control['time'] = now.millisecondsSinceEpoch ~/ 1000;
      _controlRef.set(_control);
      _status = event.snapshot.value;
    });
  }

  void _onValueStartup(Event event) {
    setState(() {
      _startup = event.snapshot.value;
    });
  }
}
