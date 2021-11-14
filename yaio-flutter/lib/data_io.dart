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
  _DataIOState createState() => new _DataIOState();
}

class _DataIOState extends State<DataIO> {
  List<IoEntry> entryList = [];
  DatabaseReference _dataRef;
  StreamSubscription<Event> _onAddSubscription;
  StreamSubscription<Event> _onEditSubscription;
  StreamSubscription<Event> _onRemoveSubscription;

  @override
  void initState() {
    super.initState();
    _dataRef = FirebaseDatabase.instance
        .reference()
        .child(getUserRef())
        .child('obj/data')
        .child(widget.domain);
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Data IO ${widget.domain}/${widget.node}'),
      ),
      body: ListView.builder(
        shrinkWrap: true,
        physics: BouncingScrollPhysics(),
        itemCount: entryList.length,
        itemBuilder: (buildContext, index) {
          return InkWell(
              onTap: () => _openEntryEdit(entryList[index]),
              child: DataItemWidget(entryList[index]));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFloatingActionButtonPressed,
        tooltip: 'add',
        child: Icon(Icons.add),
      ),
    );
  }

  void _onEntryAdded(Event event) {
    String owner = event.snapshot.value["owner"];
    if (owner == widget.node) {
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
    if (owner == widget.node) {
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
    if (owner == widget.node) {
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
        MaterialPageRoute(
          builder: (BuildContext context) => new DataEditScreen(
              domain: widget.domain, node: widget.node, entry: entry),
          fullscreenDialog: true,
        ));
  }

  void _onFloatingActionButtonPressed() {
    final IoEntry entry = new IoEntry.setReference(_dataRef);
    entry.setOwner(widget.node);
    _openEntryEdit(entry);
  }
}

class DataEditScreen extends StatefulWidget {
  final String domain;
  final String node;
  final IoEntry entry;

  DataEditScreen({this.domain, this.node, this.entry});

  @override
  _DataEditScreenState createState() => new _DataEditScreenState();
}

class _DataEditScreenState extends State<DataEditScreen> {
  DatabaseReference _execRef;
  List<ExecEntry> _execList = [];
  List<int> _opTypeMenu = [];

  final TextEditingController _controllerName = new TextEditingController();
  final TextEditingController _controllerType = new TextEditingController();
  String _selectedExec;
  StreamSubscription<Event> _onValueExecSubscription;
  List<String> _execStringList = [];

  void _handleChangedValue(IoEntry newValue) {
    setState(() {
      widget.entry.value = newValue.value;
      widget.entry.ioctl = newValue.ioctl;
    });
  }

  @override
  void initState() {
    super.initState();
    print('domain ${widget.domain}');
    _execRef = FirebaseDatabase.instance
        .reference()
        .child(getUserRef())
        .child('obj/exec')
        .child(widget.domain)
        .child(widget.node);
    _onValueExecSubscription = _execRef.onValue.listen(_onValueExec);
    if (widget.entry.value != null) {
      _controllerName.text = widget.entry.key;
      _controllerType.text = widget.entry.code.toString();
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
    return Scaffold(
      appBar: AppBar(
          title: Text((widget.entry.key != null) ? widget.entry.key : 'Data'),
          actions: <Widget>[
            TextButton(
                child: Text(
                  'REMOVE',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  FirebaseDatabase.instance
                      .reference()
                      .child(getUserRef())
                      .child('obj/logs')
                      .child(widget.domain)
                      .child(widget.entry.key)
                      ?.remove();
                  if (widget.entry.exist == true) {
                    widget.entry.reference.child(widget.entry.key)?.remove();
                  }
                  Navigator.pop(context, null);
                }),
            TextButton(
                child: Text(
                  'SAVE',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  widget.entry.key = _controllerName.text;
                  try {
                    if (_selectedExec != '') {
                      widget.entry.cb = _selectedExec;
                    } else {
                      widget.entry.cb = null;
                    }
                    // entry.setOwner(getOwner());
                    if (widget.entry.value != null) {
                      print('saving');
                      widget.entry.reference
                          .child(widget.entry.key)
                          .set(widget.entry.toJson());
                    } else {
                      print('missing');
                    }
                  } catch (exception) {
                    print('bug');
                  }
                  Navigator.pop(context, null);
                }),
          ]),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(8.0),
          alignment: Alignment.bottomLeft,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: _controllerName,
                  decoration: InputDecoration(
                    hintText: 'name',
                    labelText: 'Name',
                  ),
                ),
                Row(children: [
                  Expanded(
                    child: Text('Data Type'),
                  ),
                  DropdownButton<int>(
                    hint: Text('select'),
                    value: widget.entry.code,
                    onChanged: (int newValue) {
                      setState(() {
                        widget.entry.code = newValue;
                      });
                    },
                    items: _opTypeMenu.map((int entry) {
                      return DropdownMenuItem<int>(
                        value: entry,
                        child: Text(kEntryId2Name[DataCode.values[entry]]),
                      );
                    }).toList(),
                  ),
                ]),
                (widget.entry.code != null)
                    ? (DataConfigWidget(
                        data: widget.entry,
                        onChangedValue: _handleChangedValue,
                      ))
                    : (Container()),
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
                    : Text('routine empty'),
                ListTile(
                  title: Text('Enable on Google Home'),
                  leading: Checkbox(
                      value: widget.entry.aog,
                      onChanged: (bool value) {
                        setState(() {
                          widget.entry.aog = value;
                        });
                      }),
                ),
                ListTile(
                  title: Text('On Dashboard Write Mode'),
                  leading: Checkbox(
                      value: widget.entry.drawWr,
                      onChanged: (bool value) {
                        setState(() {
                          widget.entry.drawWr = value;
                        });
                      }),
                ),
                ListTile(
                  title: Text('On Dashboard Read Mode'),
                  leading: Checkbox(
                      value: widget.entry.drawRd,
                      onChanged: (bool value) {
                        setState(() {
                          widget.entry.drawRd = value;
                        });
                      }),
                ),
                ListTile(
                  title: Text('Enable Logs'),
                  leading: Checkbox(
                      value: widget.entry.enLog,
                      onChanged: (bool value) {
                        setState(() {
                          widget.entry.enLog = value;
                        });
                      }),
                ),
              ]),
        ),
      ),
    );
  }

  void _onValueExec(Event event) {
    // print('_onValueExec');
    Map data = event.snapshot.value;
    // print('node: $node');
    if (data != null) {
      data.forEach((k, v) {
        // print('key: $k - value: ${v.toString()}');
        // filter only relative to the domain
        String owner = v["owner"];
        if (owner == widget.node) {
          ExecEntry e = new ExecEntry.fromMap(_execRef, k, v);
          _execList.add(e);
          _execStringList = _execList.map((e) => e.key).toList();
          setState(() {
            _execStringList.add('');
            _selectedExec = _execStringList.firstWhere(
              (el) => el == widget.entry.cb,
              orElse: () => null,
            );
          });
        }
      });
    }
  }
}
