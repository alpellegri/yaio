import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'entries.dart';
import 'firebase_utils.dart';
import 'exec_edit.dart';

class ExecListItem extends StatelessWidget {
  final ExecEntry entry;

  ExecListItem(this.entry);

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: new EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
      child: new Text('${entry.key}', textAlign: TextAlign.left),
    );
  }
}

class Exec extends StatefulWidget {
  final String domain;
  final String node;

  Exec({Key key, this.domain, this.node}) : super(key: key);

  @override
  _ExecState createState() => new _ExecState();
}

class _ExecState extends State<Exec> {
  List<ExecEntry> entryList = [];
  DatabaseReference _entryRef;
  StreamSubscription<Event> _onAddSubscription;
  StreamSubscription<Event> _onEditSubscription;
  StreamSubscription<Event> _onRemoveSubscription;

  @override
  void initState() {
    super.initState();
    _entryRef = FirebaseDatabase.instance
        .reference()
        .child(getUserRef())
        .child('obj/exec')
        .child(widget.domain)
        .child(widget.node);
    _onAddSubscription = _entryRef.onChildAdded.listen(_onEntryAdded);
    _onEditSubscription = _entryRef.onChildChanged.listen(_onEntryEdited);
    _onRemoveSubscription = _entryRef.onChildRemoved.listen(_onEntryRemoved);
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
    /* entryList.forEach((e) {
      print('>> ${e.name.toString()}');
      e.p.forEach((f) => print('>> ${f.i.toString()} ${f.v.toString()}'));
    });*/
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Routine ${widget.domain}/${widget.node}'),
      ),
      body: new ListView.builder(
        shrinkWrap: true,
        physics: BouncingScrollPhysics(),
        reverse: true,
        itemCount: entryList.length,
        itemBuilder: (buildContext, index) {
          return new InkWell(
              onTap: () => _openEntryDialog(entryList[index]),
              child: new ExecListItem(entryList[index]));
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
    if (owner == widget.node) {
      setState(() {
        entryList.add(new ExecEntry.fromMap(
            _entryRef, event.snapshot.key, event.snapshot.value));
      });
    }
  }

  void _onEntryEdited(Event event) {
    String owner = event.snapshot.value["owner"];
    if (owner == widget.node) {
      ExecEntry oldValue =
          entryList.singleWhere((el) => el.key == event.snapshot.key);
      setState(() {
        entryList[entryList.indexOf(oldValue)] = new ExecEntry.fromMap(
            _entryRef, event.snapshot.key, event.snapshot.value);
      });
    }
  }

  void _onEntryRemoved(Event event) {
    String owner = event.snapshot.value["owner"];
    if (owner == widget.node) {
      ExecEntry oldValue =
          entryList.singleWhere((el) => el.key == event.snapshot.key);
      setState(() {
        entryList.remove(oldValue);
      });
    }
  }

  void _openEntryDialog(ExecEntry entry) {
    Navigator.push(
        context,
        new MaterialPageRoute(
          builder: (BuildContext context) => new ExecEdit(
              domain: widget.domain,
              node: widget.node,
              entry: entry,
              execList: entryList),
        ));
  }

  void _onFloatingActionButtonPressed() {
    ExecEntry entry = new ExecEntry(_entryRef);
    _openEntryDialog(entry);
  }
}
