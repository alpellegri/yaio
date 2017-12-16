import 'dart:async';

import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'drawer.dart';
import 'entries.dart';
import 'firebase_utils.dart';

class LogListItem extends StatelessWidget {
  final LogEntry logEntry;

  LogListItem(this.logEntry);

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: new EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
      child: new Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          new Expanded(
            child: new Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Column(
                  children: [
                    new Text(
                      new DateFormat('d/M/y').format(logEntry.dateTime),
                      textScaleFactor: 1.0,
                    ),
                    new Text(
                      new DateFormat('Hm').format(logEntry.dateTime),
                      textScaleFactor: 1.0,
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
          new Text(
            logEntry.message.toString(),
            textScaleFactor: 1.0,
          ),
        ],
      ),
    );
  }
}

class LogHistory extends StatefulWidget {
  LogHistory({Key key, this.title}) : super(key: key);

  static const String routeName = '/log_history';

  final String title;

  @override
  _LogHistoryState createState() => new _LogHistoryState();
}

class _LogHistoryState extends State<LogHistory> {
  List<LogEntry> entryList = new List();
  DatabaseReference _entryRef;
  StreamSubscription<Event> _onAddSub;
  StreamSubscription<Event> _onRemoveSub;

  _LogHistoryState() {
    _entryRef = FirebaseDatabase.instance.reference().child(dLogsReportsRef);
    _onAddSub = _entryRef.onChildAdded.listen(_onEntryAdded);
    _onRemoveSub = _entryRef.onChildRemoved.listen(_onEntryRemoved);
  }

  @override
  void initState() {
    super.initState();
    print('_LogHistoryState');
  }

  @override
  void dispose() {
    super.dispose();
    _onAddSub.cancel();
    _onRemoveSub.cancel();
  }

  @override
  Widget build(BuildContext context) {
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
          //calculating difference
          return new InkWell(
              // onTap: () => _openEditEntryDialog(logSaves[index]),
              child: new LogListItem(entryList[index]));
        },
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _onFloatingActionButtonPressed,
        tooltip: 'remove all',
        child: new Icon(Icons.delete),
      ),
    );
  }

  _onEntryAdded(Event event) {
    print('_onEntryAdded');
    setState(() {
      entryList.add(new LogEntry.fromSnapshot(event.snapshot));
      entryList.sort((e1, e2) => e1.dateTime.compareTo(e2.dateTime));
    });
  }

  _onEntryRemoved(Event event) {
    print('_onEntryRemoved');
    var oldValue =
        entryList.singleWhere((entry) => entry.key == event.snapshot.key);

    setState(() {
      entryList.remove(oldValue);
      entryList.sort((e1, e2) => e1.dateTime.compareTo(e2.dateTime));
    });
  }

  void _onFloatingActionButtonPressed() {
    _entryRef.remove();
  }
}
