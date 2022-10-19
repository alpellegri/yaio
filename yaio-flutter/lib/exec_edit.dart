import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'entries.dart';
import 'firebase_utils.dart';

class ExecEdit extends StatefulWidget {
  final String domain;
  final String node;
  final ExecEntry entry;
  final List<ExecEntry> execList;

  ExecEdit({Key key, this.domain, this.node, this.entry, this.execList})
      : super(key: key);

  @override
  _ExecEditState createState() => new _ExecEditState();
}

class _ExecEditState extends State<ExecEdit> {
  final TextEditingController _controllerName = new TextEditingController();
  String _selectedExec;
  List<IoEntry> entryIoList = [];
  List<String> _execStringList = [];

  @override
  void initState() {
    super.initState();

    _execStringList = widget.execList.map((e) => e.key).toList();
    _execStringList.add('');

    _controllerName.text = widget.entry?.key;
    if (widget.entry.cb != null) {
      _selectedExec = _execStringList.firstWhere(
        (el) => el == widget.entry.cb,
        orElse: () => null,
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit'),
      ),
      body: Column(
        children: <Widget>[
          ListTile(
            title: TextField(
              controller: _controllerName,
              decoration: InputDecoration(
                hintText: 'Name',
                labelText: 'Routine Name',
              ),
            ),
          ),
          (_execStringList.length > 1)
              ? ListTile(
                  title: Text('Callback Routine'),
                  trailing: DropdownButton<String>(
                    hint: Text('Select'),
                    value: _selectedExec,
                    onChanged: (String newValue) {
                      setState(() {
                        _selectedExec = newValue;
                      });
                    },
                    items: _execStringList.map((String e) {
                      return DropdownMenuItem<String>(
                        value: e,
                        child: (e != '') ? (Text(e)) : (Text('-')),
                      );
                    }).toList(),
                  ),
                )
              : Container(),
          SizedBox(height: 24.0),
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                TextButton(
                    child: Text('REMOVE'),
                    onPressed: () {
                      print(widget.entry.reference);
                      if (widget.entry.exist == true) {
                        widget.entry.reference.child(widget.entry.key).remove();
                      }
                      Navigator.pop(context, null);
                    }),
                TextButton(
                    child: Text('SAVE'),
                    onPressed: () {
                      setState(() {
                        widget.entry.key = _controllerName.text;
                        if (_selectedExec != '') {
                          widget.entry.cb = _selectedExec;
                        } else {
                          widget.entry.cb = null;
                        }
                        widget.entry.setOwner(widget.node);
                        widget.entry.reference
                            .child(widget.entry.key)
                            .set(widget.entry.toJson());
                      });
                      Navigator.pop(context, null);
                    }),
                TextButton(
                  child: Text('EDIT'),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) => new ExecProg(
                              domain: widget.domain,
                              node: widget.node,
                              prog: widget.entry.p),
                        ));
                  },
                ),
              ],
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
    String value;
    value = entry.v;

    return Container(
      padding: EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Container(
                    padding: EdgeInsets.only(right: 8.0),
                    child:
                        Text('$pc', style: TextStyle(color: Colors.grey[500]))),
                Text('${kOpCode2Name[OpCode.values[entry.i]]}, $value'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ExecProg extends StatefulWidget {
  final String domain;
  final String node;
  static const String routeName = '/exec_prog';
  final List<InstrEntry> prog;

  ExecProg({Key key, this.domain, this.node, this.prog}) : super(key: key);

  @override
  _ExecProgState createState() => new _ExecProgState(domain, node, prog);
}

class _ExecProgState extends State<ExecProg> {
  final String domain;
  final String node;
  final List<InstrEntry> prog;
  List<IoEntry> entryIoList = [];
  DatabaseReference _dataRef;
  StreamSubscription<DatabaseEvent> _onValueSubscription;

  _ExecProgState(this.domain, this.node, this.prog);

  @override
  void initState() {
    super.initState();
    print('_ExecProgState');
    _dataRef = FirebaseDatabase.instance
        .reference()
        .child(getUserRef())
        .child('obj/data')
        .child(domain);
    _onValueSubscription = _dataRef.onValue.listen(_onValueIoEntry);
  }

  @override
  void dispose() {
    super.dispose();
    _onValueSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    print('_ExecProgState');
    return Scaffold(
      appBar: AppBar(
        title: Text('Program'),
      ),
      body: Container(
        child: ListView.builder(
          shrinkWrap: true,
          physics: BouncingScrollPhysics(),
          itemCount: prog.length,
          itemBuilder: (buildContext, index) {
            return InkWell(
                onTap: () => _openEntryDialog(index),
                child: ExecProgListItem(index, prog[index], entryIoList));
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFloatingActionButtonPressed,
        tooltip: 'add',
        child: Icon(Icons.add),
      ),
    );
  }

  Future<Null> _onFloatingActionButtonPressed() async {
    final TextEditingController ctrl =
        TextEditingController(text: '${prog.length}');
    await showDialog<String>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select line number'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'line',
                    labelText: 'Line',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(ctrl.text);
              },
            ),
            TextButton(
              child: Text('DISCARD'),
              onPressed: () {
                Navigator.of(context).pop(null);
              },
            ),
          ],
        );
      },
    ).then((e) {
      if (e != null) {
        int index = int.parse(e);
        setState(() {
          if (index < prog.length) {
            prog.insert(index, new InstrEntry(0, '0'));
          } else {
            prog.add(new InstrEntry(0, '0'));
          }
        });
      } else {
        print('showDialog null');
      }
    });
  }

  void _didChanged(bool newValue) {
    setState(() {});
  }

  void _openEntryDialog(int index) {
    showDialog<Null>(
      context: context,
      builder: (BuildContext context) {
        return new EntryDialog(index, prog, entryIoList, _didChanged);
      },
    );
  }

  // read all oneshot
  void _onValueIoEntry(DatabaseEvent event) {
    print('_onValueIoEntry');
    Map data = event.snapshot.value;
    if (data != null) {
      data.forEach((k, v) {
        // print('key: $k - value: ${v.toString()}');
        String owner = v['owner'];
        if (owner == node) {
          setState(() {
            IoEntry e = new IoEntry.fromMap(_dataRef, k, v);
            entryIoList.add(e);
          });
        }
      });
    }
  }
}

class EntryDialog extends StatefulWidget {
  final int index;
  final List<InstrEntry> prog;
  final List<IoEntry> entryIoList;
  final ValueChanged<bool> onChanged;

  EntryDialog(this.index, this.prog, this.entryIoList, this.onChanged);

  @override
  _EntryDialogState createState() =>
      new _EntryDialogState(index, prog, entryIoList);
}

class _EntryDialogState extends State<EntryDialog> {
  final int index;
  final List<InstrEntry> prog;
  final List<IoEntry> entryIoList;

  final TextEditingController _controllerValue = new TextEditingController();
  bool _isImmediate;
  int _selectedOpCode;
  List<int> _opCodeMenu = [];
  IoEntry _selectedEntry;

  _EntryDialogState(this.index, this.prog, this.entryIoList);

  @override
  void initState() {
    super.initState();
    _selectedOpCode = prog[index].i;
    OpCode.values.toList().forEach((e) => _opCodeMenu.add(e.index));
    // _opCodeMenu.forEach((e) => print(e));
    _isImmediate = kOpCodeIsImmediate[OpCode.values[prog[index].i]];
    print('isImmediate: $_isImmediate');
    if (_isImmediate == false) {
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

  void _didChange() {
    widget.onChanged(true);
  }

  @override
  Widget build(BuildContext context) {
    print('_EntryDialogState');
    return AlertDialog(
      title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Edit Code'),
            Icon(Icons.edit),
          ]),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Opcode'),
            SizedBox(height: 8.0),
            DropdownButton<int>(
              isDense: true,
              hint: Text('action'),
              value: _selectedOpCode,
              onChanged: (int newValue) {
                setState(() {
                  _selectedOpCode = newValue;
                  _isImmediate =
                      kOpCodeIsImmediate[OpCode.values[_selectedOpCode]];
                });
              },
              items: _opCodeMenu.map((int entry) {
                return DropdownMenuItem<int>(
                  value: entry,
                  child: Text(
                    kOpCode2Name[OpCode.values[entry]],
                  ),
                );
              }).toList(),
            ),
          ]),
          SizedBox(height: 16.0),
          (_isImmediate == true)
              ? (TextField(
                  controller: _controllerValue,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'value',
                    labelText: 'Value',
                  ),
                ))
              : (Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Text('Operand'),
                      DropdownButton<IoEntry>(
                        hint: Text('data'),
                        value: _selectedEntry,
                        onChanged: (IoEntry newValue) {
                          setState(() {
                            _selectedEntry = newValue;
                          });
                        },
                        items: entryIoList.map((IoEntry entry) {
                          return DropdownMenuItem<IoEntry>(
                            value: entry,
                            child: Text(entry.key),
                          );
                        }).toList(),
                      ),
                    ])),
          SizedBox(height: 24.0),
          Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                TextButton(
                    child: Text('REMOVE'),
                    onPressed: () {
                      setState(() {
                        _didChange();
                        prog.removeAt(index);
                      });
                      Navigator.pop(context, null);
                    }),
                TextButton(
                    child: Text('SAVE'),
                    onPressed: () {
                      _didChange();
                      setState(() {
                        prog[index].i = _selectedOpCode;
                        prog[index].v = (_isImmediate == true)
                            ? _controllerValue.text
                            : _selectedEntry.key;
                        Navigator.pop(context, null);
                      });
                    }),
              ]),
        ],
      ),
    );
  }
}
