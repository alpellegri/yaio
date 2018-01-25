import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'entries.dart';
import 'firebase_utils.dart';

class ProgListItem extends StatelessWidget {
  final ExecEntry entry;

  ProgListItem(this.entry);

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

class ExecProg extends StatefulWidget {
  ExecProg({Key key, this.title}) : super(key: key);

  static const String routeName = '/exec';

  final String title;

  @override
  _ExecProgState createState() => new _ExecProgState();
}

class _ExecProgState extends State<ExecProg> {
  List<ExecEntry> entryList = new List();
  _ExecProgState() {}

  @override
  void initState() {
    super.initState();
    print('_ExecProgState');
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
      body: new ListView.builder(
        shrinkWrap: true,
        reverse: true,
        itemCount: entryList.length,
        itemBuilder: (buildContext, index) {
          return new InkWell(
              onTap: () => _openEntryDialog(entryList[index]),
              child: new ProgListItem(entryList[index]));
        },
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _onFloatingActionButtonPressed,
        tooltip: 'add',
        child: new Icon(Icons.add),
      ),
    );
  }

  void _openEntryDialog(ExecEntry entry) {
    showDialog(
      context: context,
      child: new EntryDialog(entry, entryList),
    );
  }

  void _onFloatingActionButtonPressed() {
    // _openEntryDialog(entry);
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
  DatabaseReference _dataRef;
  StreamSubscription<Event> _onAddSubscription;

  _EntryDialogState(this.entry, this.execList) {
    print('EntryDialogState');
    _dataRef = FirebaseDatabase.instance.reference().child(getDataRef());
    _onAddSubscription = _dataRef.onChildAdded.listen(_onDataEntryAdded);

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

  void _onDataEntryAdded(Event event) {
    print('_onDataEntryAdded');
    IoEntry ioEntry = new IoEntry.fromSnapshot(_dataRef, event.snapshot);
    setState(() {
      entryIoList.add(ioEntry);
    });
  }
}
