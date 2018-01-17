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
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                    ),
                    new Text(
                      'TYPE: ${kEntryId2Name[DataCode.values[entry.code]]}',
                      textScaleFactor: 0.8,
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    new Text(
                      'VALUE: ${entry.getValue()}',
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

class DataIO extends StatefulWidget {
  DataIO({Key key, this.title}) : super(key: key);

  static const String routeName = '/data_io';

  final String title;

  @override
  _DataIOState createState() => new _DataIOState();
}

class _DataIOState extends State<DataIO> {
  List<IoEntry> entryList = new List();
  DatabaseReference _dataRef;
  StreamSubscription<Event> _onAddSubscription;
  StreamSubscription<Event> _onEditSubscription;
  StreamSubscription<Event> _onRemoveSubscription;

  _DataIOState() {
    _dataRef = FirebaseDatabase.instance.reference().child(getDataRef());
    _onAddSubscription = _dataRef.onChildAdded.listen(_onEntryAdded);
    _onEditSubscription = _dataRef.onChildChanged.listen(_onEntryEdited);
    _onRemoveSubscription = _dataRef.onChildRemoved.listen(_onEntryRemoved);
  }

  @override
  void initState() {
    super.initState();
    print('_DigitalIOState');
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
    setState(() {
      IoEntry entry = new IoEntry.fromSnapshot(_dataRef, event.snapshot);
      print(entry.name);
      print(entry.cb);
      entryList.add(entry);
    });
  }

  void _onEntryEdited(Event event) {
    IoEntry oldValue =
        entryList.singleWhere((el) => el.key == event.snapshot.key);
    setState(() {
      entryList[entryList.indexOf(oldValue)] =
          new IoEntry.fromSnapshot(_dataRef, event.snapshot);
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
    final IoEntry entry = new IoEntry(_dataRef);
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
  final DatabaseReference _execRef =
      FirebaseDatabase.instance.reference().child(getExecRef());
  List<ExecEntry> _execList = new List();

  final TextEditingController _controllerName = new TextEditingController();
  final TextEditingController _controllerType = new TextEditingController();
  final TextEditingController _controllerPin = new TextEditingController();
  final TextEditingController _controllerValue = new TextEditingController();
  ExecEntry _selectedExec;
  StreamSubscription<Event> _onExecAddSub;

  _EntryDialogState(this.entry) {
    _onExecAddSub = _execRef.onChildAdded.listen(_onExecAdded);
    if (entry.value != null) {
      _controllerName.text = entry.name;
      _controllerType.text = entry.code.toString();
      _controllerPin.text = entry.getPin().toString();
      _controllerValue.text = entry.getValue().toString();
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _onExecAddSub.cancel();
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
                controller: _controllerType,
                decoration: new InputDecoration(
                  hintText: 'type',
                ),
              ),
              new TextField(
                controller: _controllerPin,
                decoration: new InputDecoration(
                  hintText: 'pin',
                ),
              ),
              new TextField(
                controller: _controllerValue,
                decoration: new InputDecoration(
                  hintText: 'value',
                ),
              ),
              (_execList.length > 0)
                  ? new ListTile(
                      title: const Text('Exec Call'),
                      trailing: new DropdownButton<ExecEntry>(
                        hint: const Text('select an exec'),
                        value: _selectedExec,
                        onChanged: (ExecEntry newValue) {
                          setState(() {
                            _selectedExec = newValue;
                          });
                        },
                        items: _execList.map((ExecEntry entry) {
                          return new DropdownMenuItem<ExecEntry>(
                            value: entry,
                            child: new Text(entry.name),
                          );
                        }).toList(),
                      ),
                    )
                  : new Text('Exec not declared yet'),
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
                  entry.code = DataCode.PhyOut.index;
                  entry.setPin(int.parse(_controllerPin.text));
                  entry.setValue(int.parse(_controllerValue.text));
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

  void _onExecAdded(Event event) {
    ExecEntry execEntry = new ExecEntry.fromSnapshot(_execRef, event.snapshot);
    setState(() {
      _execList.add(execEntry);
      if (entry.cb == execEntry.key) {
        _selectedExec = execEntry;
      }
    });
  }
}
