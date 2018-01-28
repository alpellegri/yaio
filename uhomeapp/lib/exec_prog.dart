import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'entries.dart';
import 'firebase_utils.dart';

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
                      '$pc: ${kOpCode2Name[OpCode.values[entry.i]]} $value',
                      textScaleFactor: 1.2,
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
    _onValueSubscription = _dataRef.onValue.listen(_onValueEntry);
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
      body: new ListView.builder(
        shrinkWrap: true,
        itemCount: prog.length,
        itemBuilder: (buildContext, index) {
          return new InkWell(
              onTap: () => _openEntryDialog(index),
              child: new ExecProgListItem(index, prog[index], entryIoList));
        },
      ),
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
  void _onValueEntry(Event event) {
    print('_onValueEntry');
    Map data = event.snapshot.value;
    data.forEach((k, v) {
      // print('key: $k - value: ${v.toString()}');
      setState(() {
        IoEntry e = new IoEntry.fromMap(_dataRef, k, v);
        entryIoList.add(e);
      });
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

  _EntryDialogState(this.index, this.prog, this.entryIoList) {
    print('EntryDialogState');
  }

  @override
  void initState() {
    super.initState();
    _selectedOpCode = prog[index].i;
    OpCode.values.toList().forEach((f) => _opCodeMenu.add(f.index));
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
