import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'entries.dart';
import 'firebase_utils.dart';
import 'ui_data_io.dart';

class DataIO extends StatefulWidget {
  final String domain;
  final String node;

  DataIO({Key key, this.domain, this.node}) : super(key: key);

  @override
  _DataIOState createState() => new _DataIOState(domain, node);
}

class _DataIOState extends State<DataIO> {
  final String domain;
  final String node;
  List<IoEntry> entryList = new List();
  DatabaseReference _dataRef;
  StreamSubscription<Event> _onAddSubscription;
  StreamSubscription<Event> _onEditSubscription;
  StreamSubscription<Event> _onRemoveSubscription;

  _DataIOState(this.domain, this.node);

  @override
  void initState() {
    super.initState();
    _dataRef = FirebaseDatabase.instance
        .reference()
        .child(getUserRef())
        .child('obj/data')
        .child(domain);
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
      appBar: new AppBar(
        title: new Text('Data IO $domain/$node'),
      ),
      body: new ListView.builder(
        shrinkWrap: true,
        itemCount: entryList.length,
        itemBuilder: (buildContext, index) {
          return new InkWell(
              onTap: () => _openEntryEdit(entryList[index]),
              child: new DataItemWidget(entryList[index]));
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
    if (owner == node) {
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
    if (owner == node) {
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
    if (owner == node) {
      IoEntry oldValue =
          entryList.singleWhere((el) => el.key == event.snapshot.key);
      setState(() {
        entryList.remove(oldValue);
      });
    }
  }

  void _openEntryEdit(IoEntry entry) {
    Navigator.push(
        context,
        new MaterialPageRoute(
          builder: (BuildContext context) =>
              new DataEditScreen(domain: domain, node: node, entry: entry),
          fullscreenDialog: true,
        ));
  }

  void _onFloatingActionButtonPressed() {
    final IoEntry entry = new IoEntry.setReference(_dataRef);
    entry.setOwner(node);
    _openEntryEdit(entry);
  }
}

class DataEditScreen extends StatefulWidget {
  final String domain;
  final String node;
  final IoEntry entry;

  DataEditScreen({this.domain, this.node, this.entry});

  @override
  _DataEditScreenState createState() =>
      new _DataEditScreenState(domain, node, entry);
}

class _DataEditScreenState extends State<DataEditScreen> {
  final String domain;
  final String node;
  final IoEntry entry;
  DatabaseReference _execRef;
  List<ExecEntry> _execList = new List();
  List<int> _opTypeMenu = new List<int>();

  final TextEditingController _controllerName = new TextEditingController();
  final TextEditingController _controllerType = new TextEditingController();
  ExecEntry _selectedExec;
  StreamSubscription<Event> _onValueExecSubscription;

  _DataEditScreenState(this.domain, this.node, this.entry);

  void _handleChangedValue(IoEntry newValue) {
    setState(() {
      entry.value = newValue.value;
      entry.ioctl = newValue.ioctl;
    });
  }

  @override
  void initState() {
    super.initState();
    print('domain $domain');
    _execRef = FirebaseDatabase.instance
        .reference()
        .child(getUserRef())
        .child('obj/exec')
        .child(domain).child(node);
    _onValueExecSubscription = _execRef.onValue.listen(_onValueExec);
    if (entry.value != null) {
      _controllerName.text = entry.key;
      _controllerType.text = entry.code.toString();
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
    return new Scaffold(
      appBar: new AppBar(
          title: new Text((entry.key != null) ? entry.key : 'Data'),
          actions: <Widget>[
            new FlatButton(
                child: const Text(
                  'REMOVE',
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  if (entry.exist == true) {
                    entry.reference.child(entry.key).remove();
                  }
                  Navigator.pop(context, null);
                }),
            new FlatButton(
                child: const Text(
                  'SAVE',
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  entry.key = _controllerName.text;
                  try {
                    entry.cb = _selectedExec?.key;
                    // entry.setOwner(getOwner());
                    if (entry.value != null) {
                      print('saving');
                      entry.reference.child(entry.key).set(entry.toJson());
                    } else {
                      print('missing');
                    }
                  } catch (exception) {
                    print('bug');
                  }
                  Navigator.pop(context, null);
                }),
          ]),
      body: new SingleChildScrollView(
        child: new Container(
          padding: const EdgeInsets.all(8.0),
          alignment: Alignment.bottomLeft,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                new TextField(
                  controller: _controllerName,
                  decoration: const InputDecoration(
                    hintText: 'name',
                    labelText: 'Name',
                  ),
                ),
                new Row(children: [
                  new Expanded(
                    child: const Text('Data Type'),
                  ),
                  new DropdownButton<int>(
                    hint: const Text('select'),
                    value: entry.code,
                    onChanged: (int newValue) {
                      setState(() {
                        entry.code = newValue;
                      });
                    },
                    items: _opTypeMenu.map((int entry) {
                      return new DropdownMenuItem<int>(
                        value: entry,
                        child: new Text(kEntryId2Name[DataCode.values[entry]]),
                      );
                    }).toList(),
                  ),
                ]),
                (entry.code != null)
                    ? (new DataConfigWidget(
                        data: entry,
                        onChangedValue: _handleChangedValue,
                      ))
                    : (const Text('')),
                (_execList.length > 0)
                    ? new ListTile(
                        title: const Text('Callback Routine'),
                        trailing: new DropdownButton<ExecEntry>(
                          hint: const Text('Select'),
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
                    : const Text('routine empty'),
                new ListTile(
                  title: const Text('Enable on Google Home'),
                  leading: new Checkbox(
                      value: entry.aog,
                      onChanged: (bool value) {
                        setState(() {
                          entry.aog = value;
                        });
                      }),
                ),
                new ListTile(
                  title: const Text('On Dashboard Write Mode'),
                  leading: new Checkbox(
                      value: entry.drawWr,
                      onChanged: (bool value) {
                        setState(() {
                          entry.drawWr = value;
                        });
                      }),
                ),
                new ListTile(
                  title: const Text('On Dashboard Read Mode'),
                  leading: new Checkbox(
                      value: entry.drawRd,
                      onChanged: (bool value) {
                        setState(() {
                          entry.drawRd = value;
                        });
                      }),
                ),
                new ListTile(
                  title: const Text('Enable Logs'),
                  leading: new Checkbox(
                      value: entry.enLog,
                      onChanged: (bool value) {
                        setState(() {
                          entry.enLog = value;
                        });
                      }),
                ),
              ]),
        ),
      ),
    );
  }

  void _onValueExec(Event event) {
    print('_onValueExec');
    Map data = event.snapshot.value;
    print('node: $node');
    if (data != null) {
      data.forEach((k, v) {
        print('key: $k - value: ${v.toString()}');
        // filter only relative to the domain
        String owner = v["owner"];
        if (owner == node) {
          setState(() {
            ExecEntry e = new ExecEntry.fromMap(_execRef, k, v);
            _execList.add(e);
            print('************');
            if (entry.cb == e.key) {
              _selectedExec = e;
            }
          });
        }
      });
    }
  }
}
