import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'firebase_utils.dart';
import 'const.dart';
import 'entries.dart';

class EntryDialog extends StatefulWidget {
  final IoEntry entry;

  EntryDialog(this.entry);

  @override
  _EntryDialogState createState() => new _EntryDialogState(entry);
}

class _EntryDialogState extends State<EntryDialog> {
  final IoEntry entry;

  final TextEditingController _controllerName = new TextEditingController();
  final TextEditingController _controllerType = new TextEditingController();
  final TextEditingController _controllerPin = new TextEditingController();
  final TextEditingController _controllerValue = new TextEditingController();

  _EntryDialogState(this.entry);

  @override
  void initState() {
    super.initState();
    if (entry.value != null) {
      _controllerName.text = entry.key;
      _controllerType.text = entry.code.toString();
      switch (getMode(entry.code)) {
        case 1:
          _controllerPin.text = entry.getPin8().toString();
          _controllerValue.text = entry.getValue24().toString();
          break;
        case 2:
          _controllerValue.text = entry.getValue().toString();
          break;
        case 3:
          _controllerValue.text = entry.getValue();
          break;
        case 4:
          if (entry.getValue() == false) {
            _controllerValue.text = '0';
          } else if (entry.getValue() == true) {
            _controllerValue.text = '1';
          } else {
            print('_controllerValue.text error');
            _controllerValue.text = '0';
          }
          break;
        default:
      }
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
                  entry.code, _controllerPin, _controllerValue),
            ]),
        actions: <Widget>[
          new FlatButton(
              child: const Text('SAVE'),
              onPressed: () {
                try {
                  switch (getMode(entry.code)) {
                    case 1:
                      entry.setPin8(int.parse(_controllerPin.text));
                      entry.setValue24(int.parse(_controllerValue.text));
                      break;
                    case 2:
                      entry.setValue(int.parse(_controllerValue.text));
                      break;
                    case 3:
                    case 4:
                      if (_controllerValue.text == '0') {
                        entry.setValue(false);
                      } else if (_controllerValue.text == '1') {
                        entry.setValue(true);
                      } else {
                        print('_controllerValue.text error');
                      }
                      break;
                  }
                  entry.reference.child(entry.key).set(entry.toJson());
                } catch (exception, stackTrace) {
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

class DynamicEditWidget extends StatelessWidget {
  final int type;
  final TextEditingController pin;
  final TextEditingController value;

  DynamicEditWidget(this.type, this.pin, this.value);

  @override
  Widget build(BuildContext context) {
    switch (getMode(type)) {
      case 1:
        return new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new TextField(
                controller: pin,
                keyboardType: TextInputType.number,
                decoration: new InputDecoration(
                  hintText: 'pin value',
                ),
              ),
              new TextField(
                controller: value,
                keyboardType: TextInputType.number,
                decoration: new InputDecoration(
                  hintText: 'data value',
                ),
              ),
            ]);
        break;
      case 2:
        return new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new TextField(
                controller: value,
                keyboardType: TextInputType.number,
                decoration: new InputDecoration(
                  hintText: 'value',
                ),
              ),
            ]);
        break;
      case 3:
        return new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new TextField(
                controller: value,
                decoration: new InputDecoration(
                  hintText: 'value',
                ),
              ),
            ]);
      case 4:
        return new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new TextField(
                controller: value,
                keyboardType: TextInputType.number,
                decoration: new InputDecoration(
                  hintText: 'value',
                ),
              ),
            ]);
        break;
      default:
        return new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new Text(''),
            ]);
    }
  }
}

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
                      '${entry.getData() / 10}',
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
  StreamSubscription<Event> _onChangedSubscription;
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
                      if (entryList[index].drawWr == true) {
                        return new InkWell(
                            onTap: () {
                              _openEntryDialog(entryList[index]);
                              _nodeUpdate(kNodeUpdate);
                            },
                            child: new ListItem(entryList[index]));
                      } else {
                        return new ListItem(entryList[index]);
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
    showDialog(
      context: context,
      child: new EntryDialog(entry),
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
