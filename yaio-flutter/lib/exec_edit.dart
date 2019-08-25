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
  ExecEntry _selectedNext;
  var _selectedNextList;

  List<IoEntry> entryIoList = new List();

  @override
  void initState() {
    super.initState();
    _controllerName.text = widget.entry?.key;
    if (widget.entry.cb != null) {
      _selectedNextList =
          widget.execList.where((el) => el.key == widget.entry.cb);
      if (_selectedNextList.length == 1) {
        _selectedNext =
            widget.execList.singleWhere((el) => el.key == widget.entry.cb);
      } else {
        widget.entry.cb = null;
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
      appBar: new AppBar(
        title: new Text('Edit'),
      ),
      body: new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          new ListTile(
            title: new TextField(
              controller: _controllerName,
              decoration: new InputDecoration(
                hintText: 'Name',
                labelText: 'Routine Name',
              ),
            ),
          ),
          (widget.execList.length > 0)
              ? new ListTile(
                  title: const Text('Callback Routine'),
                  trailing: new DropdownButton<ExecEntry>(
                    hint: const Text('Select'),
                    value: _selectedNext,
                    onChanged: (ExecEntry newValue) {
                      setState(() {
                        _selectedNext = newValue;
                      });
                    },
                    items: widget.execList.map((ExecEntry entry) {
                      return new DropdownMenuItem<ExecEntry>(
                        value: entry,
                        child: new Text(entry.key),
                      );
                    }).toList(),
                  ),
                )
              : new Container(),
          new Container(
            child: new ButtonTheme.bar(
              child: new ButtonBar(
                children: <Widget>[
                  new FlatButton(
                      child: const Text('REMOVE'),
                      onPressed: () {
                        print(widget.entry.reference);
                        if (widget.entry.exist == true) {
                          widget.entry.reference
                              .child(widget.entry.key)
                              .remove();
                        }
                        Navigator.pop(context, null);
                      }),
                  new FlatButton(
                      child: const Text('SAVE'),
                      onPressed: () {
                        setState(() {
                          widget.entry.key = _controllerName.text;
                          widget.entry.cb = _selectedNext?.key;
                          widget.entry.setOwner(widget.node);
                          widget.entry.reference
                              .child(widget.entry.key)
                              .set(widget.entry.toJson());
                        });
                        Navigator.pop(context, null);
                      }),
                  new FlatButton(
                    child: const Text('EDIT'),
                    onPressed: () {
                      Navigator.push(
                          context,
                          new MaterialPageRoute(
                            builder: (BuildContext context) => new ExecProg(
                                domain: widget.domain,
                                node: widget.node,
                                prog: widget.entry.p),
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
    String value;
    value = entry.v;

    return new Container(
      padding: const EdgeInsets.all(8.0),
      child: new Row(
        children: <Widget>[
          new Expanded(
            child: new Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
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
  List<IoEntry> entryIoList = new List();
  DatabaseReference _dataRef;
  StreamSubscription<Event> _onValueSubscription;

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
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Program'),
      ),
      body: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
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
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<Null> _onFloatingActionButtonPressed() async {
    final TextEditingController ctrl =
        new TextEditingController(text: '${prog.length}');
    await showDialog<String>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return new AlertDialog(
          title: const Text('Select line number'),
          content: new SingleChildScrollView(
            child: new ListBody(
              children: <Widget>[
                new TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  decoration: new InputDecoration(
                    hintText: 'line',
                    labelText: 'Line',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            new FlatButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(ctrl.text);
              },
            ),
            new FlatButton(
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
  void _onValueIoEntry(Event event) {
    print('_onValueIoEntry');
    Map data = event.snapshot.value;
    if (data != null) {
      data.forEach((k, v) {
        // print('key: $k - value: ${v.toString()}');
        String owner = v["owner"];
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
  List<int> _opCodeMenu = new List<int>();
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
    return new AlertDialog(
        // title: new Text('Edit'),
        content: new Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new Row(children: [
              new Expanded(
                child: const Text('OpCode'),
              ),
              new DropdownButton<int>(
                isDense: true,
                hint: const Text('action'),
                value: _selectedOpCode,
                onChanged: (int newValue) {
                  setState(() {
                    _selectedOpCode = newValue;
                    _isImmediate =
                        kOpCodeIsImmediate[OpCode.values[_selectedOpCode]];
                  });
                },
                items: _opCodeMenu.map((int entry) {
                  return new DropdownMenuItem<int>(
                    value: entry,
                    child: new Text(
                      kOpCode2Name[OpCode.values[entry]],
                    ),
                  );
                }).toList(),
              ),
            ]),
            (_isImmediate == true)
                ? (new TextField(
                    controller: _controllerValue,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'value',
                      labelText: 'Value',
                    ),
                  ))
                : (new Row(children: [
                    new Expanded(
                      child: const Text('Data'),
                    ),
                    new DropdownButton<IoEntry>(
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
                          child: new Text(entry.key),
                        );
                      }).toList(),
                    ),
                  ])),
          ],
        ),
        actions: <Widget>[
          new OutlineButton(
              child: const Text('REMOVE'),
              onPressed: () {
                setState(() {
                  _didChange();
                  prog.removeAt(index);
                });
                Navigator.pop(context, null);
              }),
          new OutlineButton(
              child: const Text('SAVE'),
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
          new OutlineButton(
              child: const Text('DISCARD'),
              onPressed: () {
                Navigator.pop(context, null);
              }),
        ]);
  }
}
