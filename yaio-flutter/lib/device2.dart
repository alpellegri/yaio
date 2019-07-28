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
  _DeviceConfigState createState() => new _DeviceConfigState();
}

class _DeviceConfigState extends State<DeviceConfig> {
  DatabaseReference _rootRef;
  DatabaseReference _controlRef;
  DatabaseReference _statusRef;
  DatabaseReference _startupRef;
  StreamSubscription<Event> _controlSub;
  StreamSubscription<Event> _statusSub;
  StreamSubscription<Event> _startupSub;

  @override
  void initState() {
    super.initState();

    _rootRef = FirebaseDatabase.instance.reference().child(getRootRef());
    _controlRef =
        _rootRef.child(widget.domain).child(widget.node).child('control');
    _statusRef =
        _rootRef.child(widget.domain).child(widget.node).child('status');
    _startupRef =
        _rootRef.child(widget.domain).child(widget.node).child('startup');
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
    print('_DeviceConfigState');
    DateTime current = new DateTime.now();
    DateTime _startupTime = new DateTime.fromMillisecondsSinceEpoch(
        int.parse(widget.value['startup']['time'].toString()) * 1000);
    DateTime _heartbeatTime = new DateTime.fromMillisecondsSinceEpoch(
        int.parse(widget.value['status']['time'].toString()) * 1000);
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

    if ((widget.value['status'] != null) && (widget.value['control'] != null)) {
      DateTime statusTime = new DateTime.fromMillisecondsSinceEpoch(
          int.parse(widget.value['status']['time'].toString()) * 1000);
      DateTime controlTime = new DateTime.fromMillisecondsSinceEpoch(
          int.parse(widget.value['control']['time'].toString()) * 1000);
      Duration diff = statusTime.difference(controlTime);
      online = (diff.inSeconds >= 0);
    }
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.node),
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
                subtitle: new Text('${widget.domain}/${widget.node}'),
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
                                    new NodeSetup(
                                        domain: widget.domain,
                                        node: widget.node),
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
              subtitle:
                  new Text('Device Memory: ${widget.value['status']["heap"]}'),
            ),
            new ListTile(
              leading: (widget.value['control']['reboot'] == kNodeUpdate)
                  ? (new CircularProgressIndicator(
                      value: null,
                    ))
                  : (const Icon(Icons.update)),
              title: const Text('Update Device'),
              subtitle: const Text('Configuration'),
              trailing: new FlatButton(
                textColor: Theme.of(context).accentColor,
                child: const Text('UPDATE'),
                onPressed: () {
                  _nodeActionRequest(kNodeUpdate);
                },
              ),
            ),
            new ListTile(
              leading: (widget.value['control']['reboot'] == kNodeReboot)
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
              leading: (widget.value['control']['reboot'] == kNodeFlash)
                  ? (new CircularProgressIndicator(
                      value: null,
                    ))
                  : (const Icon(Icons.system_update_alt)),
              title: const Text('Firmware Version'),
              subtitle: new Text('${widget.value['startup']["version"]}'),
              trailing: new FlatButton(
                textColor: Theme.of(context).accentColor,
                child: const Text('UPGRADE'),
                onPressed: () {
                  _nodeActionRequest(kNodeFlash);
                },
              ),
            ),
            new ListTile(
              leading: (widget.value['control']['reboot'] == kNodeErase)
                  ? (new CircularProgressIndicator(
                      value: null,
                    ))
                  : (const Icon(Icons.delete_forever)),
              title: const Text('Erase device'),
              subtitle: new Text(widget.node),
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
      widget.value['startup'] = event.snapshot.value;
    });
  }

  void _onValueControl(Event event) {
    setState(() {
      widget.value['control'] = event.snapshot.value;
    });
  }

  void _onValueStatus(Event event) {
    setState(() {
      widget.value['status'] = event.snapshot.value;
    });
  }

  void _nodeActionRequest(int value) {
    widget.value['control']['reboot'] = value;
    DateTime now = new DateTime.now();
    widget.value['control']['time'] = now.millisecondsSinceEpoch ~/ 1000;
    _controlRef.set(widget.value['control']);
  }
}
