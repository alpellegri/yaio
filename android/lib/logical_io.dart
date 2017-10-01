import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';

class LoutEntry {
  String key;
  int id;
  String name;

  LoutEntry(this.id, this.name);

  LoutEntry.fromSnapshot(DataSnapshot snapshot)
      : key = snapshot.key,
        id = snapshot.value['id'],
        name = snapshot.value['name'];

  toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class LoutListItem extends StatelessWidget {
  final LoutEntry loutEntry;

  LoutListItem(this.loutEntry);

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
                      loutEntry.name,
                      textScaleFactor: 1.5,
                      textAlign: TextAlign.left,
                    ),
                    new Text(
                      'PIN: ${loutEntry.id}',
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

class LogicalIO extends StatefulWidget {
  LogicalIO({Key key, this.title}) : super(key: key);

  static const String routeName = '/logical_io';

  final String title;

  @override
  _LogicalIOState createState() => new _LogicalIOState();
}

class _LogicalIOState extends State<LogicalIO> {
  List<LoutEntry> loutSaves = new List();
  DatabaseReference _loutRef;

  _LogicalIOState() {
    _loutRef =
        FirebaseDatabase.instance.reference().child('LIO').child('Lout');
    _loutRef.onChildAdded.listen(_onLoutEntryAdded);
    _loutRef.onChildChanged.listen(_onLoutEntryEdited);
    _loutRef.onChildRemoved.listen(_onLoutEntryRemoved);
  }

  @override
  void initState() {
    super.initState();
    print('_LogicalIOState');
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
        itemCount: loutSaves.length,
        itemBuilder: (buildContext, index) {
          return new InkWell(
              onTap: () => _openRemoveEntryDialog(loutSaves[index]),
              child: new LoutListItem(loutSaves[index]));
        },
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _openAddEntryDialog,
        tooltip: 'add',
        child: new Icon(Icons.add),
      ),
    );
  }

  _onLoutEntryAdded(Event event) {
    print('_onLoutEntryAdded');
    setState(() {
      loutSaves.add(new LoutEntry.fromSnapshot(event.snapshot));
    });
  }

  _onLoutEntryEdited(Event event) {
    print('_onLoutEntryEdited');
    var oldValue =
        loutSaves.singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      loutSaves[loutSaves.indexOf(oldValue)] =
          new LoutEntry.fromSnapshot(event.snapshot);
    });
  }

  _onLoutEntryRemoved(Event event) {
    print('_onLoutEntryRemoved');
    var oldValue =
        loutSaves.singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      loutSaves.remove(oldValue);
    });
  }

  void _openAddEntryDialog() {
    final TextEditingController _controllerName = new TextEditingController();
    final TextEditingController _controllerId = new TextEditingController();

    showDialog(
      context: context,
      child: new AlertDialog(
          title: new Text('Create a Logical Output'),
          content: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                new TextField(
                  controller: _controllerName,
                  decoration: new InputDecoration(
                    hintText: 'Name',
                  ),
                ),
                new TextField(
                  controller: _controllerId,
                  decoration: new InputDecoration(
                    hintText: 'ID',
                  ),
                ),
              ]),
          actions: <Widget>[
            new FlatButton(
                child: const Text('SAVE'),
                onPressed: () {
                  _loutRef.push().set({
                    'id': int.parse(_controllerId.text),
                    'name': _controllerName.text,
                  });
                  Navigator.pop(context, null);
                }),
            new FlatButton(
                child: const Text('DISCARD'),
                onPressed: () {
                  Navigator.pop(context, null);
                })
          ]),
    );
  }

  void _openRemoveEntryDialog(LoutEntry entry) {
    showDialog(
        context: context,
        child: new AlertDialog(
            title: new Text('Remove ${entry.name} Logital Output'),
            actions: <Widget>[
              new FlatButton(
                  child: const Text('REMOVE'),
                  onPressed: () {
                    _loutRef.child(entry.key).remove();
                    Navigator.pop(context, null);
                  }),
              new FlatButton(
                  child: const Text('DISCARD'),
                  onPressed: () {
                    Navigator.pop(context, null);
                  })
            ]));
  }
}
