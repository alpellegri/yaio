import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'login.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final DatabaseReference _controlReference =
      FirebaseDatabase.instance.reference().child('control');
  final DatabaseReference _statusReference =
      FirebaseDatabase.instance.reference().child('status');
  final DatabaseReference _startupReference =
      FirebaseDatabase.instance.reference().child('startup');
  Icon iconLockstatus;
  Map _configMap;
  String _infoConfig = "";

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
    configFirefase().then((value) {
      _configMap = value;
      _infoConfig =
          'project_number ${_configMap["project_info"]['project_number']}\n'
          'firebase_url ${_configMap["project_info"]['firebase_url']}\n'
          'project_id ${_configMap["project_info"]['project_id']}\n'
          'storage_bucket ${_configMap["project_info"]['storage_bucket']}\n';
    });
    FirebaseDatabase.instance.setPersistenceEnabled(true);
    FirebaseDatabase.instance.setPersistenceCacheSizeBytes(10000000);
    signInWithGoogle();
    _controlReference.onValue.listen(_onValueControl);
    _statusReference.onValue.listen(_onValueStatus);
    _startupReference.onValue.listen(_onValueStartup);
    iconLockstatus = const Icon(Icons.lock_open);
    print('_MyHomePageState');
  }

  @override
  void dispose() {
    super.dispose();
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
    DateTime _startupTime = new DateTime.fromMillisecondsSinceEpoch(
        int.parse(_startup['time'].toString()) * 1000);
    DateTime _heartbeatTime = new DateTime.fromMillisecondsSinceEpoch(
        int.parse(_status['time'].toString()) * 1000);
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
                  leading: const Icon(Icons.album),
                  title: const Text('Device Status'),
                ),
                new ListTile(
                  leading: iconLockstatus,
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
                            _controlReference.set(_control);
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
                      '${_status["temperature"]}°C / ${_status["temperature"]}%'),
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
                  leading: const Icon(Icons.power),
                  title: const Text('PowerUp'),
                  subtitle: new Text('${_startupTime.toUtc()}'),
                ),
                new ListTile(
                  leading: const Icon(Icons.link),
                  title: const Text('HeartBeat'),
                  subtitle: new Text('${_heartbeatTime.toUtc()}'),
                ),
                new ListTile(
                  leading: const Icon(Icons.loop),
                  title: const Text('Reboot Counter'),
                  subtitle: new Text('${_startup["bootcnt"]}'),
                ),
                new ListTile(
                  leading: const Icon(Icons.memory),
                  title: const Text('Heap Memory'),
                  subtitle: new Text('${_status["heap"]}'),
                ),
                new ListTile(
                  leading: const Icon(Icons.cloud_download),
                  title: const Text('Firmware Version'),
                  subtitle: new Text('${_startup["version"]}'),
                  trailing: new ButtonTheme.bar(
                    child: new ButtonBar(
                      children: <Widget>[
                        new FlatButton(
                          child: const Text('UPDATE'),
                          onPressed: () {
                            _control['reboot'] = true;
                            _controlReference.set(_control);
                            DateTime now = new DateTime.now();
                            _control['time'] =
                                now.millisecondsSinceEpoch ~/ 1000;
                            _controlReference.set(_control);
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
                new Text('Firebase info'),
                new Text(_infoConfig),
              ],
            ),
          ),
        ]));
  }

  void _onValueControl(Event event) {
    setState(() {
      _control = event.snapshot.value;
    });
  }

  void _onValueStatus(Event event) {
    // update control time to keep up node
    DateTime now = new DateTime.now();
    _control['time'] = now.millisecondsSinceEpoch ~/ 1000;
    _controlReference.set(_control);
    setState(() {
      _status = event.snapshot.value;
      if (_status['alarm'] == true) {
        iconLockstatus = const Icon(Icons.lock, color: Colors.red);
      } else {
        iconLockstatus = const Icon(Icons.lock_open, color: Colors.green);
      }
    });
  }

  void _onValueStartup(Event event) {
    setState(() {
      _startup = event.snapshot.value;
    });
  }
}
