import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';

class DoutEntry {
  String key;
  int id;
  String name;

  DoutEntry(this.id, this.name);

  DoutEntry.fromSnapshot(DataSnapshot snapshot)
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

class DoutListItem extends StatelessWidget {
  final DoutEntry doutEntry;

  DoutListItem(this.doutEntry);

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
                      doutEntry.name,
                      textScaleFactor: 1.5,
                      textAlign: TextAlign.left,
                    ),
                    new Text(
                      'PIN: ${doutEntry.id >> 1}',
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                    ),
                    new Text(
                      'Value: ${doutEntry.id & 0x1}',
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

class DigitalIO extends StatefulWidget {
  DigitalIO({Key key, this.title}) : super(key: key);

  static const String routeName = '/digital_io';

  final String title;

  @override
  _DigitalIOState createState() => new _DigitalIOState();
}

class _DigitalIOState extends State<DigitalIO> {
  List<DoutEntry> doutSaves = new List();
  DatabaseReference _doutRef;

  _DigitalIOState() {
    _doutRef =
        FirebaseDatabase.instance.reference().child('DIO').child('Dout');
    _doutRef.onChildAdded.listen(_onDoutEntryAdded);
    _doutRef.onChildChanged.listen(_onDoutEntryEdited);
    _doutRef.onChildRemoved.listen(_onDoutEntryRemoved);
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
    return new Scaffold(
      drawer: drawer,
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new ListView.builder(
        shrinkWrap: true,
        reverse: true,
        itemCount: doutSaves.length,
        itemBuilder: (buildContext, index) {
          return new InkWell(
              onTap: () => _openRemoveEntryDialog(doutSaves[index]),
              child: new DoutListItem(doutSaves[index]));
        },
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _openAddEntryDialog,
        tooltip: 'add',
        child: new Icon(Icons.add),
      ),
    );
  }

  _onDoutEntryAdded(Event event) {
    print('_onDoutEntryAdded');
    setState(() {
      doutSaves.add(new DoutEntry.fromSnapshot(event.snapshot));
    });
  }

  _onDoutEntryEdited(Event event) {
    print('_onDoutEntryEdited');
    var oldValue =
        doutSaves.singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      doutSaves[doutSaves.indexOf(oldValue)] =
          new DoutEntry.fromSnapshot(event.snapshot);
    });
  }

  _onDoutEntryRemoved(Event event) {
    print('_onDoutEntryRemoved');
    var oldValue =
        doutSaves.singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      doutSaves.remove(oldValue);
    });
  }

  void _openAddEntryDialog() {
    final TextEditingController _controllerName = new TextEditingController();
    final TextEditingController _controllerPin = new TextEditingController();
    final TextEditingController _controllerValue = new TextEditingController();

    showDialog(
      context: context,
      child: new AlertDialog(
          title: new Text('Create a Digical Output'),
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
                  controller: _controllerPin,
                  decoration: new InputDecoration(
                    hintText: 'PIN',
                  ),
                ),
                new TextField(
                  controller: _controllerValue,
                  decoration: new InputDecoration(
                    hintText: 'Value',
                  ),
                ),
              ]),
          actions: <Widget>[
            new FlatButton(
                child: const Text('SAVE'),
                onPressed: () {
                  _doutRef.push().set({
                    'id': int.parse(_controllerPin.text) * 2 +
                        int.parse(_controllerValue.text),
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

  void _openRemoveEntryDialog(DoutEntry entry) {
    showDialog(
        context: context,
        child: new AlertDialog(
            title: new Text('Remove ${entry.name} Digital Output'),
            actions: <Widget>[
              new FlatButton(
                  child: const Text('REMOVE'),
                  onPressed: () {
                    _doutRef.child(entry.key).remove();
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
