import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'entries.dart';
import 'firebase_utils.dart';
import 'ui_data_io.dart';

class DataIO extends StatefulWidget {
  static const String routeName = '/data_io';

  @override
  _DataIOState createState() => new _DataIOState();
}

class _DataIOState extends State<DataIO> {
  List<IoEntry> entryList = new List();
  DatabaseReference _dataRef;
  StreamSubscription<Event> _onAddSubscription;
  StreamSubscription<Event> _onEditSubscription;
  StreamSubscription<Event> _onRemoveSubscription;

  @override
  void initState() {
    super.initState();
    print('_DigitalIOState');
    _dataRef = FirebaseDatabase.instance.reference().child(getDataRef());
    _onAddSubscription = _dataRef.onChildAdded.listen(_onEntryAdded);
    _onEditSubscription = _dataRef.onChildChanged.listen(_onEntryChanged);
    _onRemoveSubscription = _dataRef.onChildRemoved.listen(_onEntryRemoved);
  }

  @override
  void dispose() {
    super.dispose();
    _onAddSubscription.cancel();
    _onEditSubscription.cancel();
    _onRemoveSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      drawer: drawer,
      appBar: new AppBar(
        title: new Text('Data IO @ ${getDomain()}'),
      ),
      body: new ListView.builder(
        shrinkWrap: true,
        reverse: true,
        itemCount: entryList.length,
        itemBuilder: (buildContext, index) {
          return new InkWell(
              onTap: () => _openEntryDialog(entryList[index]),
              child: new DataIoItemWidget(entryList[index]));
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
    String owner = event.snapshot.value["owner"];
    if (owner == getOwner()) {
      setState(() {
        IoEntry entry = new IoEntry.fromMap(
            _dataRef, event.snapshot.key, event.snapshot.value);
        entryList.add(entry);
      });
    }
  }

  void _onEntryChanged(Event event) {
    print('_onEntryChanged');
    String owner = event.snapshot.value["owner"];
    if (owner == getOwner()) {
      IoEntry oldValue =
          entryList.singleWhere((el) => el.key == event.snapshot.key);
      setState(() {
        entryList[entryList.indexOf(oldValue)] = new IoEntry.fromMap(
            _dataRef, event.snapshot.key, event.snapshot.value);
      });
    }
  }

  void _onEntryRemoved(Event event) {
    String owner = event.snapshot.value["owner"];
    if (owner == getOwner()) {
      IoEntry oldValue =
          entryList.singleWhere((el) => el.key == event.snapshot.key);
      setState(() {
        entryList.remove(oldValue);
      });
    }
  }

  void _openEntryDialog(IoEntry entry) {
    showDialog(
      context: context,
      child: new EntryDialog(entry),
    );
  }

  void _onFloatingActionButtonPressed() {
    final IoEntry entry = new IoEntry(_dataRef);
    _openEntryDialog(entry);
  }
}

class EntryDialog extends StatefulWidget {
  final IoEntry entry;

  EntryDialog(this.entry);

  @override
  _EntryDialogState createState() => new _EntryDialogState(entry);
}

class _EntryDialogState extends State<EntryDialog> {
  final IoEntry entry;
  final DatabaseReference _execRef =
      FirebaseDatabase.instance.reference().child(getExecRef());
  List<ExecEntry> _execList = new List();
  int _selectedType;
  List<int> _opTypeMenu = new List<int>();
  bool _checkboxValueWr = false;
  bool _checkboxValueRd = false;

  final TextEditingController _controllerName = new TextEditingController();
  final TextEditingController _controllerType = new TextEditingController();
  final TextEditingController _controller_1 = new TextEditingController();
  final TextEditingController _controller_2 = new TextEditingController();
  ExecEntry _selectedExec;
  StreamSubscription<Event> _onValueExecSubscription;

  _EntryDialogState(this.entry);

  @override
  void initState() {
    super.initState();
    _onValueExecSubscription = _execRef.onValue.listen(_onValueExec);
    if (entry.value != null) {
      _checkboxValueWr = entry.drawWr;
      _checkboxValueRd = entry.drawRd;
      _controllerName.text = entry.key;
      _controllerType.text = entry.code.toString();
      _selectedType = entry.code;
      switch (getMode(_selectedType)) {
        case 1:
          _controller_1.text = entry.getPin8().toString();
          _controller_2.text = entry.getValue24().toString();
          break;
        case 2:
          _controller_2.text = entry.getValue().toString();
          break;
        case 3:
          _controller_2.text = entry.getValue();
          break;
        case 4:
          if (entry.getValue() == false) {
            _controller_2.text = '0';
          } else if (entry.getValue() == true) {
            _controller_2.text = '1';
          } else {
            print('_controller_2.text error');
            _controller_2.text = '0';
          }
          break;
        case 5:
          _controller_1.text = entry.getBits(31, 8).toString();
          _controller_2.text = entry.getBits(23, 8).toString();
          break;
        case 6:
          _controller_1.text = entry.getBits(15, 8).toString();
          _controller_2.text = entry.getBits(7, 8).toString();
          break;
        default:
      }
    }
    DataCode.values.toList().forEach((e) => _opTypeMenu.add(e.index));
  }

  @override
  void dispose() {
    super.dispose();
    _onValueExecSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return new AlertDialog(
        title: new Text('Edit'),
        content: new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new TextField(
                controller: _controllerName,
                decoration: new InputDecoration(
                  hintText: 'name',
                ),
              ),
              new ListTile(
                title: const Text('Type'),
                trailing: new DropdownButton<int>(
                  hint: const Text('select'),
                  value: _selectedType,
                  onChanged: (int newValue) {
                    setState(() {
                      _selectedType = newValue;
                    });
                  },
                  items: _opTypeMenu.map((int entry) {
                    return new DropdownMenuItem<int>(
                      value: entry,
                      child: new Text(kEntryId2Name[DataCode.values[entry]]),
                    );
                  }).toList(),
                ),
              ),
              new DynamicEditWidget(
                  _selectedType, _controller_1, _controller_2),
              (_execList.length > 0)
                  ? new ListTile(
                      title: const Text('Call'),
                      trailing: new DropdownButton<ExecEntry>(
                        hint: const Text('select an exec'),
                        value: _selectedExec,
                        onChanged: (ExecEntry newValue) {
                          setState(() {
                            _selectedExec = newValue;
                          });
                        },
                        items: _execList.map((ExecEntry entry) {
                          return new DropdownMenuItem<ExecEntry>(
                            value: entry,
                            child: new Text(entry.key),
                          );
                        }).toList(),
                      ),
                    )
                  : new Text(''),
              new ListTile(
                title: const Text('Dashboard display WR'),
                trailing: new Checkbox(
                    value: _checkboxValueWr,
                    onChanged: (bool value) {
                      setState(() {
                        _checkboxValueWr = value;
                      });
                    }),
              ),
              new ListTile(
                title: const Text('Dashboard display RD'),
                trailing: new Checkbox(
                    value: _checkboxValueRd,
                    onChanged: (bool value) {
                      setState(() {
                        _checkboxValueRd = value;
                      });
                    }),
              ),
            ]),
        actions: <Widget>[
          new FlatButton(
              child: const Text('REMOVE'),
              onPressed: () {
                if (entry.exist == true) {
                  entry.reference.child(entry.key).remove();
                }
                Navigator.pop(context, null);
              }),
          new FlatButton(
              child: const Text('SAVE'),
              onPressed: () {
                entry.key = _controllerName.text;
                entry.drawWr = _checkboxValueWr;
                entry.drawRd = _checkboxValueRd;
                try {
                  entry.code = _selectedType;
                  entry.cb = _selectedExec?.key;
                  switch (getMode(_selectedType)) {
                    case 1:
                      entry.setPin8(int.parse(_controller_1.text));
                      entry.setValue24(int.parse(_controller_2.text));
                      break;
                    case 2:
                      entry.setValue(int.parse(_controller_2.text));
                      break;
                    case 3:
                      entry.setValue(_controller_2.text);
                      break;
                    case 4:
                      if (_controller_2.text == '0') {
                        entry.setValue(false);
                      } else if (_controller_2.text == '1') {
                        entry.setValue(true);
                      } else {
                        print('_controller_2.text error');
                      }
                      break;
                    case 5:
                      entry.setBits(31, 8, int.parse(_controller_1.text));
                      entry.setBits(23, 8, int.parse(_controller_2.text));
                      break;
                    case 6:
                      entry.setBits(15, 8, int.parse(_controller_1.text));
                      entry.setBits(7, 8, int.parse(_controller_2.text));
                      break;
                  }
                  entry.setOwner(getOwner());
                  if (entry.value != null) {
                    entry.reference.child(entry.key).set(entry.toJson());
                  }
                } catch (exception, stackTrace) {
                  print('bug');
                }
                Navigator.pop(context, null);
              }),
          new FlatButton(
              child: const Text('DISCARD'),
              onPressed: () {
                Navigator.pop(context, null);
              }),
        ]);
  }

  void _onValueExec(Event event) {
    print('_onValueExec');
    Map data = event.snapshot.value;
    if (data != null) {
      data.forEach((k, v) {
        // print('key: $k - value: ${v.toString()}');
        // filter only relative to the domain
        String owner = v["owner"];
        if (owner == getOwner()) {
          setState(() {
            ExecEntry e = new ExecEntry.fromMap(_execRef, k, v);
            _execList.add(e);
            if (entry.cb == e.key) {
              _selectedExec = e;
            }
          });
        }
      });
    }
  }
}
