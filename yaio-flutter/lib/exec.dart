import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'entries.dart';
import 'firebase_utils.dart';
import 'exec_edit.dart';

class ExecListItem extends StatelessWidget {
  final ExecEntry entry;

  const ExecListItem({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        // alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).primaryColorLight,
        ),
        child: Stack(
          children: <Widget>[
            Container(
              // alignment: Alignment.centerLeft,
              width: 4,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8)),
                color: Theme.of(context).primaryColor,
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
              child: Text('${entry.key}', textAlign: TextAlign.left),
            )
          ],
        ));
  }
}

class Exec extends StatefulWidget {
  final String domain;
  final String node;

  const Exec({
    super.key,
    required this.domain,
    required this.node,
  });

  @override
  _ExecState createState() => _ExecState();
}

class _ExecState extends State<Exec> {
  List<ExecEntry> entryList = [];
  late DatabaseReference _entryRef;
  late StreamSubscription<DatabaseEvent> _onAddSubscription;
  late StreamSubscription<DatabaseEvent> _onEditSubscription;
  late StreamSubscription<DatabaseEvent> _onRemoveSubscription;

  @override
  void initState() {
    super.initState();
    _entryRef = FirebaseDatabase.instance
        .ref()
        .child(getUserRef()!)
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Routine ${widget.domain}/${widget.node}'),
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
        reverse: false,
        itemCount: entryList.length,
        itemBuilder: (buildContext, index) {
          return InkWell(
            onTap: () => _openEntryDialog(entryList[index]),
            child: ExecListItem(entry: entryList[index]),
          );
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
        entryList.add(ExecEntry.fromMap(
            _entryRef, event.snapshot.key!, event.snapshot.value));
      });
    }
  }

  void _onEntryEdited(DatabaseEvent event) {
    dynamic v = event.snapshot.value;
    String? owner = v['owner'];
    if (owner == widget.node) {
      ExecEntry oldValue =
          entryList.singleWhere((el) => el.key == event.snapshot.key);
      setState(() {
        entryList[entryList.indexOf(oldValue)] = ExecEntry.fromMap(
            _entryRef, event.snapshot.key!, event.snapshot.value);
      });
    }
  }

  void _onEntryRemoved(DatabaseEvent event) {
    dynamic v = event.snapshot.value;
    String? owner = v['owner'];
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
        MaterialPageRoute(
          builder: (BuildContext context) => ExecEdit(
            domain: widget.domain,
            node: widget.node,
            entry: entry,
            execList: entryList,
          ),
        ));
  }

  void _onFloatingActionButtonPressed() {
    ExecEntry entry = ExecEntry(_entryRef);
    _openEntryDialog(entry);
  }
}
