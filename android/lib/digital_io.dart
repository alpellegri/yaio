import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'entries.dart';
import 'const.dart';

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
                      textScaleFactor: 1.5,
                      textAlign: TextAlign.left,
                    ),
                    new Text(
                      'PORT: ${entry.getPort()}',
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    new Text(
                      'VALUE: ${entry.getValue()}',
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    new Text(
                      'ID: ${entry.id.toRadixString(16)}',
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

class DigitalIO extends StatefulWidget {
  DigitalIO({Key key, this.title}) : super(key: key);

  static const String routeName = '/digital_io';

  final String title;

  @override
  _DigitalIOState createState() => new _DigitalIOState();
}

class _DigitalIOState extends State<DigitalIO> {
  List<IoEntry> entrySaves = new List();
  DatabaseReference _entryRef;

  _DigitalIOState() {
    _entryRef = FirebaseDatabase.instance.reference().child(kGraphRef);
    _entryRef.onChildAdded.listen(_onEntryAdded);
    _entryRef.onChildChanged.listen(_onEntryEdited);
    _entryRef.onChildRemoved.listen(_onEntryRemoved);
  }

  @override
  void initState() {
    super.initState();
    print('_DigitalIOState');
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var query = entrySaves.where((entry) => (entry.id == kDOut)).toList();
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
      entrySaves.add(new IoEntry.fromSnapshot(_entryRef, event.snapshot));
    });
  }

  void _onEntryEdited(Event event) {
    IoEntry oldValue =
        entrySaves.singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      entrySaves[entrySaves.indexOf(oldValue)] =
          new IoEntry.fromSnapshot(_entryRef, event.snapshot);
    });
  }

  void _onEntryRemoved(Event event) {
    IoEntry oldValue =
        entrySaves.singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      entrySaves.remove(oldValue);
    });
  }

  void _openEntryDialog(IoEntry entry) {
    showDialog(
      context: context,
      child: new EntryDialog(entry),
    );
  }

  void _onFloatingActionButtonPressed() {
    final IoEntry entry = new IoEntry(_entryRef);
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

  final TextEditingController _controllerName = new TextEditingController();
  final TextEditingController _controllerPort = new TextEditingController();
  final TextEditingController _controllerValue = new TextEditingController();

  _EntryDialogState(this.entry) {
    if (entry.id != null) {
      _controllerName.text = entry.name;
      _controllerPort.text = entry.getPort().toString();
      _controllerValue.text = entry.getValue().toString();
    }
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
                controller: _controllerPort,
                decoration: new InputDecoration(
                  hintText: 'port',
                ),
              ),
              new TextField(
                controller: _controllerValue,
                decoration: new InputDecoration(
                  hintText: 'value',
                ),
              ),
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
                  entry.type = kDOut;
                  entry.setPort(int.parse(_controllerPort.text));
                  entry.setValue(int.parse(_controllerValue.text));
                  if (entry.key != null) {
                    entry.reference.child(entry.key).remove();
                  }
                  entry.reference.push().set(entry.toJson());
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
}
