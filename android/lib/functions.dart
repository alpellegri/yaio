import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'io_entry.dart';
import 'const.dart';

class FunctionListItem extends StatelessWidget {
  final FunctionEntry entry;

  FunctionListItem(this.entry);

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
                      textScaleFactor: 1.5,
                      textAlign: TextAlign.left,
                    ),
                    new Text(
                      'type: ${entry.typeName}',
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    new Text(
                      'name: ${entry.actionName}',
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    new Text(
                      'delay: ${entry.delay.toString()}',
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    new Text(
                      'next: ${entry.next}',
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

class Functions extends StatefulWidget {
  Functions({Key key, this.title}) : super(key: key);

  static const String routeName = '/functions';

  final String title;

  @override
  _FunctionsState createState() => new _FunctionsState();
}

class _FunctionsState extends State<Functions> {
  final DatabaseReference _controlRef =
      FirebaseDatabase.instance.reference().child(kControlRef);

  List<FunctionEntry> entrySaves = new List();
  DatabaseReference _entryRef;

  _FunctionsState() {
    _entryRef = FirebaseDatabase.instance.reference().child(kFunctionsRef);
    _entryRef.onChildAdded.listen(_onEntryAdded);
    _entryRef.onChildChanged.listen(_onEntryEdited);
    _entryRef.onChildRemoved.listen(_onEntryRemoved);
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
        itemCount: entrySaves.length,
        itemBuilder: (buildContext, index) {
          return new InkWell(
              onTap: () => _openEntryDialog(entrySaves[index]),
              child: new FunctionListItem(entrySaves[index]));
        },
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _onFloatingActionButtonPressed,
        tooltip: 'add',
        child: new Icon(Icons.add),
      ),
    );
  }

  _onEntryAdded(Event event) {
    print('_onEntryAdded');
    setState(() {
      entrySaves.add(new FunctionEntry.fromSnapshot(_entryRef, event.snapshot));
    });
  }

  _onEntryEdited(Event event) {
    print('_onEntryEdited');
    var oldValue =
        entrySaves.singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      entrySaves[entrySaves.indexOf(oldValue)] =
          new FunctionEntry.fromSnapshot(_entryRef, event.snapshot);
    });
  }

  _onEntryRemoved(Event event) {
    print('_onEntryRemoved');
    var oldValue =
        entrySaves.singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      entrySaves.remove(oldValue);
    });
  }

  void _openEntryDialog(FunctionEntry entry) {
    showDialog(
      context: context,
      child: new EntryDialog(entry, entrySaves),
    );
  }

  void _onFloatingActionButtonPressed() {
    FunctionEntry entry = new FunctionEntry(_entryRef);
    _openEntryDialog(entry);
  }
}

class EntryDialog extends StatefulWidget {
  final FunctionEntry entry;
  final List<FunctionEntry> functionSaves;

  EntryDialog(this.entry, this.functionSaves);

  @override
  _EntryDialogState createState() =>
      new _EntryDialogState(entry, functionSaves);
}

class _EntryDialogState extends State<EntryDialog> {
  final TextEditingController _controllerName = new TextEditingController();
  final FunctionEntry entry;
  final List<FunctionEntry> functionSaves;
  Map<String, int> _delaysMap = {
    '0 s': 0,
    '300 s': 300,
    '1 s': 1000,
    '3 s': 3 * 1000,
    '10 s': 10 * 1000,
    '30 s': 30 * 1000,
    '1 m': 1 * 60 * 1000,
    '3 m': 3 * 60 * 1000,
  };
  List<String> _delayList = [
    '0 s',
    '300 s',
    '1 s',
    '3 s',
    '10 s',
    '30 s',
    '1 m',
    '3 m',
  ];
  String _selectType;
  String _selectAction;
  String _selectDelay;
  String _selectNext;
  List<String> selectTypeMenu = new List();
  Map<String, List> _menuRef = new Map();
  List ioMenu;

  List<RadioCodeEntry> radioTxSaves = new List();
  DatabaseReference _radioTxRef;
  List<IoEntry> doutSaves = new List();
  DatabaseReference _doutRef;
  List<IoEntry> loutSaves = new List();
  DatabaseReference _loutRef;

  _EntryDialogState(this.entry, this.functionSaves) {
    print('EntryDialogState');
    _radioTxRef = FirebaseDatabase.instance
        .reference()
        .child(kRadioCodesRef)
        .child('ActiveTx');
    _radioTxRef.onChildAdded.listen(_onRadioEntryAdded);
    _doutRef = FirebaseDatabase.instance.reference().child(kDoutRef);
    _doutRef.onChildAdded.listen(_onDoutEntryAdded);
    _loutRef = FirebaseDatabase.instance.reference().child(kLoutRef);
    _loutRef.onChildAdded.listen(_onLoutEntryAdded);

    _controllerName.text = entry.name;

    _menuRef['DOUT'] = doutSaves;
    _menuRef['LOUT'] = loutSaves;
    _menuRef['Radio Tx'] = radioTxSaves;
    _menuRef.forEach((String key, List value) {
      selectTypeMenu.add(key);
      ioMenu = loutSaves;
    });
    _selectType = 'DOUT';
    ioMenu = _menuRef[_selectType];
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
              new ListTile(
                title: const Text('Action Type'),
                trailing: new DropdownButton<String>(
                  hint: const Text('Select Type'),
                  value: _selectType,
                  onChanged: (String newValue) {
                    setState(() {
                      _selectType = newValue;
                      ioMenu = _menuRef[_selectType];
                      _selectAction = null;
                    });
                  },
                  items: selectTypeMenu.map((String entry) {
                    return new DropdownMenuItem<String>(
                      value: entry,
                      child: new Text(
                        entry,
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
                  items: ioMenu.map((dynamic entry) {
                    return new DropdownMenuItem<String>(
                      value: entry.name,
                      child: new Text(
                        entry.name,
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
                    setState(() {
                      _selectDelay = newValue;
                    });
                  },
                  items: _delayList.map((String entry) {
                    return new DropdownMenuItem<String>(
                      value: entry,
                      child: new Text(
                        entry,
                      ),
                    );
                  }).toList(),
                ),
              ),
              new ListTile(
                title: const Text('Next Function'),
                trailing: new DropdownButton<String>(
                  hint: const Text('Select a Function'),
                  value: _selectNext,
                  onChanged: (String newValue) {
                    setState(() {
                      _selectNext = newValue;
                    });
                  },
                  items: functionSaves.map((FunctionEntry entry) {
                    return new DropdownMenuItem<String>(
                      value: entry.name,
                      child: new Text(
                        entry.name,
                      ),
                    );
                  }).toList(),
                ),
              ),
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
                if (entry.key != null) {
                  entry.reference.child(entry.key).remove();
                }
                setState(() {
                  entry.name = _controllerName.text;
                  entry.next = _selectNext;
                  entry.typeName = _selectType;
                  entry.idType = 0; // _selectType;
                  entry.idAction = 0; // _selectAction;
                  entry.actionName = _selectAction;
                  entry.delay = _delaysMap[_selectDelay];
                });
                entry.reference.push().set(entry.toJson());
                Navigator.pop(context, null);
              }),
          new FlatButton(
              child: const Text('DISCARD'),
              onPressed: () {
                Navigator.pop(context, null);
              }),
        ]);
  }

  _onRadioEntryAdded(Event event) {
    print('_onRadioEntryAdded');
    setState(() {
      radioTxSaves
          .add(new RadioCodeEntry.fromSnapshot(_radioTxRef, event.snapshot));
    });
  }

  _onDoutEntryAdded(Event event) {
    print('_onDoutEntryAdded');
    setState(() {
      doutSaves.add(new IoEntry.fromSnapshot(_doutRef, event.snapshot));
    });
  }

  _onLoutEntryAdded(Event event) {
    print('_onLoutEntryAdded');
    setState(() {
      loutSaves.add(new IoEntry.fromSnapshot(_loutRef, event.snapshot));
    });
  }
}
