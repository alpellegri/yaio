import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'entries.dart';
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
                    /*new Text(
                      'type: ${entry.typeName}',
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    new Text(
                      'action name: ${entry.actionName}',
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    new Text(
                      'type ID: ${entry.idType}',
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    new Text(
                      'action ID: ${entry.idAction}',
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
                    ),*/
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

  void _onEntryAdded(Event event) {
    setState(() {
      entrySaves.add(new FunctionEntry.fromSnapshot(_entryRef, event.snapshot));
    });
  }

  void _onEntryEdited(Event event) {
    FunctionEntry oldValue =
        entrySaves.singleWhere((el) => el.key == event.snapshot.key);
    setState(() {
      entrySaves[entrySaves.indexOf(oldValue)] =
          new FunctionEntry.fromSnapshot(_entryRef, event.snapshot);
    });
  }

  void _onEntryRemoved(Event event) {
    FunctionEntry oldValue =
        entrySaves.singleWhere((el) => el.key == event.snapshot.key);
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
  final List<FunctionEntry> functionList;

  EntryDialog(this.entry, this.functionList);

  @override
  _EntryDialogState createState() => new _EntryDialogState(entry, functionList);
}

class _EntryDialogState extends State<EntryDialog> {
  final TextEditingController _controllerName = new TextEditingController();
  final TextEditingController _controllerDelay = new TextEditingController();
  final FunctionEntry entry;
  final List<FunctionEntry> functionList;

  int _selectedType;
  String _selectedAction;
  FunctionEntry _selectedNext;
  List<String> selectTypeMenu = new List();
  Map<int, List> _selectedList = new Map();
  List ioMenu;
  dynamic _selectedEntry;

  List<IoEntry> entryList = new List();
  List<IoEntry> radioTxList = new List();
  List<IoEntry> doutList = new List();
  List<IoEntry> loutList = new List();
  DatabaseReference _graphRef;

  _EntryDialogState(this.entry, this.functionList) {
    print('EntryDialogState');
    _graphRef = FirebaseDatabase.instance.reference().child(kGraphRef);
    _graphRef.onChildAdded.listen(_onGraphEntryAdded);

    _selectedList[kDOut] = doutList;
    _selectedList[kLOut] = loutList;
    _selectedList[kRadioOut] = radioTxList;
    _selectedList.forEach((int key, List value) {
      selectTypeMenu.add(kEntryId2Name[key]);
    });

    _controllerDelay.text = '0';
  }

  @override
  Widget build(BuildContext context) {
    doutList = entryList.where((el) => (el.type == kDOut)).toList();
    loutList = entryList.where((el) => (el.type == kLOut)).toList();
    radioTxList =
        entryList.where((entry) => (entry.type == kRadioOut)).toList();
    _selectedList[kDOut] = doutList;
    _selectedList[kLOut] = loutList;
    _selectedList[kRadioOut] = radioTxList;
    if (entry.action != null) {
      _controllerName.text = entry.name;
      _controllerDelay.text = entry.delay.toString();
      if (entryList.length > 0) {
        IoEntry ioEntry = entryList.singleWhere((el) => el.key == entry.action);
        _selectedType = ioEntry.type;
        _selectedEntry = ioEntry;
        ioMenu = _selectedList[_selectedType];
      }
    }
    if (entry.next != null) {
      _selectedNext = functionList.singleWhere((el) => el.key == entry.next);
    }
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
                  hint: const Text('select a type'),
                  value: kEntryId2Name[_selectedType],
                  onChanged: (String newValue) {
                    setState(() {
                      _selectedType = kEntryName2Id[newValue];
                      ioMenu = _selectedList[_selectedType];
                      _selectedAction = null;
                    });
                  },
                  items: selectTypeMenu.map((String entry) {
                    return new DropdownMenuItem<String>(
                      value: entry,
                      child: new Text(entry),
                    );
                  }).toList(),
                ),
              ),
              ((ioMenu != null) && (ioMenu.length > 0))
                  ? new ListTile(
                      title: const Text('Action'),
                      trailing: new DropdownButton<dynamic>(
                        hint: const Text('select an action'),
                        value: _selectedEntry,
                        onChanged: (dynamic newValue) {
                          setState(() {
                            _selectedEntry = newValue;
                            _selectedAction = newValue.key;
                          });
                        },
                        items: ioMenu.map((dynamic entry) {
                          return new DropdownMenuItem<dynamic>(
                            value: entry,
                            child: new Text(entry.name),
                          );
                        }).toList(),
                      ),
                    )
                  : new Text('Actions not declared yet'),
              new TextField(
                controller: _controllerDelay,
                decoration: new InputDecoration(
                  hintText: 'delay',
                ),
              ),
              (functionList.length > 0)
                  ? new ListTile(
                      title: const Text('Next Function'),
                      trailing: new DropdownButton<FunctionEntry>(
                        hint: const Text('Select a Function'),
                        value: _selectedNext,
                        onChanged: (FunctionEntry newValue) {
                          setState(() {
                            _selectedNext = newValue;
                          });
                        },
                        items: functionList.map((FunctionEntry entry) {
                          return new DropdownMenuItem<FunctionEntry>(
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
                print(_controllerDelay.text);
                  setState(() {
                    entry.delay = int.parse(_controllerDelay.text);
                    entry.name = _controllerName.text;
                    entry.next = _selectedNext.key;
                    entry.action = _selectedAction;
                    if (entry.key != null) {
                      entry.reference.child(entry.key).update(entry.toJson());
                    } else {
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

  void _onGraphEntryAdded(Event event) {
    setState(() {
      entryList.add(new IoEntry.fromSnapshot(_graphRef, event.snapshot));
    });
  }
}
