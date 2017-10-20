import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'drawer.dart';

class LogEntry {
  String key;
  DateTime dateTime;
  String message;

  LogEntry(this.dateTime, this.message);

  LogEntry.fromSnapshot(DataSnapshot snapshot)
      : key = snapshot.key,
        dateTime = new DateTime.fromMillisecondsSinceEpoch(
            snapshot.value["time"] * 1000),
        message = snapshot.value["msg"];

  toJson() {
    return {
      "message": message,
      "date": dateTime.millisecondsSinceEpoch,
    };
  }
}

class LogListItem extends StatelessWidget {
  final LogEntry logEntry;

  LogListItem(this.logEntry);

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
                      new DateFormat.MMMEd().format(logEntry.dateTime),
                      textScaleFactor: 0.9,
                      textAlign: TextAlign.left,
                    ),
                    new Text(
                      new TimeOfDay.fromDateTime(logEntry.dateTime).toString(),
                      textScaleFactor: 0.8,
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
          new Text(
            logEntry.message.toString(),
            textScaleFactor: 1.3,
            textAlign: TextAlign.left,
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
  List<LogEntry> logSaves = new List();
  DatabaseReference _logReference;

  _LogHistoryState() {
    _logReference =
        FirebaseDatabase.instance.reference().child("logs").child("Reports");
    _logReference.onChildAdded.listen(_onEntryAdded);
    _logReference.onChildRemoved.listen(_onEntryRemoved);
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
        itemCount: logSaves.length,
        itemBuilder: (buildContext, index) {
          //calculating difference
          return new InkWell(
              // onTap: () => _openEditEntryDialog(logSaves[index]),
              child: new LogListItem(logSaves[index]));
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
      logSaves.add(new LogEntry.fromSnapshot(event.snapshot));
      logSaves.sort((e1, e2) => e1.dateTime.compareTo(e2.dateTime));
    });
  }

  _onEntryRemoved(Event event) {
    print('_onEntryRemoved');
    var oldValue =
    logSaves.singleWhere((entry) => entry.key == event.snapshot.key);

    setState(() {
      logSaves.remove(oldValue);
      logSaves.sort((e1, e2) => e1.dateTime.compareTo(e2.dateTime));
    });
  }

  void _onFloatingActionButtonPressed() {
    _logReference.remove();
  }
}
