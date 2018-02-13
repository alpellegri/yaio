import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'firebase_utils.dart';
import 'const.dart';
import 'entries.dart';

class ListItem extends StatelessWidget {
  final IoEntry entry;

  ListItem(this.entry);

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: new EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
      child: new Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          new Expanded(
            child: new Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Expanded(
                    child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    new Text(
                      entry.key,
                      textScaleFactor: 1.2,
                      textAlign: TextAlign.left,
                    ),
                    new Text(
                      '${kEntryId2Name[DataCode.values[entry.code]]}',
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                )),
                new Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    new Text(
                      '${entry.getValue()}',
                      textScaleFactor: 1.2,
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
  int _controlTimeoutCnt;

  StreamSubscription<Event> _controlSub;
  StreamSubscription<Event> _statusSub;
  StreamSubscription<Event> _startupSub;

  List<IoEntry> entryList = new List();
  DatabaseReference _dataRef;
  StreamSubscription<Event> _onAddSubscription;
  StreamSubscription<Event> _onEditSubscription;
  StreamSubscription<Event> _onRemoveSubscription;

  bool _connected = false;

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
    _dataRef = FirebaseDatabase.instance.reference().child(getDataRef());
    _onAddSubscription = _dataRef.onChildAdded.listen(_onEntryAdded);
    _onEditSubscription = _dataRef.onChildChanged.listen(_onEntryEdited);
    _onRemoveSubscription = _dataRef.onChildRemoved.listen(_onEntryRemoved);
  }

  @override
  void dispose() {
    super.dispose();
    _controlSub.cancel();
    _statusSub.cancel();
    _startupSub.cancel();
    _onAddSubscription.cancel();
    _onEditSubscription.cancel();
    _onRemoveSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
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
                ],
              ),
            ),
            new Card(
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  new ListView.builder(
                    shrinkWrap: true,
                    reverse: true,
                    itemCount: entryList.length,
                    itemBuilder: (buildContext, index) {
                      return new InkWell(
                          onTap: () {
                            _nodeUpdate(kNodeUpdate);
                          },
                          child: new ListItem(entryList[index]));
                    },
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
                        ? (new CircularProgressIndicator(
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
                        ? (new CircularProgressIndicator(
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
                        ? (new CircularProgressIndicator(
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

  void _onEntryAdded(Event event) {
    String owner = event.snapshot.value["owner"];
    bool drawWr = event.snapshot.value["drawWr"];
    bool drawRd = event.snapshot.value["drawRd"];
    if ((owner == getOwner()) && ((drawWr == true) || (drawRd == true))) {
      setState(() {
        IoEntry entry = new IoEntry.fromMap(
            _dataRef, event.snapshot.key, event.snapshot.value);
        entryList.add(entry);
      });
    }
  }

  void _onEntryEdited(Event event) {
    String owner = event.snapshot.value["owner"];
    bool drawWr = event.snapshot.value["drawWr"];
    bool drawRd = event.snapshot.value["drawRd"];
    if ((owner == getOwner()) && ((drawWr == true) || (drawRd == true))) {
      IoEntry oldValue =
          entryList.singleWhere((el) => el.key == event.snapshot.key);
      setState(() {
        entryList[entryList.indexOf(oldValue)] = new IoEntry.fromMap(
            _dataRef, event.snapshot.key, event.snapshot.value);
      });
    }
  }

  void _onEntryRemoved(Event event) {
    String owner = event.snapshot.value["owner"];
    bool drawWr = event.snapshot.value["drawWr"];
    bool drawRd = event.snapshot.value["drawRd"];
    if ((owner == getOwner()) && ((drawWr == true) || (drawRd == true))) {
      IoEntry oldValue =
          entryList.singleWhere((el) => el.key == event.snapshot.key);
      setState(() {
        entryList.remove(oldValue);
      });
    }
  }

  bool checkConnected() {
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
