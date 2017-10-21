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
    /*func = snapshot.value['func'] ?? snapshot.value['func'];
    id = snapshot.value['id'] ?? snapshot.value['id'];
    name = snapshot.value['name'] ?? snapshot.value['name'];*/
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
  List<RadioCodeEntry> codeRxActiveSaves = new List();
  DatabaseReference _codeRxActiveRef;
  List<RadioCodeEntry> codeTxActiveSaves = new List();
  DatabaseReference _codeTxActiveRef;
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
    /*
    _codeRxActiveRef =
        FirebaseDatabase.instance.reference().child(kRadioCodesRef).child(
            'Active');
    _codeRxActiveRef.onChildAdded.listen(_onRxActiveEntryAdded);
    _codeRxActiveRef.onChildChanged.listen(_onRxActiveEntryEdited);
    _codeRxActiveRef.onChildRemoved.listen(_onRxActiveEntryRemoved);
    _codeRxActiveRef =
        FirebaseDatabase.instance.reference().child(kRadioCodesRef).child(
            'TxActive');
    _codeTxActiveRef.onChildAdded.listen(_onTxActiveEntryAdded);
    _codeTxActiveRef.onChildChanged.listen(_onTxActiveEntryEdited);
    _codeTxActiveRef.onChildRemoved.listen(_onTxActiveEntryRemoved);*/
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
      body: new Container(),
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

  _onRxActiveEntryAdded(Event event) {
    print('_onRxActiveEntryAdded');
    setState(() {
      codeRxActiveSaves.add(new RadioCodeEntry.fromSnapshot(event.snapshot));
    });
  }

  _onRxActiveEntryEdited(Event event) {
    print('_onRxActiveEntryEdited');
    var oldValue = codeRxActiveSaves
        .singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      codeRxActiveSaves[codeRxActiveSaves.indexOf(oldValue)] =
          new RadioCodeEntry.fromSnapshot(event.snapshot);
    });
  }

  _onRxActiveEntryRemoved(Event event) {
    print('_onRxActiveEntryRemoved');
    var oldValue = codeRxActiveSaves
        .singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      codeRxActiveSaves.remove(oldValue);
    });
  }

  _onTxActiveEntryAdded(Event event) {
    print('_onTxActiveEntryAdded');
    setState(() {
      codeTxActiveSaves.add(new RadioCodeEntry.fromSnapshot(event.snapshot));
    });
  }

  _onTxActiveEntryEdited(Event event) {
    print('_onTxActiveEntryEdited');
    var oldValue = codeTxActiveSaves
        .singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      codeTxActiveSaves[codeTxActiveSaves.indexOf(oldValue)] =
          new RadioCodeEntry.fromSnapshot(event.snapshot);
    });
  }

  _onTxActiveEntryRemoved(Event event) {
    print('_onRxActiveEntryRemoved');
    var oldValue = codeTxActiveSaves
        .singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      codeTxActiveSaves.remove(oldValue);
    });
  }

  void _onFloatingActionButtonPressed() {}
}
