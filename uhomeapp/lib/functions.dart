import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'entries.dart';
import 'firebase_utils.dart';

class FunctionListItem extends StatelessWidget {
  final FunctionEntry entry;

  FunctionListItem(this.entry);

  @override
  Widget build(BuildContext context) {
    FunctionEntry next;
    IoEntry action;
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
                      '${entry.name}',
                      textScaleFactor: 1.5,
                      textAlign: TextAlign.left,
                    ),
                    /*
                    new Text(
                      'action name: ${entry.actionName}',
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    new Text(
                      'type ID: ${entry.idType}',
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
                    ),*/
                    new Text(
                      'delay: ${entry.delay.toString()}',
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    new Text(
                      'next: ${entry.next}',
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

class Functions extends StatefulWidget {
  Functions({Key key, this.title}) : super(key: key);

  static const String routeName = '/functions';

  final String title;

  @override
  _FunctionsState createState() => new _FunctionsState();
}

class _FunctionsState extends State<Functions> {
  final DatabaseReference _controlRef =
      FirebaseDatabase.instance.reference().child(getControlRef());

  List<FunctionEntry> entryList = new List();
  DatabaseReference _entryRef;
  StreamSubscription<Event> _onAddSubscription;
  StreamSubscription<Event> _onEditSubscription;
  StreamSubscription<Event> _onRemoveSubscription;

  _FunctionsState() {
    _entryRef = FirebaseDatabase.instance.reference().child(getFunctionsRef());
    _onAddSubscription = _entryRef.onChildAdded.listen(_onEntryAdded);
    _onEditSubscription = _entryRef.onChildChanged.listen(_onEntryEdited);
    _onRemoveSubscription = _entryRef.onChildRemoved.listen(_onEntryRemoved);
  }

  @override
  void initState() {
    super.initState();
    print('_FunctionsState');
  }

  @override
  void dispose() {
    super.dispose();
    _onAddSubscription.cancel();
    _onEditSubscription.cancel();
    _onRemoveSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      drawer: drawer,
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new ListView.builder(
        shrinkWrap: true,
        reverse: true,
        itemCount: entryList.length,
        itemBuilder: (buildContext, index) {
          return new InkWell(
              onTap: () => _openEntryDialog(entryList[index]),
              child: new FunctionListItem(entryList[index]));
        },
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _onFloatingActionButtonPressed,
        tooltip: 'add',
        child: new Icon(Icons.add),
      ),
    );
  }

  void _onEntryAdded(Event event) {
    setState(() {
      entryList.add(new FunctionEntry.fromSnapshot(_entryRef, event.snapshot));
    });
  }

  void _onEntryEdited(Event event) {
    FunctionEntry oldValue =
        entryList.singleWhere((el) => el.key == event.snapshot.key);
    setState(() {
      entryList[entryList.indexOf(oldValue)] =
          new FunctionEntry.fromSnapshot(_entryRef, event.snapshot);
    });
  }

  void _onEntryRemoved(Event event) {
    FunctionEntry oldValue =
        entryList.singleWhere((el) => el.key == event.snapshot.key);
    setState(() {
      entryList.remove(oldValue);
    });
  }

  void _openEntryDialog(FunctionEntry entry) {
    showDialog(
      context: context,
      child: new EntryDialog(entry, entryList),
    );
  }

  void _onFloatingActionButtonPressed() {
    FunctionEntry entry = new FunctionEntry(_entryRef);
    _openEntryDialog(entry);
  }
}

class EntryDialog extends StatefulWidget {
  final FunctionEntry entry;
  final List<FunctionEntry> functionList;

  EntryDialog(this.entry, this.functionList);

  @override
  _EntryDialogState createState() => new _EntryDialogState(entry, functionList);
}

class _EntryDialogState extends State<EntryDialog> {
  final TextEditingController _controllerName = new TextEditingController();
  final TextEditingController _controllerDelay = new TextEditingController();
  final FunctionEntry entry;
  List<FunctionEntry> functionList;

  int _selectedType;
  FunctionEntry _selectedNext;
  List<String> selectTypeMenu = new List();
  Map<int, List> _selectedList = new Map();
  List<IoEntry> _ioMenu = new List();
  IoEntry _selectedEntry;

  List<IoEntry> entryIoList = new List();
  DatabaseReference _graphRef;
  StreamSubscription<Event> _onAddSubscription;

  _EntryDialogState(this.entry, this.functionList) {
    print('EntryDialogState');
    _graphRef = FirebaseDatabase.instance.reference().child(getGraphRef());
    _onAddSubscription = _graphRef.onChildAdded.listen(_onGraphEntryAdded);

    selectTypeMenu.add(kEntryId2Name[kDOut]);
    selectTypeMenu.add(kEntryId2Name[kLOut]);
    selectTypeMenu.add(kEntryId2Name[kRadioOut]);

    _controllerName.text = entry?.name;
    if (entry.delay != null) {
      _controllerDelay.text = entry.delay.toString();
    } else {
      // _controllerDelay.text = '0';
    }
    if (entry.next != null) {
      _selectedNext = functionList.singleWhere((el) => el.key == entry.next);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _onAddSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return new AlertDialog(
        title: new Text('Edit a Function'),
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
                title: const Text('Action Type'),
                trailing: new DropdownButton<String>(
                  hint: const Text('type'),
                  value: kEntryId2Name[_selectedType],
                  onChanged: (String newValue) {
                    setState(() {
                      _selectedType = kEntryName2Id[newValue];
                      _ioMenu = entryIoList
                          .where((el) => el.type == _selectedType)
                          .toList();
                      _ioMenu.forEach((e) => print(e.name));
                      _selectedEntry = null;
                    });
                  },
                  items: selectTypeMenu.map((String entry) {
                    return new DropdownMenuItem<String>(
                      value: entry,
                      child: new Text(entry),
                    );
                  }).toList(),
                ),
              ),
              ((_ioMenu != null) && (_ioMenu.length > 0))
                  ? new ListTile(
                      title: const Text('Action'),
                      trailing: new DropdownButton<IoEntry>(
                        hint: const Text('action'),
                        value: _selectedEntry,
                        onChanged: (IoEntry newValue) {
                          setState(() {
                            _selectedEntry = newValue;
                          });
                        },
                        items: _ioMenu.map((IoEntry entry) {
                          return new DropdownMenuItem<IoEntry>(
                            value: entry,
                            child: new Text(entry.name),
                          );
                        }).toList(),
                      ),
                    )
                  : new Text('Actions not declared yet'),
              new TextField(
                controller: _controllerDelay,
                decoration: new InputDecoration(
                  hintText: 'delay',
                ),
              ),
              (functionList.length > 0)
                  ? new ListTile(
                      title: const Text('Next Function'),
                      trailing: new DropdownButton<FunctionEntry>(
                        hint: const Text('Select a Function'),
                        value: _selectedNext,
                        onChanged: (FunctionEntry newValue) {
                          setState(() {
                            _selectedNext = newValue;
                          });
                        },
                        items: functionList.map((FunctionEntry entry) {
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
                setState(() {
                  if (_controllerDelay.text != null) {
                    entry.delay = int.parse(_controllerDelay.text);
                  } else {
                    entry.delay = 0;
                  }
                  entry.name = _controllerName.text;
                  entry.next = _selectedNext?.key;
                  entry.action = _selectedEntry?.key;
                  if (entry.key != null) {
                    entry.reference.child(entry.key).update(entry.toJson());
                  } else {
                    entry.reference.push().set(entry.toJson());
                  }
                });
                Navigator.pop(context, null);
              }),
          new FlatButton(
              child: const Text('DISCARD'),
              onPressed: () {
                Navigator.pop(context, null);
              }),
        ]);
  }

  void _onGraphEntryAdded(Event event) {
    print('_onGraphEntryAdded');
    IoEntry ioEntry = new IoEntry.fromSnapshot(_graphRef, event.snapshot);
    setState(() {
      entryIoList.add(ioEntry);
      if (entry.action == ioEntry.key) {
        _selectedEntry = ioEntry;
        _selectedType = ioEntry.type;
        _ioMenu = entryIoList.where((el) => el.type == _selectedType).toList();
      }
    });
  }
}
