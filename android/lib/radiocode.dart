import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'const.dart';

class RadioCodeEntry {
  String key;
  String func;
  int id;
  String name;

  RadioCodeEntry(this.id, this.name);

  RadioCodeEntry.fromSnapshot(DataSnapshot snapshot) {
    key = snapshot.key;
    func = snapshot.value['func'] ?? '';
    id = snapshot.value['id'] ?? 0;
    name = snapshot.value['name'] ?? '';
  }

  toJson() {
    return {
      'func': func,
      'id': id,
      'name': name,
    };
  }
}

class RadioCodeListItem extends StatelessWidget {
  final RadioCodeEntry codeEntry;

  RadioCodeListItem(this.codeEntry);

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
                new Column(
                  children: [
                    new Text(
                      codeEntry.name,
                      textScaleFactor: 1.5,
                      textAlign: TextAlign.left,
                    ),
                    new Text(
                      codeEntry.id.toString(),
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                    ),
                    new Text(
                      codeEntry.func,
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                    ),
                  ],
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RadioCode extends StatefulWidget {
  RadioCode({Key key, this.title}) : super(key: key);

  static const String routeName = '/radiocode';

  final String title;

  @override
  _RadioCodeState createState() => new _RadioCodeState();
}

class _RadioCodeState extends State<RadioCode> {
  List<RadioCodeEntry> codeInactiveSaves = new List();
  DatabaseReference _codeInactiveRef;
  List<RadioCodeEntry> codeActiveRxSaves = new List();
  DatabaseReference _codeActiveRxRef;
  List<RadioCodeEntry> codeActiveTxSaves = new List();
  DatabaseReference _codeActiveTxRef;
  List<RadioCodeEntry> ioMenu;
  String selection;

  _RadioCodeState() {
    _codeInactiveRef = FirebaseDatabase.instance
        .reference()
        .child(kRadioCodesRef)
        .child('Inactive');
    _codeInactiveRef.onChildAdded.listen(_onInactiveEntryAdded);
    _codeInactiveRef.onChildChanged.listen(_onInactiveEntryEdited);
    _codeInactiveRef.onChildRemoved.listen(_onInactiveEntryRemoved);
    _codeActiveRxRef =
        FirebaseDatabase.instance.reference().child(kRadioCodesRef).child(
            'Active');
    _codeActiveRxRef.onChildAdded.listen(_onActiveRxEntryAdded);
    _codeActiveRxRef.onChildChanged.listen(_onActiveRxEntryEdited);
    _codeActiveRxRef.onChildRemoved.listen(_onActiveRxEntryRemoved);
    _codeActiveTxRef =
        FirebaseDatabase.instance.reference().child(kRadioCodesRef).child(
            'ActiveTx');
    _codeActiveTxRef.onChildAdded.listen(_onActiveTxEntryAdded);
    _codeActiveTxRef.onChildChanged.listen(_onActiveTxEntryEdited);
    _codeActiveTxRef.onChildRemoved.listen(_onActiveTxEntryRemoved);
  }

  @override
  void initState() {
    super.initState();
    print('_RadioCodeState');
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              new Text('Inactive'),
              new ListView.builder(
                shrinkWrap: true,
                reverse: true,
                itemCount: codeInactiveSaves.length,
                itemBuilder: (buildContext, index) {
                  return new InkWell(
                      // onTap: () => _openRemoveEntryDialog(codeInactiveSaves[index]),
                      child: new RadioCodeListItem(codeInactiveSaves[index]));
                },
              ),
            ])),
        new Card(
            child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
              new Text('Rx Active'),
              new ListView.builder(
                shrinkWrap: true,
                reverse: true,
                itemCount: codeActiveRxSaves.length,
                itemBuilder: (buildContext, index) {
                  return new InkWell(
                      // onTap: () => _openRemoveEntryDialog(codeInactiveSaves[index]),
                      child: new RadioCodeListItem(codeActiveRxSaves[index]));
                },
              ),
            ])),
        new Card(
            child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
              new Text('Tx Active'),
              new ListView.builder(
                shrinkWrap: true,
                reverse: true,
                itemCount: codeActiveTxSaves.length,
                itemBuilder: (buildContext, index) {
                  return new InkWell(
                      // onTap: () => _openRemoveEntryDialog(codeInactiveSaves[index]),
                      child: new RadioCodeListItem(codeActiveTxSaves[index]));
                },
              ),
            ])),
      ]),
      floatingActionButton: new FloatingActionButton(
        onPressed: _onFloatingActionButtonPressed,
        tooltip: 'add',
        child: new Icon(Icons.add),
      ),
    );
  }

  _onInactiveEntryAdded(Event event) {
    print('_onInactiveEntryAdded');
    setState(() {
      codeInactiveSaves.add(new RadioCodeEntry.fromSnapshot(event.snapshot));
    });
  }

  _onInactiveEntryEdited(Event event) {
    print('_onInactiveEntryEdited');
    var oldValue = codeInactiveSaves
        .singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      codeInactiveSaves[codeInactiveSaves.indexOf(oldValue)] =
          new RadioCodeEntry.fromSnapshot(event.snapshot);
    });
  }

  _onInactiveEntryRemoved(Event event) {
    print('_onInactiveEntryRemoved');
    var oldValue = codeInactiveSaves
        .singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      codeInactiveSaves.remove(oldValue);
    });
  }

  _onActiveRxEntryAdded(Event event) {
    print('_onActiveRxEntryAdded');
    setState(() {
      codeActiveRxSaves.add(new RadioCodeEntry.fromSnapshot(event.snapshot));
    });
  }

  _onActiveRxEntryEdited(Event event) {
    print('_onActiveRxEntryEdited');
    var oldValue = codeActiveRxSaves
        .singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      codeActiveRxSaves[codeActiveRxSaves.indexOf(oldValue)] =
          new RadioCodeEntry.fromSnapshot(event.snapshot);
    });
  }

  _onActiveRxEntryRemoved(Event event) {
    print('_onActiveRxEntryRemoved');
    var oldValue = codeActiveRxSaves
        .singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      codeActiveRxSaves.remove(oldValue);
    });
  }

  _onActiveTxEntryAdded(Event event) {
    print('_onActiveTxEntryAdded');
    setState(() {
      codeActiveTxSaves.add(new RadioCodeEntry.fromSnapshot(event.snapshot));
    });
  }

  _onActiveTxEntryEdited(Event event) {
    print('_onActiveTxEntryEdited');
    var oldValue = codeActiveTxSaves
        .singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      codeActiveTxSaves[codeActiveTxSaves.indexOf(oldValue)] =
          new RadioCodeEntry.fromSnapshot(event.snapshot);
    });
  }

  _onActiveTxEntryRemoved(Event event) {
    print('_onActiveRxEntryRemoved');
    var oldValue = codeActiveTxSaves
        .singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      codeActiveTxSaves.remove(oldValue);
    });
  }

  void _onFloatingActionButtonPressed() {}
}
