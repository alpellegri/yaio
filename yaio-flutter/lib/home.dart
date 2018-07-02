import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_utils.dart';
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
  DatabaseReference _controlRef;
  StreamSubscription<Event> _controlSub;

  List<IoEntry> entryList = new List();
  DatabaseReference _dataRef;
  StreamSubscription<Event> _onAddSubscription;
  StreamSubscription<Event> _onChangedSubscription;
  StreamSubscription<Event> _onRemoveSubscription;

  Map<dynamic, dynamic> _control;

  @override
  void initState() {
    super.initState();
    print('_MyHomePageState');
    _controlRef = FirebaseDatabase.instance.reference().child(getControlRef());
    _controlSub = _controlRef.onValue.listen(_onValueControl);
    _dataRef = FirebaseDatabase.instance.reference().child(getDataRef());
    _onAddSubscription = _dataRef.onChildAdded.listen(_onEntryAdded);
    _onChangedSubscription = _dataRef.onChildChanged.listen(_onEntryChanged);
    _onRemoveSubscription = _dataRef.onChildRemoved.listen(_onEntryRemoved);
  }

  @override
  void dispose() {
    super.dispose();
    _controlSub.cancel();
    _onAddSubscription.cancel();
    _onChangedSubscription.cancel();
    _onRemoveSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text('${widget.title} @ ${getDomain()}'),
        ),
        body: new ListView(children: <Widget>[
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
                          // _nodeUpdate(kNodeUpdate);
                          _nodeRefresh();
                        },
                        child: new DataItemWidget(entryList[index]),
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
                        child: new DataItemWidget(entryList[index]),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ]));
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

  void _onValueControl(Event event) {
    print('_onValueControl');
    setState(() {
      _control = event.snapshot.value;
    });
  }

  void _nodeRefresh() {
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

  void _handleChangedValue(IoEntry newValue) {
    print('_handleTapboxChanged $newValue');
    setState(() {
      entry.value = newValue.value;
      entry.ioctl = newValue.ioctl;
    });
  }

  _DataIoShortDialogWidgetState(this.entry);

  @override
  void initState() {
    super.initState();
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
              new DataConfigWidget(
                data: entry,
                onChangedValue: _handleChangedValue,
              ),
            ]),
        actions: <Widget>[
          new FlatButton(
              child: const Text('SAVE'),
              onPressed: () {
                try {
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
