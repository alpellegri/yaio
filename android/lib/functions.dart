import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'io_entry.dart';
import 'const.dart';

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
  List<IoEntry> doutSaves = new List();
  DatabaseReference _doutRef;
  List<IoEntry> loutSaves = new List();
  DatabaseReference _loutRef;
  List<IoEntry> ioMenu;
  String selection;

  _FunctionsState() {
    ioMenu = loutSaves;
    _functionRef = FirebaseDatabase.instance.reference().child(kFunctionsRef);
    _functionRef.onChildAdded.listen(_onFuncEntryAdded);
    _functionRef.onChildChanged.listen(_onFuncEntryEdited);
    _functionRef.onChildRemoved.listen(_onFuncEntryRemoved);
    _doutRef = FirebaseDatabase.instance.reference().child(kDoutRef);
    _doutRef.onChildAdded.listen(_onDoutEntryAdded);
    _doutRef.onChildChanged.listen(_onDoutEntryEdited);
    _doutRef.onChildRemoved.listen(_onDoutEntryRemoved);
    _loutRef = FirebaseDatabase.instance.reference().child(kLoutRef);
    _loutRef.onChildAdded.listen(_onLoutEntryAdded);
    _loutRef.onChildChanged.listen(_onLoutEntryEdited);
    _loutRef.onChildRemoved.listen(_onLoutEntryRemoved);
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

  _onFuncEntryAdded(Event event) {
    print('_onFuncEntryAdded');
    setState(() {
      functionSaves.add(new FunctionEntry.fromSnapshot(event.snapshot));
    });
  }

  _onFuncEntryEdited(Event event) {
    print('_onFuncEntryEdited');
    var oldValue =
        functionSaves.singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      functionSaves[functionSaves.indexOf(oldValue)] =
          new FunctionEntry.fromSnapshot(event.snapshot);
    });
  }

  _onFuncEntryRemoved(Event event) {
    print('_onFuncEntryRemoved');
    var oldValue =
        functionSaves.singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      functionSaves.remove(oldValue);
    });
  }

  _onDoutEntryAdded(Event event) {
    print('_onDoutEntryAdded');
    setState(() {
      doutSaves.add(new IoEntry.fromSnapshot(event.snapshot));
    });
  }

  _onDoutEntryEdited(Event event) {
    print('_onDoutEntryEdited');
    var oldValue =
        doutSaves.singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      doutSaves[doutSaves.indexOf(oldValue)] =
          new IoEntry.fromSnapshot(event.snapshot);
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

  _onLoutEntryAdded(Event event) {
    print('_onLoutEntryAdded');
    setState(() {
      loutSaves.add(new IoEntry.fromSnapshot(event.snapshot));
    });
  }

  _onLoutEntryEdited(Event event) {
    print('_onLoutEntryEdited');
    var oldValue =
        loutSaves.singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      loutSaves[loutSaves.indexOf(oldValue)] =
          new IoEntry.fromSnapshot(event.snapshot);
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
    showDialog(
      context: context,
      child: new EntryDialog(
          functionSaves: functionSaves,
          doutSaves: doutSaves,
          loutSaves: loutSaves),
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

class EntryDialog extends StatefulWidget {
  final List<FunctionEntry> functionSaves;
  final List<IoEntry> doutSaves;
  final List<IoEntry> loutSaves;

  EntryDialog({this.functionSaves, this.doutSaves, this.loutSaves});

  @override
  _EntryDialogState createState() => new _EntryDialogState(
      functionSaves: functionSaves, doutSaves: doutSaves, loutSaves: loutSaves);
}

class _EntryDialogState extends State<EntryDialog> {
  final TextEditingController _controllerName = new TextEditingController();
  List<FunctionEntry> functionSaves;
  List<IoEntry> doutSaves;
  List<IoEntry> loutSaves;
  List<IoEntry> ioMenu;
  String _selectType;
  String _selectAction;
  String _selectDelay;
  String selectNext;

  _EntryDialogState({this.functionSaves, this.doutSaves, this.loutSaves}) {
    print('EntryDialogState');
    ioMenu = doutSaves;
  }

  @override
  Widget build(BuildContext context) {
    return new AlertDialog(
        title: new Text('Create a Function'),
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
                  hint: const Text('Select Type'),
                  value: _selectType,
                  onChanged: (String newValue) {
                    print(newValue);
                    setState(() {
                      _selectType = newValue;
                      if (newValue == 'Digital IO') {
                        ioMenu = doutSaves;
                      } else
                      /* if (newValue == 'Logical IO') */ {
                        ioMenu = loutSaves;
                      }
                    });
                  },
                  items:
                      <String>['Digital IO', 'Logical IO'].map((String entry) {
                    return new DropdownMenuItem<String>(
                      value: entry,
                      child: new Text(
                        entry,
                        style: new TextStyle(color: Colors.black),
                      ),
                    );
                  }).toList(),
                ),
              ),
              new ListTile(
                title: const Text('Action'),
                trailing: new DropdownButton<String>(
                  hint: const Text('Select Action'),
                  value: _selectAction,
                  onChanged: (String newValue) {
                    setState(() {
                      _selectAction = newValue;
                    });
                  },
                  items: ioMenu.map((IoEntry entry) {
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
              new ListTile(
                title: const Text('Delay'),
                trailing: new DropdownButton<String>(
                  hint: const Text('Select a Delay'),
                  value: _selectDelay,
                  onChanged: (String newValue) {
                    print(newValue);
                    setState(() {
                      _selectDelay = newValue;
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
              new ListTile(
                title: const Text('Next Function'),
                trailing: new DropdownButton<String>(
                  hint: const Text('Select a Function'),
                  value: selectNext,
                  onChanged: (String newValue) {
                    print(newValue);
                    setState(() {
                      selectNext = newValue;
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
        ]);
  }
}
