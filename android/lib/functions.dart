import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'io_entry.dart';
import 'const.dart';

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
  final DatabaseReference _controlRef =
      FirebaseDatabase.instance.reference().child(kControlRef);

  List<FunctionEntry> functionSaves = new List();
  DatabaseReference _functionRef;
  List<RadioCodeEntry> radioTxSaves = new List();
  DatabaseReference _radioTxRef;
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
    _radioTxRef = FirebaseDatabase.instance
        .reference()
        .child(kRadioCodesRef)
        .child('ActiveTx');
    _radioTxRef.onChildAdded.listen(_onRadioEntryAdded);
    _radioTxRef.onChildChanged.listen(_onRadioEntryEdited);
    _radioTxRef.onChildRemoved.listen(_onRadioEntryRemoved);
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
              onTap: () => _openEntryDialog(functionSaves[index]),
              child: new FunctionListItem(functionSaves[index]));
        },
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _onFloatingActionButtonPressed,
        tooltip: 'add',
        child: new Icon(Icons.add),
      ),
    );
  }

  _onFuncEntryAdded(Event event) {
    print('_onFuncEntryAdded');
    setState(() {
      functionSaves.add(new FunctionEntry.fromSnapshot(_functionRef, event.snapshot));
    });
  }

  _onFuncEntryEdited(Event event) {
    print('_onFuncEntryEdited');
    var oldValue =
        functionSaves.singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      functionSaves[functionSaves.indexOf(oldValue)] =
          new FunctionEntry.fromSnapshot(_functionRef, event.snapshot);
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

  _onRadioEntryAdded(Event event) {
    print('_onRadioEntryAdded');
    setState(() {
      radioTxSaves
          .add(new RadioCodeEntry.fromSnapshot(_radioTxRef, event.snapshot));
    });
  }

  _onRadioEntryEdited(Event event) {
    print('_onRadioEntryEdited');
    var oldValue =
        radioTxSaves.singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      radioTxSaves[radioTxSaves.indexOf(oldValue)] =
          new RadioCodeEntry.fromSnapshot(_radioTxRef, event.snapshot);
    });
  }

  _onRadioEntryRemoved(Event event) {
    print('_onRadioEntryRemoved');
    var oldValue =
        radioTxSaves.singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      radioTxSaves.remove(oldValue);
    });
  }

  _onDoutEntryAdded(Event event) {
    print('_onDoutEntryAdded');
    setState(() {
      doutSaves.add(new IoEntry.fromSnapshot(_doutRef, event.snapshot));
    });
  }

  _onDoutEntryEdited(Event event) {
    print('_onDoutEntryEdited');
    var oldValue =
        doutSaves.singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      doutSaves[doutSaves.indexOf(oldValue)] =
          new IoEntry.fromSnapshot(_doutRef, event.snapshot);
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
      loutSaves.add(new IoEntry.fromSnapshot(_loutRef, event.snapshot));
    });
  }

  _onLoutEntryEdited(Event event) {
    print('_onLoutEntryEdited');
    var oldValue =
        loutSaves.singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      loutSaves[loutSaves.indexOf(oldValue)] =
          new IoEntry.fromSnapshot(_loutRef, event.snapshot);
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

  void _openEntryDialog(FunctionEntry entry) {
    showDialog(
      context: context,
      child: new EntryDialog(
        entry: entry,
        functionRef: _functionRef,
        functionSaves: functionSaves,
        radioTxSaves: radioTxSaves,
        doutSaves: doutSaves,
        loutSaves: loutSaves,
      ),
    );
  }

  void _onFloatingActionButtonPressed() {
    // request update to node
    _controlRef.child('radioTx_update').set(true);
    DateTime now = new DateTime.now();
    _controlRef.child('time').set(now.millisecondsSinceEpoch ~/ 1000);
  }
}

class EntryDialog extends StatefulWidget {
  final FunctionEntry entry;
  final DatabaseReference functionRef;
  final List<FunctionEntry> functionSaves;
  final List<RadioCodeEntry> radioTxSaves;
  final List<IoEntry> doutSaves;
  final List<IoEntry> loutSaves;

  EntryDialog({
    this.entry,
    this.functionRef,
    this.functionSaves,
    this.radioTxSaves,
    this.doutSaves,
    this.loutSaves,
  });

  @override
  _EntryDialogState createState() => new _EntryDialogState(
        entry: entry,
        functionRef: functionRef,
        functionSaves: functionSaves,
        radioTxSaves: radioTxSaves,
        doutSaves: doutSaves,
        loutSaves: loutSaves,
      );
}

class _EntryDialogState extends State<EntryDialog> {
  final TextEditingController _controllerName = new TextEditingController();
  final FunctionEntry entry;
  final DatabaseReference functionRef;
  final List<FunctionEntry> functionSaves;
  final List<RadioCodeEntry> radioTxSaves;
  final List<IoEntry> doutSaves;
  final List<IoEntry> loutSaves;
  String _selectType;
  String _selectAction;
  String _selectDelay;
  String _selectNext;
  List<String> selectTypeMenu = new List();
  Map<String, List> _menuRef = new Map();
  List ioMenu;

  _EntryDialogState({
    this.entry,
    this.functionRef,
    this.functionSaves,
    this.radioTxSaves,
    this.doutSaves,
    this.loutSaves,
  }) {
    print('EntryDialogState');
    _controllerName.text = entry.name;
    _menuRef['DOUT'] = doutSaves;
    _menuRef['LOUT'] = loutSaves;
    _menuRef['Radio Tx'] = radioTxSaves;
    _menuRef.forEach((String key, List value) {
      selectTypeMenu.add(key);
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
                    print(newValue);
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
                  items: ioMenu.map((entry) {
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
                    print(newValue);
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
              child: const Text('DELETE'),
              onPressed: () {
                entry.reference.child(entry.key).remove();
                Navigator.pop(context, null);
              }),
          new FlatButton(
              child: const Text('SAVE'),
              onPressed: () {
                print(entry.reference);
                // entry.reference.child(entry.key).remove();
                entry.reference.push().set({
                  'id': entry.id,
                  'name': _controllerName.text,
                  'action_name': _selectAction,
                  'delay': _selectDelay,
                  'func': _selectNext,
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
