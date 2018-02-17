import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'entries.dart';
import 'firebase_utils.dart';

class ListItem extends StatelessWidget {
  final IoEntry entry;

  ListItem(this.entry);

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
                new Expanded(
                    child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    new Text(
                      entry.key,
                      textScaleFactor: 1.2,
                      textAlign: TextAlign.left,
                    ),
                    new Text(
                      '${kEntryId2Name[DataCode.values[entry.code]]}',
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                )),
                new Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    new Text(
                      '${entry.getValue()}',
                      textScaleFactor: 1.2,
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
    _onEditSubscription = _dataRef.onChildChanged.listen(_onEntryEdited);
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
              child: new ListItem(entryList[index]));
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

  void _onEntryEdited(Event event) {
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
  final TextEditingController _controllerPin = new TextEditingController();
  final TextEditingController _controllerValue = new TextEditingController();
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
          _controllerPin.text = entry.getPin8().toString();
          _controllerValue.text = entry.getValue24().toString();
          break;
        case 2:
          _controllerValue.text = entry.getValue().toString();
          break;
        case 3:
          _controllerValue.text = entry.getValue();
          break;
        case 4:
          if (entry.getValue() == false) {
            _controllerValue.text = '0';
          } else if (entry.getValue() == true) {
            _controllerValue.text = '1';
          } else {
            print('_controllerValue.text error');
            _controllerValue.text = '0';
          }
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
                  _selectedType, _controllerPin, _controllerValue),
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
              new Checkbox(
                  value: _checkboxValueWr,
                  onChanged: (bool value) {
                    setState(() {
                      _checkboxValueWr = value;
                    });
                  }),
              new Checkbox(
                  value: _checkboxValueRd,
                  onChanged: (bool value) {
                    setState(() {
                      _checkboxValueRd = value;
                    });
                  }),
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
                      entry.setPin8(int.parse(_controllerPin.text));
                      entry.setValue24(int.parse(_controllerValue.text));
                      break;
                    case 2:
                      entry.setValue(int.parse(_controllerValue.text));
                      break;
                    case 3:
                    case 4:
                      if (_controllerValue.text == '0') {
                        entry.setValue(false);
                      } else if (_controllerValue.text == '1') {
                        entry.setValue(true);
                      } else {
                        print('_controllerValue.text error');
                      }
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

class DynamicEditWidget extends StatelessWidget {
  final int type;
  final TextEditingController pin;
  final TextEditingController value;

  DynamicEditWidget(this.type, this.pin, this.value);

  @override
  Widget build(BuildContext context) {
    switch (getMode(type)) {
      case 1:
        return new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new TextField(
                controller: pin,
                keyboardType: TextInputType.number,
                decoration: new InputDecoration(
                  hintText: 'pin value',
                ),
              ),
              new TextField(
                controller: value,
                keyboardType: TextInputType.number,
                decoration: new InputDecoration(
                  hintText: 'data value',
                ),
              ),
            ]);
        break;
      case 2:
        return new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new TextField(
                controller: value,
                keyboardType: TextInputType.number,
                decoration: new InputDecoration(
                  hintText: 'value',
                ),
              ),
            ]);
        break;
      case 3:
        return new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new TextField(
                controller: value,
                decoration: new InputDecoration(
                  hintText: 'value',
                ),
              ),
            ]);
      case 4:
        return new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new TextField(
                controller: value,
                keyboardType: TextInputType.number,
                decoration: new InputDecoration(
                  hintText: 'value',
                ),
              ),
            ]);
        break;
      default:
        return new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new Text(''),
            ]);
    }
  }
}
