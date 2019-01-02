import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'node_setup.dart';
import 'firebase_utils.dart';
import 'const.dart';
import 'entries.dart';
import 'chart_history.dart';
import 'ui_data_io.dart';

class DeviceConfig extends StatefulWidget {
  final String domain;
  final String node;
  final dynamic value;

  DeviceConfig({Key key, this.domain, this.node, this.value}) : super(key: key);

  @override
  _DeviceConfigState createState() =>
      new _DeviceConfigState(this.domain, this.node, this.value);
}

class _DeviceConfigState extends State<DeviceConfig> {
  final String domain;
  final String node;
  final dynamic value;
  dynamic _startup;
  dynamic _control;
  dynamic _status;
  DatabaseReference _rootRef;
  DatabaseReference _controlRef;
  DatabaseReference _statusRef;
  DatabaseReference _startupRef;
  StreamSubscription<Event> _controlSub;
  StreamSubscription<Event> _statusSub;
  StreamSubscription<Event> _startupSub;

  _DeviceConfigState(this.domain, this.node, this.value);

  @override
  void initState() {
    super.initState();
    _startup = value['startup'];
    _control = value['control'];
    _status = value['status'];
    _rootRef = FirebaseDatabase.instance.reference().child(getRootRef());
    _controlRef = _rootRef.child(domain).child(node).child('control');
    _statusRef = _rootRef.child(domain).child(node).child('status');
    _startupRef = _rootRef.child(domain).child(node).child('startup');
    _controlSub = _controlRef.onValue.listen(_onValueControl);
    _statusSub = _statusRef.onValue.listen(_onValueStatus);
    _startupSub = _startupRef.onValue.listen(_onValueStartup);
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
    DateTime current = new DateTime.now();
    DateTime _startupTime = new DateTime.fromMillisecondsSinceEpoch(
        int.parse(_startup['time'].toString()) * 1000);
    DateTime _heartbeatTime = new DateTime.fromMillisecondsSinceEpoch(
        int.parse(_status['time'].toString()) * 1000);
    Duration diff = current.difference(_heartbeatTime);
    String diffTime;
    if (diff.inDays > 0) {
      diffTime = '${diff.inDays} days ago';
    } else if (diff.inHours > 0) {
      diffTime = '${diff.inHours} hours ago';
    } else if (diff.inMinutes > 0) {
      diffTime = '${diff.inMinutes} minutes ago';
    } else if (diff.inSeconds > 0) {
      diffTime = '${diff.inSeconds} seconds ago';
    } else {
      diffTime = 'now';
    }
    bool online = false;
    if ((value['status'] != null) && (value['control'] != null)) {
      DateTime statusTime = new DateTime.fromMillisecondsSinceEpoch(
          int.parse(value['status']['time'].toString()) * 1000);
      DateTime controlTime = new DateTime.fromMillisecondsSinceEpoch(
          int.parse(value['control']['time'].toString()) * 1000);
      Duration diff = statusTime.difference(controlTime);
      online = (diff.inSeconds >= 0);
    }
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(node),
      ),
      body: new ListView(children: <Widget>[
        new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new ListTile(
                leading: (false)
                    ? (const Icon(Icons.link_off))
                    : (const Icon(Icons.link)),
                title: const Text('Selected Device'),
                subtitle: new Text('$domain/$node'),
                trailing: new FlatButton(
                  textColor: Theme.of(context).accentColor,
                  child: const Text('CONFIGURE'),
                  onPressed: (false)
                      ? null
                      : () {
                          Navigator.push(
                              context,
                              new MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    new NodeSetup(domain: domain, node: node),
                                fullscreenDialog: true,
                              ));
                        },
                ),
              ),
            ]),
        new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new ListTile(
              leading: (online)
                  ? (new Icon(Icons.cloud_done, color: Colors.green[400]))
                  : (new Icon(Icons.cloud_queue, color: Colors.red[400])),
              title: new Text('HeartBeat: $diffTime'),
              subtitle: new Text('Device Memory: ${_status["heap"]}'),
            ),
            new ListTile(
              leading: (_control['reboot'] == kNodeUpdate)
                  ? (new CircularProgressIndicator(
                      value: null,
                    ))
                  : (const Icon(Icons.update)),
              title: const Text('Update Device'),
              subtitle: new Text('Configuration'),
              trailing: new FlatButton(
                textColor: Theme.of(context).accentColor,
                child: const Text('UPDATE'),
                onPressed: () {
                  _nodeActionRequest(kNodeUpdate);
                },
              ),
            ),
            new ListTile(
              leading: (_control['reboot'] == kNodeReboot)
                  ? (new CircularProgressIndicator(
                      value: null,
                    ))
                  : (const Icon(Icons.power_settings_new)),
              title: const Text('PowerUp'),
              subtitle: new Text('${_startupTime.toString()}'),
              trailing: new FlatButton(
                textColor: Theme.of(context).accentColor,
                child: const Text('RESTART'),
                onPressed: () {
                  _nodeActionRequest(kNodeReboot);
                },
              ),
            ),
            new ListTile(
              leading: (_control['reboot'] == kNodeFlash)
                  ? (new CircularProgressIndicator(
                      value: null,
                    ))
                  : (const Icon(Icons.system_update_alt)),
              title: const Text('Firmware Version'),
              subtitle: new Text('${_startup["version"]}'),
              trailing: new FlatButton(
                textColor: Theme.of(context).accentColor,
                child: const Text('UPGRADE'),
                onPressed: () {
                  _nodeActionRequest(kNodeFlash);
                },
              ),
            ),
            new ListTile(
              leading: (_control['reboot'] == kNodeErase)
                  ? (new CircularProgressIndicator(
                      value: null,
                    ))
                  : (const Icon(Icons.delete_forever)),
              title: const Text('Erase device'),
              subtitle: new Text(node),
              trailing: new FlatButton(
                textColor: Theme.of(context).accentColor,
                child: const Text('ERASE'),
                onPressed: () {
                  _nodeActionRequest(kNodeErase);
                },
              ),
            ),
          ],
        ),
      ]),
    );
  }

  void _onValueStartup(Event event) {
    setState(() {
      _startup = event.snapshot.value;
    });
  }

  void _onValueControl(Event event) {
    setState(() {
      _control = event.snapshot.value;
    });
  }

  void _onValueStatus(Event event) {
    setState(() {
      _status = event.snapshot.value;
    });
  }

  void _nodeActionRequest(int value) {
    _control['reboot'] = value;
    DateTime now = new DateTime.now();
    _control['time'] = now.millisecondsSinceEpoch ~/ 1000;
    _controlRef.set(_control);
  }
}
