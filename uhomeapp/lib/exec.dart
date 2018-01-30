import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
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
                      '${entry.name}',
                      textScaleFactor: 1.2,
                      textAlign: TextAlign.left,
                    ),
                    new Text(
                      '',
                      textScaleFactor: 0.8,
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    new Text(
                      '',
                      textScaleFactor: 0.9,
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
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

class Exec extends StatefulWidget {
  Exec({Key key, this.title}) : super(key: key);
  static const String routeName = '/exec';
  final String title;

  @override
  _ExecState createState() => new _ExecState();
}

class _ExecState extends State<Exec> {
  List<ExecEntry> entryList = new List();
  DatabaseReference _entryRef;
  StreamSubscription<Event> _onAddSubscription;
  StreamSubscription<Event> _onEditSubscription;
  StreamSubscription<Event> _onRemoveSubscription;

  _ExecState() {
    _entryRef = FirebaseDatabase.instance.reference().child(getExecRef());
    _onAddSubscription = _entryRef.onChildAdded.listen(_onEntryAdded);
    _onEditSubscription = _entryRef.onChildChanged.listen(_onEntryEdited);
    _onRemoveSubscription = _entryRef.onChildRemoved.listen(_onEntryRemoved);
  }

  @override
  void initState() {
    super.initState();
    print('_ExecState');
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
      drawer: drawer,
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new ListView.builder(
        shrinkWrap: true,
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
    print('_onEntryAdded ${event.snapshot.value.toString()}');
    setState(() {
      entryList.add(new ExecEntry.fromSnapshot(_entryRef, event.snapshot));
    });
  }

  void _onEntryEdited(Event event) {
    ExecEntry oldValue =
        entryList.singleWhere((el) => el.key == event.snapshot.key);
    setState(() {
      entryList[entryList.indexOf(oldValue)] =
          new ExecEntry.fromSnapshot(_entryRef, event.snapshot);
    });
  }

  void _onEntryRemoved(Event event) {
    ExecEntry oldValue =
        entryList.singleWhere((el) => el.key == event.snapshot.key);
    setState(() {
      entryList.remove(oldValue);
    });
  }

  void _openEntryDialog(ExecEntry entry) {
    Navigator.push(
        context,
        new MaterialPageRoute(
          builder: (BuildContext context) =>
              new ExecEdit(entry: entry, execList: entryList),
        ));
  }

  void _onFloatingActionButtonPressed() {
    ExecEntry entry = new ExecEntry(_entryRef);
    _openEntryDialog(entry);
  }
}
