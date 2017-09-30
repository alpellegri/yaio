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
        id = snapshot.value["id"],
        name = snapshot.value["name"];

  toJson() {
    return {
      "id": id,
      "name": name,
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
                new Row(
                  children: [
                    new Text(
                      doutEntry.name,
                      textScaleFactor: 1.3,
                      textAlign: TextAlign.left,
                    ),
                    new Text(
                      doutEntry.id.toString(),
                      textScaleFactor: 1.3,
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
  DatabaseReference _doutReference;

  _DigitalIOState() {
    _doutReference =
        FirebaseDatabase.instance.reference().child("DIO").child("Dout");
    _doutReference.onChildAdded.listen(_onEntryAdded);
    _doutReference.onChildChanged.listen(_onEntryEdited);
    _doutReference.onChildRemoved.listen(_onEntryRemoved);
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
              // onTap: () => _openEditEntryDialog(doutSaves[index]),
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

  _onEntryAdded(Event event) {
    print('_onEntryAdded');
    setState(() {
      doutSaves.add(new DoutEntry.fromSnapshot(event.snapshot));
    });
  }

  _onEntryEdited(Event event) {
    print('_onEntryEdited');
    var oldValue =
        doutSaves.singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      doutSaves[doutSaves.indexOf(oldValue)] =
          new DoutEntry.fromSnapshot(event.snapshot);
    });
  }

  _onEntryRemoved(Event event) {
    print('_onEntryRemoved');
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
          title: new Text('Create a Digital Output'),
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
                  _doutReference.push().set({
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
}
