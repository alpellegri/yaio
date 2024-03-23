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

  const ExecEdit({
    super.key,
    required this.domain,
    required this.node,
    required this.entry,
    required this.execList,
  });

  @override
  _ExecEditState createState() => _ExecEditState();
}

class _ExecEditState extends State<ExecEdit> {
  final TextEditingController _controllerName = TextEditingController();
  String? _selectedExec;
  List<IoEntry> entryIoList = [];
  List<String> _execStringList = [];

  @override
  void initState() {
    super.initState();

    _execStringList = widget.execList.map((e) => e.key!).toList();
    _execStringList.add('');

    // _controllerName.text = widget.entry.key!;
    if (widget.entry.cb != null) {
      _selectedExec = _execStringList.firstWhere(
        (el) => el == widget.entry.cb,
        orElse: () => '',
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
        title: const Text('Edit'),
      ),
      body: Column(
        children: <Widget>[
          ListTile(
            title: TextField(
              controller: _controllerName,
              decoration: const InputDecoration(
                hintText: 'Name',
                labelText: 'Routine Name',
              ),
            ),
          ),
          (_execStringList.length > 1)
              ? ListTile(
                  title: const Text('Callback Routine'),
                  trailing: DropdownButton<String>(
                    hint: const Text('Select'),
                    value: _selectedExec,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedExec = newValue!;
                      });
                    },
                    items: _execStringList.map((String e) {
                      return DropdownMenuItem<String>(
                        value: e,
                        child: (e != '') ? (Text(e)) : (const Text('-')),
                      );
                    }).toList(),
                  ),
                )
              : Container(),
          const SizedBox(height: 24.0),
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                TextButton(
                    child: const Text('REMOVE'),
                    onPressed: () {
                      print(widget.entry.reference);
                      if (widget.entry.exist == true) {
                        widget.entry.reference
                            .child(widget.entry.key!)
                            .remove();
                      }
                      Navigator.pop(context, null);
                    }),
                TextButton(
                    child: const Text('SAVE'),
                    onPressed: () {
                      setState(() {
                        widget.entry.key = _controllerName.text;
                        if (_selectedExec != '') {
                          widget.entry.cb = _selectedExec;
                        } else {
                          widget.entry.cb = null;
                        }
                        // print('ExecEntry.toJson owner ${widget.node}');
                        widget.entry.owner = widget.node;
                        widget.entry.reference
                            .child(widget.entry.key!)
                            .set(widget.entry.toJson());
                      });
                      Navigator.pop(context, null);
                    }),
                TextButton(
                  child: const Text('EDIT'),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) => ExecProg(
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
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Container(
                    padding: const EdgeInsets.only(right: 8.0),
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

  const ExecProg({
    super.key,
    required this.domain,
    required this.node,
    required this.prog,
  });

  @override
  _ExecProgState createState() => _ExecProgState(domain, node, prog);
}

class _ExecProgState extends State<ExecProg> {
  final String domain;
  final String node;
  final List<InstrEntry> prog;
  List<IoEntry> entryIoList = [];
  late DatabaseReference _dataRef;
  late StreamSubscription<DatabaseEvent> _onValueSubscription;

  _ExecProgState(this.domain, this.node, this.prog);

  @override
  void initState() {
    super.initState();
    print('_ExecProgState');
    _dataRef = FirebaseDatabase.instance
        .ref()
        .child(getUserRef()!)
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
        title: const Text('Program'),
      ),
      body: ListView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        itemCount: prog.length,
        itemBuilder: (buildContext, index) {
          return InkWell(
              onTap: () => _openEntryDialog(index),
              child: ExecProgListItem(index, prog[index], entryIoList));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFloatingActionButtonPressed,
        tooltip: 'add',
        child: const Icon(Icons.add),
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
          title: const Text('Select line number'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'line',
                    labelText: 'Line',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(ctrl.text);
              },
            ),
            TextButton(
              child: const Text('DISCARD'),
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
            prog.insert(index, InstrEntry(0, '0'));
          } else {
            prog.add(InstrEntry(0, '0'));
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
        return EntryDialog(
            index: index,
            prog: prog,
            entryIoList: entryIoList,
            onChanged: _didChanged);
      },
    );
  }

  // read all oneshot
  void _onValueIoEntry(DatabaseEvent event) {
    print('_onValueIoEntry');
    Map data = event.snapshot.value as Map;
    if (data.length > 0) {
      data.forEach((k, v) {
        // print('key: $k - value: ${v.toString()}');
        String? owner = v['owner'];
        if (owner == node) {
          setState(() {
            IoEntry e = IoEntry.fromMap(_dataRef, k, v);
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

  const EntryDialog({
    super.key,
    required this.index,
    required this.prog,
    required this.entryIoList,
    required this.onChanged,
  });

  @override
  _EntryDialogState createState() =>
      _EntryDialogState(index, prog, entryIoList);
}

class _EntryDialogState extends State<EntryDialog> {
  final int index;
  final List<InstrEntry> prog;
  final List<IoEntry> entryIoList;

  final TextEditingController _controllerValue = TextEditingController();
  bool? _isImmediate;
  int? _selectedOpCode;
  List<int> _opCodeMenu = [];
  IoEntry? _selectedEntry;

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
      for (var el in entryIoList) {
        // print('key: ${el.key}, name: ${el.name}');
        if (el.key == prog[index].v) {
          _selectedEntry = el;
        }
      }
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
          children: const <Widget>[
            Text('Edit Code'),
            Icon(Icons.edit),
          ]),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Opcode'),
            const SizedBox(height: 8.0),
            DropdownButton<int>(
              isDense: true,
              hint: const Text('action'),
              value: _selectedOpCode,
              onChanged: (int? newValue) {
                setState(() {
                  _selectedOpCode = newValue!;
                  _isImmediate =
                      kOpCodeIsImmediate[OpCode.values[_selectedOpCode!]];
                });
              },
              items: _opCodeMenu.map((int entry) {
                return DropdownMenuItem<int>(
                  value: entry,
                  child: Text(kOpCode2Name[OpCode.values[entry]]!),
                );
              }).toList(),
            ),
          ]),
          const SizedBox(height: 16.0),
          (_isImmediate == true)
              ? (TextField(
                  controller: _controllerValue,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'value',
                    labelText: 'Value',
                  ),
                ))
              : (Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      const Text('Operand'),
                      DropdownButton<IoEntry>(
                        hint: const Text('data'),
                        value: _selectedEntry,
                        onChanged: (IoEntry? newValue) {
                          setState(() {
                            _selectedEntry = newValue!;
                          });
                        },
                        items: entryIoList.map((IoEntry entry) {
                          return DropdownMenuItem<IoEntry>(
                            value: entry,
                            child: Text(entry.key!),
                          );
                        }).toList(),
                      ),
                    ])),
          const SizedBox(height: 24.0),
          Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                TextButton(
                    child: const Text('REMOVE'),
                    onPressed: () {
                      setState(() {
                        _didChange();
                        prog.removeAt(index);
                      });
                      Navigator.pop(context, null);
                    }),
                TextButton(
                    child: const Text('SAVE'),
                    onPressed: () {
                      _didChange();
                      setState(() {
                        prog[index].i = _selectedOpCode!;
                        prog[index].v = (_isImmediate! == true)
                            ? _controllerValue.text
                            : _selectedEntry!.key!;
                        Navigator.pop(context, null);
                      });
                    }),
              ]),
        ],
      ),
    );
  }
}
