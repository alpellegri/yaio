import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'entries.dart';
import 'const.dart';

class RadioCodeListItem extends StatelessWidget {
  final IoEntry entry;

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

  List<IoEntry> inactiveSaves = new List();
  List<IoEntry> activeRxSaves = new List();
  List<IoEntry> activeTxSaves = new List();
  DatabaseReference _graphRef;
  List<IoEntry> destinationSaves;
  String selection;

  _RadioCodeState() {
    _graphRef = FirebaseDatabase.instance.reference().child(kGraphRef);
    _graphRef.onChildAdded.listen(_onEntryAdded);
    _graphRef.onChildChanged.listen(_onEntryEdited);
    _graphRef.onChildRemoved.listen(_onEntryRemoved);
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
                itemCount: inactiveSaves.length,
                itemBuilder: (buildContext, index) {
                  return new InkWell(
                      onTap: () => _openEntryDialog(inactiveSaves[index]),
                      child: new RadioCodeListItem(inactiveSaves[index]));
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
                itemCount: activeRxSaves.length,
                itemBuilder: (buildContext, index) {
                  return new InkWell(
                      onTap: () => _openEntryDialog(activeRxSaves[index]),
                      child: new RadioCodeListItem(activeRxSaves[index]));
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
                itemCount: activeTxSaves.length,
                itemBuilder: (buildContext, index) {
                  return new InkWell(
                      onTap: () => _openEntryDialog(activeTxSaves[index]),
                      child: new RadioCodeListItem(activeTxSaves[index]));
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

  void _onEntryAdded(Event event) {
    setState(() {
      inactiveSaves.add(new IoEntry.fromSnapshot(_graphRef, event.snapshot));
    });
  }

  void _onEntryEdited(Event event) {
    IoEntry oldValue =
        inactiveSaves.singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      inactiveSaves[inactiveSaves.indexOf(oldValue)] =
          new IoEntry.fromSnapshot(_graphRef, event.snapshot);
    });
  }

  void _onEntryRemoved(Event event) {
    IoEntry oldValue =
        inactiveSaves.singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      inactiveSaves.remove(oldValue);
    });
  }

  void _openEntryDialog(IoEntry entry) {
    showDialog(
      context: context,
      child: new EntryDialog(
        entry: entry,
      ),
    );
  }

  void _onFloatingActionButtonPressed() {
    // request update to node
    _controlRef.child('radio_update').set(true);
    DateTime now = new DateTime.now();
    _controlRef.child('time').set(now.millisecondsSinceEpoch ~/ 1000);
  }
}

class EntryDialog extends StatefulWidget {
  final IoEntry entry;

  EntryDialog({
    this.entry,
  });

  @override
  _EntryDialogState createState() => new _EntryDialogState(
        entry: entry,
      );
}

class _EntryDialogState extends State<EntryDialog> {
  final TextEditingController _controllerName = new TextEditingController();
  final IoEntry entry;
  DatabaseReference _graphRef;
  DatabaseReference _functionRef;
  List<FunctionEntry> _functionSaves = new List();

  String _selectType;
  String _selectFunction;
  List<String> radioMenu = new List();
  Map<String, DatabaseReference> _menuRef = new Map();

  _EntryDialogState({
    this.entry,
  }) {
    print('EntryDialogState');
    _graphRef = FirebaseDatabase.instance.reference().child(kGraphRef);
    _functionRef = FirebaseDatabase.instance.reference().child(kFunctionsRef);
    _functionRef.onChildAdded.listen(_onFunctionAdded);
    _controllerName.text = entry.name;
    // _menuRef.forEach((String key, DatabaseReference value) {
    //   radioMenu.add(key);
    // });
  }

  bool notNull(Object o) => o != null;

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
                  hint: const Text('select a type'),
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
              (_functionSaves.length > 0)
                  ? new ListTile(
                      title: const Text('Function Call'),
                      trailing: new DropdownButton<String>(
                        hint: const Text('select a function'),
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
                    )
                  : new Text('Functions not declared yet'),
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
                if (entry.key != null) {
                  entry.reference.child(entry.key).remove();
                }
                entry.reference = _graphRef;
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

  void _onFunctionAdded(Event event) {
    setState(() {
      _functionSaves
          .add(new FunctionEntry.fromSnapshot(_functionRef, event.snapshot));
    });
  }
}
