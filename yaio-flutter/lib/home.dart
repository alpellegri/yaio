import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_utils.dart';
import 'const.dart';
import 'entries.dart';
import 'chart_history.dart';
import 'ui_data_io.dart';

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
  StreamSubscription<Event> _onChangedSubscription;
  StreamSubscription<Event> _onRemoveSubscription;

  bool _connected = false;

  Map<dynamic, dynamic> _control;
  Map<dynamic, dynamic> _status;
  Map<dynamic, dynamic> _startup;

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
    _onChangedSubscription = _dataRef.onChildChanged.listen(_onEntryChanged);
    _onRemoveSubscription = _dataRef.onChildRemoved.listen(_onEntryRemoved);
  }

  @override
  void dispose() {
    super.dispose();
    _controlSub.cancel();
    _statusSub.cancel();
    _startupSub.cancel();
    _onAddSubscription.cancel();
    _onChangedSubscription.cancel();
    _onRemoveSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    if (_connected == false) {
      return new Scaffold(
          appBar: new AppBar(
            title: new Text('${widget.title}'),
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
          appBar: new AppBar(
            title: new Text('${widget.title} @ ${getDomain()}/${getOwner()}'),
          ),
          body: new ListView(children: <Widget>[
            new Card(
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  new ListTile(
                    leading: (current.difference(_heartbeatTime) > time_limit)
                        ? (new Icon(Icons.sync, color: Colors.red[200]))
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
                      if (entryList[index].drawWr == true) {
                        return new InkWell(
                          onTap: () {
                            _openEntryDialog(entryList[index]);
                            _nodeUpdate(kNodeUpdate);
                          },
                          child: new DataIoItemWidget(entryList[index]),
                        );
                      } else {
                        return new InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                new MaterialPageRoute(
                                  builder: (BuildContext context) =>
                                      new ChartHistory(entryList[index].key),
                                  fullscreenDialog: true,
                                ));
                          },
                          child: new DataIoItemWidget(entryList[index]),
                        );
                      }
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
                    leading: (_control['reboot'] == kNodeUpdate)
                        ? (new CircularProgressIndicator(
                            value: null,
                          ))
                        : (const Icon(Icons.update)),
                    title: const Text('Update Device'),
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
                    leading: (_control['reboot'] == kNodeReboot)
                        ? (new CircularProgressIndicator(
                            value: null,
                          ))
                        : (const Icon(Icons.power_settings_new)),
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
                    leading: (_control['reboot'] == kNodeFlash)
                        ? (new CircularProgressIndicator(
                            value: null,
                          ))
                        : (const Icon(Icons.system_update_alt)),
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
                  new ListTile(
                    leading: (_control['reboot'] == kNodeErase)
                        ? (new CircularProgressIndicator(
                            value: null,
                          ))
                        : (const Icon(Icons.delete_forever)),
                    title: const Text('Erase device'),
                    subtitle: new Text('${getOwner()}'),
                    trailing: new ButtonTheme.bar(
                      child: new ButtonBar(
                        children: <Widget>[
                          new FlatButton(
                            child: const Text('ERASE'),
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
    bool drawWr = event.snapshot.value["drawWr"];
    bool drawRd = event.snapshot.value["drawRd"];
    if (((drawWr == true) || (drawRd == true))) {
      setState(() {
        IoEntry entry = new IoEntry.fromMap(
            _dataRef, event.snapshot.key, event.snapshot.value);
        entryList.add(entry);
      });
    }
  }

  void _onEntryChanged(Event event) {
    bool drawWr = event.snapshot.value["drawWr"];
    bool drawRd = event.snapshot.value["drawRd"];
    if (((drawWr == true) || (drawRd == true))) {
      IoEntry oldValue =
          entryList.singleWhere((el) => el.key == event.snapshot.key);
      setState(() {
        entryList[entryList.indexOf(oldValue)] = new IoEntry.fromMap(
            _dataRef, event.snapshot.key, event.snapshot.value);
      });
    }
  }

  void _onEntryRemoved(Event event) {
    bool drawWr = event.snapshot.value["drawWr"];
    bool drawRd = event.snapshot.value["drawRd"];
    if (((drawWr == true) || (drawRd == true))) {
      IoEntry oldValue =
          entryList.singleWhere((el) => el.key == event.snapshot.key);
      setState(() {
        entryList.remove(oldValue);
      });
    }
  }

  void _openEntryDialog(IoEntry entry) {
    showDialog<Null>(
      context: context,
      builder: (BuildContext context) {
        return new DataIoShortDialogWidget(entry);
      },
    );
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

class DataIoShortDialogWidget extends StatefulWidget {
  final IoEntry entry;

  DataIoShortDialogWidget(this.entry);

  @override
  _DataIoShortDialogWidgetState createState() =>
      new _DataIoShortDialogWidgetState(entry);
}

class _DataIoShortDialogWidgetState extends State<DataIoShortDialogWidget> {
  final IoEntry entry;

  dynamic _currentValue;

  void _handleTapboxChanged(dynamic newValue) {
    print('_handleTapboxChanged $newValue');
    setState(() {
      _currentValue = newValue;
    });
  }

  _DataIoShortDialogWidgetState(this.entry);

  @override
  void initState() {
    super.initState();
    if (entry.value != null) {
      _currentValue = entry?.value;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new AlertDialog(
        title: new Text('Edit'),
        content: new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new DynamicEditWidget(
                type: entry.code,
                value: _currentValue,
                onChanged: _handleTapboxChanged,
              ),
            ]),
        actions: <Widget>[
          new FlatButton(
              child: const Text('SAVE'),
              onPressed: () {
                try {
                  entry.value = _currentValue;
                  entry.reference.child(entry.key).set(entry.toJson());
                } catch (exception) {
                  print('bug');
                }
                Navigator.pop(context, null);
              }),
          new FlatButton(
              child: const Text('DISCARD'),
              onPressed: () {
                Navigator.pop(context, null);
              }),
        ]);
  }
}
