import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'io_entry.dart';
import 'const.dart';

class RadioCodeListItem extends StatelessWidget {
  final RadioCodeEntry entry;

  RadioCodeListItem(this.entry);

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
                      entry.name,
                      textScaleFactor: 1.5,
                      textAlign: TextAlign.left,
                    ),
                    new Text(
                      'ID: ${entry.id.toRadixString(16).toUpperCase()}',
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    new Text(
                      'Function: ${entry.func}',
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
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
  final DatabaseReference _controlRef =
  FirebaseDatabase.instance.reference().child(kControlRef);

  List<RadioCodeEntry> codeInactiveSaves = new List();
  DatabaseReference _codeInactiveRef;
  List<RadioCodeEntry> codeActiveRxSaves = new List();
  DatabaseReference _codeActiveRxRef;
  List<RadioCodeEntry> codeActiveTxSaves = new List();
  DatabaseReference _codeActiveTxRef;
  List<RadioCodeEntry> destinationSaves;
  String selection;

  _RadioCodeState() {
    _codeInactiveRef = FirebaseDatabase.instance
        .reference()
        .child(kRadioCodesRef)
        .child('Inactive');
    _codeInactiveRef.onChildAdded.listen(_onInactiveEntryAdded);
    _codeInactiveRef.onChildChanged.listen(_onInactiveEntryEdited);
    _codeInactiveRef.onChildRemoved.listen(_onInactiveEntryRemoved);
    _codeActiveRxRef = FirebaseDatabase.instance
        .reference()
        .child(kRadioCodesRef)
        .child('Active');
    _codeActiveRxRef.onChildAdded.listen(_onActiveRxEntryAdded);
    _codeActiveRxRef.onChildChanged.listen(_onActiveRxEntryEdited);
    _codeActiveRxRef.onChildRemoved.listen(_onActiveRxEntryRemoved);
    _codeActiveTxRef = FirebaseDatabase.instance
        .reference()
        .child(kRadioCodesRef)
        .child('ActiveTx');
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
                      onTap: () => _openEntryDialog(codeInactiveSaves[index]),
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
                      onTap: () => _openEntryDialog(codeActiveRxSaves[index]),
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
                      onTap: () => _openEntryDialog(codeActiveTxSaves[index]),
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
      codeInactiveSaves.add(
          new RadioCodeEntry.fromSnapshot(_codeInactiveRef, event.snapshot));
    });
  }

  _onInactiveEntryEdited(Event event) {
    print('_onInactiveEntryEdited');
    var oldValue = codeInactiveSaves
        .singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      codeInactiveSaves[codeInactiveSaves.indexOf(oldValue)] =
          new RadioCodeEntry.fromSnapshot(_codeInactiveRef, event.snapshot);
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
      codeActiveRxSaves.add(
          new RadioCodeEntry.fromSnapshot(_codeActiveRxRef, event.snapshot));
    });
  }

  _onActiveRxEntryEdited(Event event) {
    print('_onActiveRxEntryEdited');
    var oldValue = codeActiveRxSaves
        .singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      codeActiveRxSaves[codeActiveRxSaves.indexOf(oldValue)] =
          new RadioCodeEntry.fromSnapshot(_codeActiveRxRef, event.snapshot);
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
      codeActiveTxSaves.add(
          new RadioCodeEntry.fromSnapshot(_codeActiveTxRef, event.snapshot));
    });
  }

  _onActiveTxEntryEdited(Event event) {
    print('_onActiveTxEntryEdited');
    var oldValue = codeActiveTxSaves
        .singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      codeActiveTxSaves[codeActiveTxSaves.indexOf(oldValue)] =
          new RadioCodeEntry.fromSnapshot(_codeActiveTxRef, event.snapshot);
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

  void _openEntryDialog(RadioCodeEntry entry) {
    showDialog(
      context: context,
      child: new EntryDialog(
        entry: entry,
        codeInactiveRef: _codeInactiveRef,
        codeActiveRxRef: _codeActiveRxRef,
        codeActiveTxRef: _codeActiveTxRef,
      ),
    );
  }

  void _onFloatingActionButtonPressed() {
    // request update to node
    // _controlRef.child('radio_update').set(true);
    // DateTime now = new DateTime.now();
    // _controlRef.child('time').set(now.millisecondsSinceEpoch ~/ 1000);
  }
}

class EntryDialog extends StatefulWidget {
  final RadioCodeEntry entry;
  final DatabaseReference codeInactiveRef;
  final DatabaseReference codeActiveRxRef;
  final DatabaseReference codeActiveTxRef;

  EntryDialog({
    this.entry,
    this.codeInactiveRef,
    this.codeActiveRxRef,
    this.codeActiveTxRef,
  });

  @override
  _EntryDialogState createState() => new _EntryDialogState(
        entry: entry,
        codeInactiveRef: codeInactiveRef,
        codeActiveRxRef: codeActiveRxRef,
        codeActiveTxRef: codeActiveTxRef,
      );
}

class _EntryDialogState extends State<EntryDialog> {
  final TextEditingController _controllerName = new TextEditingController();
  final RadioCodeEntry entry;
  final DatabaseReference codeInactiveRef;
  final DatabaseReference codeActiveRxRef;
  final DatabaseReference codeActiveTxRef;
  DatabaseReference _functionRef;
  List<FunctionEntry> _functionSaves = new List();

  String _selectType;
  String _selectFunction;
  List<String> radioMenu = new List();
  Map<String, DatabaseReference> _menuRef = new Map();

  _EntryDialogState({
    this.entry,
    this.codeInactiveRef,
    this.codeActiveRxRef,
    this.codeActiveTxRef,
  }) {
    print('EntryDialogState');
    _functionRef = FirebaseDatabase.instance.reference().child(kFunctionsRef);
    _functionRef.onChildAdded.listen(_onFunctionAdded);
    _controllerName.text = entry.name;
    _menuRef['Inactive'] = codeInactiveRef;
    _menuRef['Active Rx'] = codeActiveRxRef;
    _menuRef['Active Tx'] = codeActiveTxRef;
    _menuRef.forEach((String key, DatabaseReference value) {
      radioMenu.add(key);
    });
  }

  @override
  Widget build(BuildContext context) {
    return new AlertDialog(
        title: new Text('Edit Radio Code'),
        content: new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              new TextField(
                controller: _controllerName,
                decoration: new InputDecoration(
                  hintText: 'Name',
                ),
              ),
              new ListTile(
                title: const Text('Radio Type'),
                trailing: new DropdownButton<String>(
                  hint: const Text('Select Type'),
                  value: _selectType,
                  onChanged: (String newValue) {
                    print(newValue);
                    setState(() {
                      _selectType = newValue;
                    });
                  },
                  items: radioMenu.map((String entry) {
                    return new DropdownMenuItem<String>(
                      value: entry,
                      child: new Text(entry),
                    );
                  }).toList(),
                ),
              ),
              new ListTile(
                title: const Text('Function Call'),
                trailing: new DropdownButton<String>(
                  hint: const Text('select function'),
                  value: _selectFunction,
                  onChanged: (String newValue) {
                    print(newValue);
                    setState(() {
                      _selectFunction = newValue;
                    });
                  },
                  items: _functionSaves.map((FunctionEntry entry) {
                    return new DropdownMenuItem<String>(
                      value: entry.name,
                      child: new Text(entry.name),
                    );
                  }).toList(),
                ),
              ),
            ]),
        actions: <Widget>[
          new FlatButton(
              child: const Text('REMOVE'),
              onPressed: () {
                entry.reference.child(entry.key).remove();
                Navigator.pop(context, null);
              }),
          new FlatButton(
              child: const Text('SAVE'),
              onPressed: () {
                entry.reference.child(entry.key).remove();
                entry.reference = _menuRef[_selectType];
                entry.name = _controllerName.text;
                entry.func = _selectFunction;
                entry.reference.push().set(entry.toJson());
                Navigator.pop(context, null);
              }),
          new FlatButton(
              child: const Text('DISCARD'),
              onPressed: () {
                Navigator.pop(context, null);
              }),
        ]);
  }

  _onFunctionAdded(Event event) {
    print('_onFunctionAdded');
    setState(() {
      _functionSaves.add(new FunctionEntry.fromSnapshot(_functionRef, event.snapshot));
    });
  }
}
