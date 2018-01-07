import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'entries.dart';
import 'firebase_utils.dart';

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
                new Column(
                  children: [
                    new Text(
                      entry.name,
                      textScaleFactor: 1.3,
                      textAlign: TextAlign.left,
                    ),
                    new Text(
                      'Hour: ${entry.getPort()}',
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    new Text(
                      'Minute: ${entry.getValue()}',
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    new Text(
                      'ID: ${entry.value}',
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

class Timer extends StatefulWidget {
  Timer({Key key, this.title}) : super(key: key);

  static const String routeName = '/timer';

  final String title;

  @override
  _TimerState createState() => new _TimerState();
}

class _TimerState extends State<Timer> {
  List<IoEntry> entryList = new List();
  DatabaseReference _graphRef;
  StreamSubscription<Event> _onAddSubscription;
  StreamSubscription<Event> _onEditSubscription;
  StreamSubscription<Event> _onRemoveSubscription;

  _TimerState() {
    _graphRef = FirebaseDatabase.instance.reference().child(dGraphRef);
    _onAddSubscription = _graphRef.onChildAdded.listen(_onEntryAdded);
    _onEditSubscription = _graphRef.onChildChanged.listen(_onEntryEdited);
    _onRemoveSubscription = _graphRef.onChildRemoved.listen(_onEntryRemoved);
  }

  @override
  void initState() {
    super.initState();
    print('_TimerState');
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
    // var query = entryList.where((el) => (el.type == kTimer)).toList();
    var query = entryList;
    return new Scaffold(
      drawer: drawer,
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new ListView.builder(
        shrinkWrap: true,
        reverse: true,
        itemCount: query.length,
        itemBuilder: (buildContext, index) {
          return new InkWell(
              onTap: () => _openEntryDialog(query[index]),
              child: new ListItem(query[index]));
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
    var snap = event.snapshot;
    if (snap.value['code'] == kTimer) {
      setState(() {
        entryList.add(new IoEntry.fromSnapshot(_graphRef, snap));
      });
    }
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
    final IoEntry entry = new IoEntry(_graphRef);
    _openEntryDialog(entry);
  }
}

class EntryDialog extends StatefulWidget {
  final IoEntry entry;

  EntryDialog(this.entry);

  @override
  _EntryDialogState createState() => new _EntryDialogState(entry);
}

class _EntryDialogState extends State<EntryDialog> {
  final IoEntry entry;
  final DatabaseReference _functionRef =
      FirebaseDatabase.instance.reference().child(getFunctionsRef());
  List<FunctionEntry> _functionList = new List();

  final TextEditingController _controllerName = new TextEditingController();
  final TextEditingController _controllerHours = new TextEditingController();
  final TextEditingController _controllerMinutes = new TextEditingController();
  FunctionEntry _selectedFunction;
  StreamSubscription<Event> _onFunctionAddSub;

  _EntryDialogState(this.entry) {
    _onFunctionAddSub = _functionRef.onChildAdded.listen(_onFunctionAdded);
    if (entry.value != null) {
      _controllerName.text = entry.name;
      _controllerHours.text = entry.getPort().toString();
      _controllerMinutes.text = entry.getValue().toString();
    }
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
        title: new Text('Edit Entry'),
        content: new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new TextField(
                controller: _controllerName,
                decoration: new InputDecoration(
                  hintText: 'name',
                ),
              ),
              new TextField(
                controller: _controllerHours,
                decoration: new InputDecoration(
                  hintText: 'hour',
                ),
              ),
              new TextField(
                controller: _controllerMinutes,
                decoration: new InputDecoration(
                  hintText: 'minute',
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
                if (entry.key != null) {
                  entry.reference.child(entry.key).remove();
                }
                Navigator.pop(context, null);
              }),
          new FlatButton(
              child: const Text('SAVE'),
              onPressed: () {
                entry.name = _controllerName.text;
                try {
                  entry.code = kTimer;
                  entry.setPort(int.parse(_controllerHours.text));
                  entry.setValue(int.parse(_controllerMinutes.text));
                  if (_selectedFunction != null) {
                    entry.cb = _selectedFunction.key;
                  }
                  if (entry.key != null) {
                    entry.reference.child(entry.key).update(entry.toJson());
                  } else {
                    entry.setOwner(getNodeSubPath());
                    entry.reference.push().set(entry.toJson());
                  }
                } catch (exception, stackTrace) {}
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
      if (entry.cb == funcEntry.key) {
        _selectedFunction = funcEntry;
      }
    });
  }
}
