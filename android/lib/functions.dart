import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';

class FunctionEntry {
  String key;
  int action;
  String action_name;
  int delay;
  int id;
  String name;
  String next;
  int type;
  String type_name;

  FunctionEntry(this.id, this.name);

  FunctionEntry.fromSnapshot(DataSnapshot snapshot)
      : key = snapshot.key,
        action = snapshot.value['action'],
        action_name = snapshot.value['action_name'],
        delay = snapshot.value['delay'],
        id = snapshot.value['id'],
        name = snapshot.value['name'],
        next = snapshot.value['next'],
        type = snapshot.value['type'],
        type_name = snapshot.value['type_name'];

  toJson() {
    return {
      'action': action,
      'action_name': action_name,
      'delay': delay,
      'id': id,
      'name': name,
      'next': next,
      'type': type,
      'type_name': type_name,
    };
  }
}

class FunctionListItem extends StatelessWidget {
  final FunctionEntry functionEntry;

  FunctionListItem(this.functionEntry);

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
                      functionEntry.name,
                      textScaleFactor: 1.5,
                      textAlign: TextAlign.left,
                    ),
                    new Text(
                      functionEntry.action_name,
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                    ),
                    new Text(
                      functionEntry.type_name,
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                    ),
                    new Text(
                      functionEntry.next,
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

class Functions extends StatefulWidget {
  Functions({Key key, this.title}) : super(key: key);

  static const String routeName = '/functions';

  final String title;

  @override
  _FunctionsState createState() => new _FunctionsState();
}

class _FunctionsState extends State<Functions> {
  List<FunctionEntry> functionSaves = new List();
  DatabaseReference _functionRef;

  _FunctionsState() {
    _functionRef = FirebaseDatabase.instance.reference().child('Functions');
    _functionRef.onChildAdded.listen(_onEntryAdded);
    _functionRef.onChildChanged.listen(_onEntryEdited);
    _functionRef.onChildRemoved.listen(_onEntryRemoved);
  }

  @override
  void initState() {
    super.initState();
    print('_FunctionsState');
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
        itemCount: functionSaves.length,
        itemBuilder: (buildContext, index) {
          return new InkWell(
              onTap: () => _openRemoveEntryDialog(functionSaves[index]),
              child: new FunctionListItem(functionSaves[index]));
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
      functionSaves.add(new FunctionEntry.fromSnapshot(event.snapshot));
    });
  }

  _onEntryEdited(Event event) {
    print('_onEntryEdited');
    var oldValue =
        functionSaves.singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      functionSaves[functionSaves.indexOf(oldValue)] =
          new FunctionEntry.fromSnapshot(event.snapshot);
    });
  }

  _onEntryRemoved(Event event) {
    print('_onEntryRemoved');
    var oldValue =
        functionSaves.singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      functionSaves.remove(oldValue);
    });
  }

  void _openAddEntryDialog() {
    final TextEditingController _controllerName = new TextEditingController();
    String selection;

    showDialog(
      context: context,
      child: new AlertDialog(
          title: new Text('Create a Function'),
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
                new ListTile(
                  title: const Text('Next Function'),
                  trailing: new DropdownButton<String>(
                    hint: new Text('Select a Function'),
                    value: selection,
                    onChanged: (String newValue) {
                      setState(() {
                        selection = newValue;
                      });
                    },
                    items: functionSaves.map((FunctionEntry entry) {
                      return new DropdownMenuItem<String>(
                        value: entry.name,
                        child: new Text(
                          entry.name,
                          style: new TextStyle(color: Colors.black),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ]),
          actions: <Widget>[
            new FlatButton(
                child: const Text('SAVE'),
                onPressed: () {
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

  void _openRemoveEntryDialog(FunctionEntry entry) {
    showDialog(
        context: context,
        child: new AlertDialog(
            title: new Text('Remove ${entry.name} Function'),
            actions: <Widget>[
              new FlatButton(
                  child: const Text('REMOVE'),
                  onPressed: () {
                    _functionRef.child(entry.key).remove();
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
