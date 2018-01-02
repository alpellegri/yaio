import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'firebase_utils.dart';
import 'chart_history.dart';
import 'const.dart';

class Home extends StatefulWidget {
  Home({Key key, this.title}) : super(key: key);

  static const String routeName = '/home';

  final String title;

  @override
  _HomeState createState() => new _HomeState();
}

class _HomeState extends State<Home> {
  static const time_limit = const Duration(seconds: 20);
  DatabaseReference _controlRef;
  DatabaseReference _statusRef;
  DatabaseReference _startupRef;
  DatabaseReference _fcmRef;
  int _controlTimeoutCnt;

  StreamSubscription<Event> _controlSub;
  StreamSubscription<Event> _statusSub;
  StreamSubscription<Event> _startupSub;

  bool _connected = false;
  bool _nodeNeedUpdate = false;

  Map<String, Object> _control;
  Map<String, Object> _status;
  Map<String, Object> _startup;

  @override
  void initState() {
    super.initState();
    print('_MyHomePageState');

    _controlTimeoutCnt = 0;
    _controlRef = FirebaseDatabase.instance.reference().child(getControlRef());
    _statusRef = FirebaseDatabase.instance.reference().child(getStatusRef());
    _startupRef = FirebaseDatabase.instance.reference().child(getStartupRef());
    _controlSub = _controlRef.onValue.listen(_onValueControl);
    _statusSub = _statusRef.onValue.listen(_onValueStatus);
    _startupSub = _startupRef.onValue.listen(_onValueStartup);
    _fcmRef = FirebaseDatabase.instance.reference().child(getFcmTokenRef());
    _fcmRef.once().then((DataSnapshot onValue) {
      print("once: ${onValue.value}");
      Map map = onValue.value;
      bool tokenFound = false;
      String token = getFbToken();
      if (map != null) {
        map.forEach((key, value) {
          if (value == token) {
            print("key test: $key");
            tokenFound = true;
          }
        });
      }
      if (tokenFound == false) {
        _nodeNeedUpdate = true;
        _fcmRef.push().set(token);
        print("token saved: $token");
      }

      // at the end, not before
      FirebaseDatabase.instance.setPersistenceEnabled(true);
      FirebaseDatabase.instance.setPersistenceCacheSizeBytes(10000000);
    });
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
    if (_connected == false) {
      return new Scaffold(
          drawer: drawer,
          appBar: new AppBar(
            title: new Text(widget.title),
          ),
          body: new LinearProgressIndicator(
            value: null,
          ));
    } else {
      if (_status["alarm"] == true) {
        if (_control["alarm"] == true) {
          alarmButton = "DEACTIVATE";
        } else {
          alarmButton = "DISARMING";
          _nodeUpdate(kNodeIdle);
        }
      } else {
        if (_control["alarm"] == false) {
          alarmButton = "ACTIVATE";
        } else {
          alarmButton = "ARMING";
          _nodeUpdate(kNodeIdle);
        }
      }
      DateTime current = new DateTime.now();
      DateTime _startupTime = new DateTime.fromMillisecondsSinceEpoch(
          int.parse(_startup['time'].toString()) * 1000);
      DateTime _heartbeatTime = new DateTime.fromMillisecondsSinceEpoch(
          int.parse(_status['time'].toString()) * 1000);
      // if FCM token regid was not present require a node update
      if (_nodeNeedUpdate == true) {
        _nodeNeedUpdate = false;
        _nodeUpdate(kNodeUpdate);
      }
      return new Scaffold(
          drawer: drawer,
          appBar: new AppBar(
            title: new Text(widget.title),
          ),
          body: new ListView(children: <Widget>[
            new Card(
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  new ListTile(
                    leading: (current.difference(_heartbeatTime) > time_limit)
                        ? (new Icon(Icons.sync_problem, color: Colors.red[200]))
                        : (new Icon(Icons.sync, color: Colors.green[200])),
                    title: const Text('Device Status'),
                  ),
                  new ListTile(
                    leading: (_status['alarm'] == true)
                        ? (new Icon(Icons.lock_outline, color: Colors.red[200]))
                        : (new Icon(Icons.lock_open, color: Colors.green[200])),
                    title: const Text('Alarm Status'),
                    subtitle:
                        new Text('${_status["alarm"] ? "ACTIVE" : "INACTIVE"}'),
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
                    title: const Text('Temperature / Humidity'),
                    subtitle: new Text(
                        '${_status["temperature"]}°C / ${_status["humidity"]}%'),
                    trailing: new ButtonTheme.bar(
                      child: new ButtonBar(
                        children: <Widget>[
                          new FlatButton(
                            child: const Text('SHOW'),
                            onPressed: () {
                              Navigator.of(context)
                                ..pushNamed(ChartHistory.routeName);
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
                              _nodeUpdate(kNodeUpdate);
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
                              _nodeUpdate(kNodeReboot);
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
                              _nodeUpdate(kNodeFlash);
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
                ],
              ),
            ),
          ]));
    }
  }

  bool checkConnected(){
    return ((_control != null) && (_status != null) && (_startup != null));
  }
  void _onValueControl(Event event) {
    print('_onValueControl');
    setState(() {
      _control = event.snapshot.value;
      _connected = checkConnected();
    });
  }

  void _onValueStatus(Event event) {
    print('_onValueStatus');
    // update control time to keep up node
    DateTime now = new DateTime.now();
    setState(() {
      if ((_control != null) && (_controlTimeoutCnt++ < 10)) {
        _control['time'] = now.millisecondsSinceEpoch ~/ 1000;
        _controlRef.set(_control);
      }
      _status = event.snapshot.value;
      _connected = checkConnected();
    });
  }

  void _onValueStartup(Event event) {
    print('_onValueStartup');
    setState(() {
      _startup = event.snapshot.value;
      _connected = checkConnected();
    });
  }

  void _nodeUpdate(int value) {
    _controlTimeoutCnt = 0;
    _control['reboot'] = value;
    _controlRef.set(_control);
    DateTime now = new DateTime.now();
    _control['time'] = now.millisecondsSinceEpoch ~/ 1000;
    _controlRef.set(_control);
  }
}
