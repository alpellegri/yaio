import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'entries.dart';
import 'firebase_utils.dart';
import 'ui_data_io.dart';

class DataIO extends StatefulWidget {
  final String domain;
  final String node;

  const DataIO({
    super.key,
    required this.domain,
    required this.node,
  });

  @override
  _DataIOState createState() => _DataIOState();
}

class _DataIOState extends State<DataIO> {
  List<IoEntry> entryList = [];
  late DatabaseReference _dataRef;
  late StreamSubscription<DatabaseEvent> _onAddSubscription;
  late StreamSubscription<DatabaseEvent> _onEditSubscription;
  late StreamSubscription<DatabaseEvent> _onRemoveSubscription;

  @override
  void initState() {
    super.initState();
    _dataRef = FirebaseDatabase.instance
        .ref()
        .child(getUserRef()!)
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
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          crossAxisCount:
              (MediaQuery.of(context).orientation == Orientation.portrait)
                  ? 3
                  : 5,
          childAspectRatio: 2,
        ),
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        itemCount: entryList.length,
        itemBuilder: (buildContext, index) {
          return InkWell(
              onTap: () => _openEntryEdit(entryList[index]),
              child: DataItemWidget(entry: entryList[index]));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFloatingActionButtonPressed,
        tooltip: 'add',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _onEntryAdded(DatabaseEvent event) {
    dynamic v = event.snapshot.value;
    String? owner = v['owner'];
    if (owner == widget.node) {
      setState(() {
        IoEntry entry =
            IoEntry.fromMap(_dataRef, event.snapshot.key, event.snapshot.value);
        entryList.add(entry);
      });
    }
  }

  void _onEntryChanged(DatabaseEvent event) {
    print('_onEntryChanged');
    dynamic v = event.snapshot.value;
    String? owner = v['owner'];
    if (owner == widget.node) {
      IoEntry oldValue =
          entryList.singleWhere((el) => el.key == event.snapshot.key);
      setState(() {
        entryList[entryList.indexOf(oldValue)] =
            IoEntry.fromMap(_dataRef, event.snapshot.key, event.snapshot.value);
      });
    }
  }

  void _onEntryRemoved(DatabaseEvent event) {
    dynamic v = event.snapshot.value;
    String? owner = v['owner'];
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
          builder: (BuildContext context) => DataEditScreen(
              domain: widget.domain, node: widget.node, entry: entry),
          fullscreenDialog: true,
        ));
  }

  void _onFloatingActionButtonPressed() {
    final IoEntry entry = IoEntry.setReference(_dataRef);
    _openEntryEdit(entry);
  }
}

class DataEditScreen extends StatefulWidget {
  final String domain;
  final String node;
  final IoEntry entry;

  const DataEditScreen({
    super.key,
    required this.domain,
    required this.node,
    required this.entry,
  });

  @override
  _DataEditScreenState createState() => _DataEditScreenState();
}

class _DataEditScreenState extends State<DataEditScreen> {
  late DatabaseReference _execRef;
  final List<ExecEntry> _execList = [];
  final List<int> _opTypeMenu = [];

  final TextEditingController _controllerName = TextEditingController();
  final TextEditingController _controllerType = TextEditingController();
  String? _selectedExec;
  late StreamSubscription<DatabaseEvent> _onValueExecSubscription;
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
        .ref()
        .child(getUserRef()!)
        .child('obj/exec')
        .child(widget.domain)
        .child(widget.node);
    _onValueExecSubscription = _execRef.onValue.listen(_onValueExec);
    if (widget.entry.value != null) {
      _controllerName.text = widget.entry.key!;
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
          title: Text((widget.entry.key != null) ? widget.entry.key! : 'Data'),
          actions: <Widget>[
            TextButton(
                child: const Text(
                  'REMOVE',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  FirebaseDatabase.instance
                      .ref()
                      .child(getUserRef()!)
                      .child('obj/logs')
                      .child(widget.domain)
                      .child(widget.entry.key!)
                      .remove();
                  if (widget.entry.exist == true) {
                    widget.entry.reference.child(widget.entry.key!).remove();
                  }
                  Navigator.pop(context, null);
                }),
            TextButton(
                child: const Text(
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
                      widget.entry.owner = widget.node;
                      widget.entry.reference
                          .child(widget.entry.key!)
                          .set(widget.entry.toJson());
                    } else {
                      print('error missing');
                    }
                  } catch (exception) {
                    print('bug');
                  }
                  Navigator.pop(context, null);
                }),
          ]),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(8.0),
          alignment: Alignment.bottomLeft,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: _controllerName,
                  decoration: const InputDecoration(
                    hintText: 'name',
                    labelText: 'Name',
                  ),
                ),
                Row(children: [
                  const Expanded(
                    child: Text('Data Type'),
                  ),
                  DropdownButton<int>(
                    hint: const Text('select'),
                    value: widget.entry.code,
                    onChanged: (int? newValue) {
                      setState(() {
                        widget.entry.code = newValue;
                      });
                    },
                    items: _opTypeMenu.map((int entry) {
                      return DropdownMenuItem<int>(
                        value: entry,
                        child: Text(
                          kEntryId2Name[DataCode.values[entry]]!,
                        ),
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
                    : const Text('routine empty'),
                ListTile(
                  title: const Text('Enable on Google Home'),
                  leading: Checkbox(
                      value: widget.entry.aog,
                      onChanged: (bool? value) {
                        setState(() {
                          widget.entry.aog = value!;
                        });
                      }),
                ),
                ListTile(
                  title: const Text('On Dashboard Write Mode'),
                  leading: Checkbox(
                      value: widget.entry.drawWr,
                      onChanged: (bool? value) {
                        setState(() {
                          widget.entry.drawWr = value!;
                        });
                      }),
                ),
                ListTile(
                  title: const Text('On Dashboard Read Mode'),
                  leading: Checkbox(
                      value: widget.entry.drawRd,
                      onChanged: (bool? value) {
                        setState(() {
                          widget.entry.drawRd = value!;
                        });
                      }),
                ),
                ListTile(
                  title: const Text('Enable Logs'),
                  leading: Checkbox(
                      value: widget.entry.enLog,
                      onChanged: (bool? value) {
                        setState(() {
                          widget.entry.enLog = value!;
                        });
                      }),
                ),
              ]),
        ),
      ),
    );
  }

  void _onValueExec(DatabaseEvent event) {
    // print('_onValueExec');
    dynamic data = event.snapshot.value;
    // print('node: ${widget.node}');
    if ((data != null) && (widget.entry.cb != null)) {
      /* clear list menu */
      _execStringList.clear();
      /* take all routines */
      data.forEach((k, v) {
        // print('key: $k - value: ${v.toString()}');
        // filter only relative to the domain
        String owner = v["owner"];
        if (owner == widget.node) {
          ExecEntry e = ExecEntry.fromMap(_execRef, k, v);
          _execList.add(e);
          _execStringList.add(e.key!);
        }
      });
      if (_execStringList.contains(widget.entry.cb)) {
        setState(() {});
        _execStringList.add('');
        _selectedExec = widget.entry.cb;
      }
    }
  }
}
