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
  StreamSubscription<Event> _onAddSubscription;

  _ExecProgState(this.prog);

  @override
  void initState() {
    super.initState();
    print('_ExecProgState');
    _dataRef = FirebaseDatabase.instance.reference().child(getDataRef());
    _onAddSubscription = _dataRef.onChildAdded.listen(_onEntryAdded);
  }

  @override
  void dispose() {
    super.dispose();
    _onAddSubscription.cancel();
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
              onTap: () => _openEntryDialog(prog[index]),
              child: new ExecProgListItem(index, prog[index], entryIoList));
        },
      ),
    );
  }

  void _openEntryDialog(InstrEntry entry) {
    showDialog(
      context: context,
      child: new EntryDialog(entry, entryIoList),
    );
  }

  void _onEntryAdded(Event event) {
    print('_onEntryAdded');
    setState(() {
      IoEntry entry = new IoEntry.fromSnapshot(_dataRef, event.snapshot);
      entryIoList.add(entry);
    });
  }
}

class EntryDialog extends StatefulWidget {
  final InstrEntry entry;
  final List<IoEntry> entryIoList;

  EntryDialog(this.entry, this.entryIoList);

  @override
  _EntryDialogState createState() => new _EntryDialogState(entry, entryIoList);
}

class _EntryDialogState extends State<EntryDialog> {
  final TextEditingController _controllerValue = new TextEditingController();
  final InstrEntry entry;
  final List<IoEntry> entryIoList;

  int _selectedOpCode;
  List<int> _opCodeMenu = new List<int>();
  IoEntry _selectedEntry;

  _EntryDialogState(this.entry, this.entryIoList) {
    print('EntryDialogState');
  }

  @override
  void initState() {
    super.initState();
    _selectedOpCode = entry.i;
    OpCode.values.toList().forEach((f) => _opCodeMenu.add(f.index));
    // _opCodeMenu.forEach((e) => print(e));
  }

  @override
  Widget build(BuildContext context) {
    bool isImmediate = kOpCodeIsImmediate[OpCode.values[entry.i]];
    print('isImmediate: $isImmediate');
    if (isImmediate == false) {
      // value = entryIoList.singleWhere((el) => el.key == entry.v).name;
      entryIoList.forEach((el) {
        // print('key: ${el.key}, name: ${el.name}');
        if (el.key == entry.v) {
          _selectedEntry = el;
        }
      });
    } else {
      _controllerValue.text = entry.v.toString();
    }

    return new AlertDialog(
        title: new Text('Edit Op Code'),
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
                    print(kOpCode2Name[OpCode.values[entry]]);
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
            ]),
        actions: <Widget>[
          new FlatButton(
              child: const Text('REMOVE'),
              onPressed: () {
                Navigator.pop(context, null);
              }),
          new FlatButton(
              child: const Text('SAVE'),
              onPressed: () {
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
