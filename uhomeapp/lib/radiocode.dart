import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'entries.dart';
import 'firebase_utils.dart';

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
                    /* new Text(
                      'Function: ${entry.func}',
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
                    ),*/
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
      FirebaseDatabase.instance.reference().child(getControlRef());

  List<IoEntry> entryList = new List();
  DatabaseReference _graphRef;
  List<IoEntry> destinationSaves;
  String selection;
  StreamSubscription<Event> _onEditSub;
  StreamSubscription<Event> _onRemoveSub;

  _RadioCodeState() {
    _graphRef = FirebaseDatabase.instance.reference().child(getGraphRef());
    _onEditSub = _graphRef.onChildChanged.listen(_onEntryEdited);
    _onRemoveSub = _graphRef.onChildRemoved.listen(_onEntryRemoved);
  }

  @override
  void initState() {
    super.initState();
    print('_RadioCodeState');
  }

  @override
  void dispose() {
    super.dispose();
    _onEditSub.cancel();
    _onRemoveSub.cancel();
  }

  @override
  Widget build(BuildContext context) {
    var inactiveList =
        entryList.where((el) => (el.type == kRadioElem)).toList();
    var activeRxList = entryList.where((el) => (el.type == kRadioIn)).toList();
    var activeTxList = entryList.where((el) => (el.type == kRadioOut)).toList();
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
                itemCount: inactiveList.length,
                itemBuilder: (buildContext, index) {
                  return new InkWell(
                      onTap: () => _openEntryDialog(inactiveList[index]),
                      child: new RadioCodeListItem(inactiveList[index]));
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
                itemCount: activeRxList.length,
                itemBuilder: (buildContext, index) {
                  return new InkWell(
                      onTap: () => _openEntryDialog(activeRxList[index]),
                      child: new RadioCodeListItem(activeRxList[index]));
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
                itemCount: activeTxList.length,
                itemBuilder: (buildContext, index) {
                  return new InkWell(
                      onTap: () => _openEntryDialog(activeTxList[index]),
                      child: new RadioCodeListItem(activeTxList[index]));
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
      entryList.add(new IoEntry.fromSnapshot(_graphRef, event.snapshot));
    });
  }

  void _onEntryEdited(Event event) {
    IoEntry oldValue =
        entryList.singleWhere((el) => el.key == event.snapshot.key);
    setState(() {
      entryList[entryList.indexOf(oldValue)] =
          new IoEntry.fromSnapshot(_graphRef, event.snapshot);
    });
  }

  void _onEntryRemoved(Event event) {
    IoEntry oldValue =
        entryList.singleWhere((el) => el.key == event.snapshot.key);
    setState(() {
      entryList.remove(oldValue);
    });
  }

  void _openEntryDialog(IoEntry entry) {
    showDialog(
      context: context,
      child: new EntryDialog(entry),
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

  EntryDialog(this.entry);

  @override
  _EntryDialogState createState() => new _EntryDialogState(
        entry: entry,
      );
}

class _EntryDialogState extends State<EntryDialog> {
  final TextEditingController _controllerName = new TextEditingController();
  final IoEntry entry;
  final DatabaseReference _graphRef =
      FirebaseDatabase.instance.reference().child(getGraphRef());
  final DatabaseReference _functionRef =
      FirebaseDatabase.instance.reference().child(getFunctionsRef());
  List<FunctionEntry> _functionList = new List();

  int _selectedType;
  FunctionEntry _selectedFunction;
  List<String> radioMenu = new List();
  StreamSubscription<Event> _onFunctionAddSub;

  _EntryDialogState({
    this.entry,
  }) {
    print('EntryDialogState');
    _onFunctionAddSub = _functionRef.onChildAdded.listen(_onFunctionAdded);
    _controllerName.text = entry.name;
    _selectedType = entry.type;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _onFunctionAddSub.cancel();
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
                  hint: const Text('select a type'),
                  value: kEntryId2Name[_selectedType],
                  onChanged: (String newValue) {
                    print(newValue);
                    setState(() {
                      _selectedType = kEntryName2Id[newValue];
                    });
                  },
                  items: <String>[
                    kEntryId2Name[kRadioIn],
                    kEntryId2Name[kRadioOut],
                    kEntryId2Name[kRadioElem]
                  ].map((String entry) {
                    return new DropdownMenuItem<String>(
                      value: entry,
                      child: new Text(entry),
                    );
                  }).toList(),
                ),
              ),
              (_functionList.length > 0)
                  ? new ListTile(
                      title: const Text('Function Call'),
                      trailing: new DropdownButton<FunctionEntry>(
                        hint: const Text('select a function'),
                        value: _selectedFunction,
                        onChanged: (FunctionEntry newValue) {
                          print(newValue.name);
                          setState(() {
                            _selectedFunction = newValue;
                          });
                        },
                        items: _functionList.map((FunctionEntry entry) {
                          return new DropdownMenuItem<FunctionEntry>(
                            value: entry,
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
                entry.reference = _graphRef;
                entry.name = _controllerName.text;
                var prevType = entry.type;
                entry.type = _selectedType;
                if (_selectedFunction != null) {
                  entry.func = _selectedFunction.key;
                }
                if (entry.key != null) {
                  if (prevType == kRadioElem) {
                    entry.reference.child(entry.key).remove();
                    entry.reference.push().set(entry.toJson());
                  } else {
                    entry.reference.child(entry.key).update(entry.toJson());
                  }
                } else {
                  entry.reference.push().set(entry.toJson());
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

  void _onFunctionAdded(Event event) {
    FunctionEntry funcEntry =
        new FunctionEntry.fromSnapshot(_functionRef, event.snapshot);
    setState(() {
      _functionList.add(funcEntry);
      if (entry.func == funcEntry.key) {
        _selectedFunction = funcEntry;
      }
    });
  }
}
