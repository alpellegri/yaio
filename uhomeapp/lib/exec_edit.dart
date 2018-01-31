import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'entries.dart';
import 'firebase_utils.dart';

class ExecEdit extends StatefulWidget {
  static const String routeName = '/exec_edit';
  final String title;
  final ExecEntry entry;
  final List<ExecEntry> execList;

  ExecEdit({Key key, this.title, this.entry, this.execList}) : super(key: key);

  @override
  _ExecEditState createState() => new _ExecEditState(entry, execList);
}

class _ExecEditState extends State<ExecEdit> {
  final TextEditingController _controllerName = new TextEditingController();
  final ExecEntry entry;
  List<ExecEntry> execList;
  ExecEntry _selectedNext;
  var _selectedNextList;

  List<IoEntry> entryIoList = new List();

  _ExecEditState(this.entry, this.execList);

  @override
  void initState() {
    super.initState();
    _controllerName.text = entry?.name;
    if (entry.cb != null) {
      _selectedNextList = execList.where((el) => el.key == entry.cb);
      if (_selectedNextList.length == 1) {
        _selectedNext = execList.singleWhere((el) => el.key == entry.cb);
      } else {
        entry.cb = null;
      }
    }
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
          // title: new Text(widget.title),
          ),
      body: new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          new ListTile(
            title: new TextField(
              controller: _controllerName,
              decoration: new InputDecoration(
                hintText: 'Name',
              ),
            ),
          ),
          (execList.length > 0)
              ? new ListTile(
                  title: const Text('Call'),
                  trailing: new DropdownButton<ExecEntry>(
                    hint: const Text('Select'),
                    value: _selectedNext,
                    onChanged: (ExecEntry newValue) {
                      setState(() {
                        _selectedNext = newValue;
                      });
                    },
                    items: execList.map((ExecEntry entry) {
                      return new DropdownMenuItem<ExecEntry>(
                        value: entry,
                        child: new Text(entry.name),
                      );
                    }).toList(),
                  ),
                )
              : new Text('Functions not declared yet'),
          new ListTile(
            trailing: new ButtonTheme.bar(
              child: new ButtonBar(
                children: <Widget>[
                  new FlatButton(
                      child: const Text('REMOVE'),
                      onPressed: () {
                        entry.reference.child(entry.key).remove();
                        Navigator.pop(context, null);
                      }),
                  new FlatButton(
                      child: const Text('SAVE'),
                      onPressed: () {
                        setState(() {
                          entry.name = _controllerName.text;
                          entry.cb = _selectedNext?.key;
                          if (entry.key != null) {
                            entry.reference
                                .child(entry.key)
                                .update(entry.toJson());
                          } else {
                            print('save on: ${getNodeSubPath()}');
                            entry.setOwner(getNodeSubPath());
                            entry.reference.push().set(entry.toJson());
                          }
                        });
                        Navigator.pop(context, null);
                      }),
                  new FlatButton(
                    child: const Text('PROGRAM'),
                    onPressed: () {
                      Navigator.push(
                          context,
                          new MaterialPageRoute(
                            builder: (BuildContext context) =>
                                new ExecProg(prog: entry.p),
                          ));
                    },
                  ),
                  new FlatButton(
                      child: const Text('DISCARD'),
                      onPressed: () {
                        Navigator.pop(context, null);
                      }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExecProgListItem extends StatelessWidget {
  final int pc;
  final InstrEntry entry;
  final List<IoEntry> entryIoList;

  ExecProgListItem(this.pc, this.entry, this.entryIoList);

  @override
  Widget build(BuildContext context) {
    bool isImmediate = kOpCodeIsImmediate[OpCode.values[entry.i]];
    String value;
    if (isImmediate == false) {
      // value = entryIoList.singleWhere((el) => el.key == entry.v).name;
      value = 'not yet defined';
      entryIoList.forEach((el) {
        // print('key: ${el.key}, name: ${el.name}');
        if (el.key == entry.v) {
          value = el.name;
        }
      });
    } else {
      value = entry.v;
    }
    // '$pc: ${kOpCode2Name[OpCode.values[entry.i]]} $value'
    return new Container(
      padding: const EdgeInsets.all(2.0),
      child: new Row(
        children: [
          new Expanded(
            child: new Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                new Container(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: new Text(
                    '$pc',
                    style: new TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ),
                new Text(
                  '${kOpCode2Name[OpCode.values[entry.i]]}, $value',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ExecProg extends StatefulWidget {
  static const String routeName = '/exec_prog';
  final String title;
  final List<InstrEntry> prog;

  ExecProg({Key key, this.title, this.prog}) : super(key: key);

  @override
  _ExecProgState createState() => new _ExecProgState(prog);
}

class _ExecProgState extends State<ExecProg> {
  final List<InstrEntry> prog;
  List<IoEntry> entryIoList = new List();
  DatabaseReference _dataRef;
  StreamSubscription<Event> _onValueSubscription;

  _ExecProgState(this.prog);

  @override
  void initState() {
    super.initState();
    print('_ExecProgState');
    _dataRef = FirebaseDatabase.instance.reference().child(getDataRef());
    _onValueSubscription = _dataRef.onValue.listen(_onValueIoEntry);
  }

  @override
  void dispose() {
    super.dispose();
    _onValueSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      drawer: drawer,
      appBar: new AppBar(
          // title: new Text(widget.title),
          ),
      body: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            new ListView.builder(
              shrinkWrap: true,
              itemCount: prog.length,
              itemBuilder: (buildContext, index) {
                return new InkWell(
                    onTap: () => _openEntryDialog(index),
                    child:
                        new ExecProgListItem(index, prog[index], entryIoList));
              },
            ),
          ]),
      floatingActionButton: new FloatingActionButton(
        onPressed: _onFloatingActionButtonPressed,
        tooltip: 'add',
        child: new Icon(Icons.add),
      ),
    );
  }

  void _onFloatingActionButtonPressed() {}

  void _openEntryDialog(int index) {
    showDialog(
      context: context,
      child: new EntryDialog(index, prog, entryIoList),
    );
  }

  // read all oneshot
  void _onValueIoEntry(Event event) {
    print('_onValueIoEntry');
    Map data = event.snapshot.value;
    data.forEach((k, v) {
      // print('key: $k - value: ${v.toString()}');
      String owner = v["owner"];
      if (owner == getOwner()) {
        setState(() {
          IoEntry e = new IoEntry.fromMap(_dataRef, k, v);
          entryIoList.add(e);
        });
      }
    });
  }
}

class EntryDialog extends StatefulWidget {
  final int index;
  final List<InstrEntry> prog;
  final List<IoEntry> entryIoList;

  EntryDialog(this.index, this.prog, this.entryIoList);

  @override
  _EntryDialogState createState() =>
      new _EntryDialogState(index, prog, entryIoList);
}

class _EntryDialogState extends State<EntryDialog> {
  final int index;
  final List<InstrEntry> prog;
  final List<IoEntry> entryIoList;

  final TextEditingController _controllerValue = new TextEditingController();
  bool isImmediate;
  int _selectedOpCode;
  List<int> _opCodeMenu = new List<int>();
  IoEntry _selectedEntry;

  _EntryDialogState(this.index, this.prog, this.entryIoList);

  @override
  void initState() {
    super.initState();
    _selectedOpCode = prog[index].i;
    OpCode.values.toList().forEach((e) => _opCodeMenu.add(e.index));
    // _opCodeMenu.forEach((e) => print(e));
    isImmediate = kOpCodeIsImmediate[OpCode.values[prog[index].i]];
    print('isImmediate: $isImmediate');
    if (isImmediate == false) {
      // value = entryIoList.singleWhere((el) => el.key == entry.v).name;
      entryIoList.forEach((el) {
        // print('key: ${el.key}, name: ${el.name}');
        if (el.key == prog[index].v) {
          _selectedEntry = el;
        }
      });
    } else {
      _controllerValue.text = prog[index].v.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return new AlertDialog(
        title: new Text('Edit'),
        content: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            new ListTile(
              title: const Text('OpCode'),
              trailing: new DropdownButton<int>(
                hint: const Text('action'),
                value: _selectedOpCode,
                onChanged: (int newValue) {
                  setState(() {
                    _selectedOpCode = newValue;
                  });
                },
                items: _opCodeMenu.map((int entry) {
                  return new DropdownMenuItem<int>(
                    value: entry,
                    child: new Text(kOpCode2Name[OpCode.values[entry]]),
                  );
                }).toList(),
              ),
            ),
            (isImmediate == true)
                ? (new TextField(
                    controller: _controllerValue,
                    decoration: new InputDecoration(
                      hintText: 'value',
                    ),
                  ))
                : new ListTile(
                    title: const Text('Data'),
                    trailing: new DropdownButton<IoEntry>(
                      hint: const Text('data'),
                      value: _selectedEntry,
                      onChanged: (IoEntry newValue) {
                        setState(() {
                          _selectedEntry = newValue;
                        });
                      },
                      items: entryIoList.map((IoEntry entry) {
                        return new DropdownMenuItem<IoEntry>(
                          value: entry,
                          child: new Text(entry.name),
                        );
                      }).toList(),
                    ),
                  ),
          ],
        ),
        actions: <Widget>[
          new FlatButton(
              child: const Text('REMOVE'),
              onPressed: () {
                prog.removeAt(index);
                Navigator.pop(context, null);
              }),
          new FlatButton(
              child: const Text('SAVE'),
              onPressed: () {
                prog[index].i = _selectedOpCode;
                prog[index].v = (isImmediate == true)
                    ? _controllerValue.text
                    : _selectedEntry.key;
                Navigator.pop(context, prog);
              }),
          new FlatButton(
              child: const Text('DISCARD'),
              onPressed: () {
                Navigator.pop(context, null);
              }),
        ]);
  }
}
