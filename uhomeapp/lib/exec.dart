import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'entries.dart';
import 'firebase_utils.dart';
import 'exec_prog.dart';

class ExecListItem extends StatelessWidget {
  final ExecEntry entry;

  ExecListItem(this.entry);

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
                      '${entry.name}',
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                    ),
                    new Text(
                      'a',
                      textScaleFactor: 0.8,
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    new Text(
                      'b',
                      textScaleFactor: 0.9,
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

class Exec extends StatefulWidget {
  Exec({Key key, this.title}) : super(key: key);

  static const String routeName = '/exec';

  final String title;

  @override
  _ExecState createState() => new _ExecState();
}

class _ExecState extends State<Exec> {
  List<ExecEntry> entryList = new List();
  DatabaseReference _entryRef;
  StreamSubscription<Event> _onAddSubscription;
  StreamSubscription<Event> _onEditSubscription;
  StreamSubscription<Event> _onRemoveSubscription;

  _ExecState() {
    _entryRef = FirebaseDatabase.instance.reference().child(getExecRef());
    _onAddSubscription = _entryRef.onChildAdded.listen(_onEntryAdded);
    _onEditSubscription = _entryRef.onChildChanged.listen(_onEntryEdited);
    _onRemoveSubscription = _entryRef.onChildRemoved.listen(_onEntryRemoved);
  }

  @override
  void initState() {
    super.initState();
    print('_ExecState');
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
              child: new ExecListItem(entryList[index]));
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
      entryList.add(new ExecEntry.fromSnapshot(_entryRef, event.snapshot));
    });
  }

  void _onEntryEdited(Event event) {
    ExecEntry oldValue =
        entryList.singleWhere((el) => el.key == event.snapshot.key);
    setState(() {
      entryList[entryList.indexOf(oldValue)] =
          new ExecEntry.fromSnapshot(_entryRef, event.snapshot);
    });
  }

  void _onEntryRemoved(Event event) {
    ExecEntry oldValue =
        entryList.singleWhere((el) => el.key == event.snapshot.key);
    setState(() {
      entryList.remove(oldValue);
    });
  }

  void _openEntryDialog(ExecEntry entry) {
    showDialog(
      context: context,
      child: new EntryDialog(entry, entryList),
    );
  }

  void _onFloatingActionButtonPressed() {
    ExecEntry entry = new ExecEntry(_entryRef);
    _openEntryDialog(entry);
  }
}

class EntryDialog extends StatefulWidget {
  final ExecEntry entry;
  final List<ExecEntry> execList;

  EntryDialog(this.entry, this.execList);

  @override
  _EntryDialogState createState() => new _EntryDialogState(entry, execList);
}

class _EntryDialogState extends State<EntryDialog> {
  final TextEditingController _controllerName = new TextEditingController();
  final ExecEntry entry;
  List<ExecEntry> execList;

  ExecEntry _selectedNext;
  var _selectedNextList;

  List<IoEntry> entryIoList = new List();
  StreamSubscription<Event> _onAddSubscription;

  _EntryDialogState(this.entry, this.execList) {
    print('EntryDialogState');

    _controllerName.text = entry?.name;
    if (entry.cb != null) {
      _selectedNextList = execList.where((el) => el.key == entry.cb);
      if (_selectedNextList.length == 1) {
        _selectedNext = execList.singleWhere((el) => el.key == entry.cb);
      } else {
        entry.cb = null;
      }
    }
  }

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
        title: new Text('Edit a Function'),
        content: new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              new ListTile(
                title: new TextField(
                  controller: _controllerName,
                  decoration: new InputDecoration(
                    hintText: 'Name',
                  ),
                ),
                trailing: new ButtonTheme.bar(
                  child: new ButtonBar(
                    children: <Widget>[
                      new FlatButton(
                        child: const Text('PROGRAM'),
                        onPressed: () {
                          /*Navigator.of(context)
                            ..pop()
                            ..pushNamed(ExecProg.routeName);*/
                          Navigator.of(context).pop();
                          Navigator.push(
                              context,
                              new MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    new ExecProg(p: entry.p),
                              ));
                        },
                      ),
                    ],
                  ),
                ),
              ),
              (execList.length > 0)
                  ? new ListTile(
                      title: const Text('Next Exec'),
                      trailing: new DropdownButton<ExecEntry>(
                        hint: const Text('Select an Exec'),
                        value: _selectedNext,
                        onChanged: (ExecEntry newValue) {
                          setState(() {
                            _selectedNext = newValue;
                          });
                        },
                        items: execList.map((ExecEntry entry) {
                          return new DropdownMenuItem<ExecEntry>(
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
                  entry.name = _controllerName.text;
                  entry.cb = _selectedNext?.key;
                  if (entry.key != null) {
                    entry.reference.child(entry.key).update(entry.toJson());
                  } else {
                    entry.setOwner(getNodeSubPath());
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
}
