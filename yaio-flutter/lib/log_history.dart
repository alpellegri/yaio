import 'dart:async';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'entries.dart';
import 'firebase_utils.dart';

class LogListItem extends StatelessWidget {
  final MessageEntry message;

  const LogListItem({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.only(right: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      DateFormat('dd/MM/yy').format(message.dateTime),
                      // textScaleFactor: 1.0,
                    ),
                    Text(
                      DateFormat('Hm').format(message.dateTime),
                      // textScaleFactor: 1.0,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${message.domain.toString()}/${message.node.toString()}',
                    // textScaleFactor: 1.0,
                  ),
                  Text(
                    message.message.toString(),
                    // textScaleFactor: 0.8,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Messages extends StatefulWidget {
  const Messages({
    super.key,
    required this.title,
  });
  static const String routeName = '/log_history';
  final String title;

  @override
  _MessagesState createState() => _MessagesState();
}

class _MessagesState extends State<Messages> {
  List<MessageEntry> entryList = [];
  late DatabaseReference _entryRef;
  late StreamSubscription<DatabaseEvent> _onAddSub;
  late StreamSubscription<DatabaseEvent> _onRemoveSub;

  _MessagesState() {
    _entryRef = FirebaseDatabase.instance.ref().child(getMessagesRef()!);
    _onAddSub = _entryRef.onChildAdded.listen(_onEntryAdded);
    _onRemoveSub = _entryRef.onChildRemoved.listen(_onEntryRemoved);
  }

  @override
  void initState() {
    super.initState();
    print('_MessagesState');
  }

  @override
  void dispose() {
    super.dispose();
    _onAddSub.cancel();
    _onRemoveSub.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title}'),
      ),
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        shrinkWrap: true,
        reverse: true,
        itemCount: entryList.length,
        itemBuilder: (buildContext, index) {
          //calculating difference
          return InkWell(
              // onTap: () => _openEditEntryDialog(logSaves[index]),
              child: LogListItem(message: entryList[index]));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFloatingActionButtonPressed,
        tooltip: 'remove all',
        child: const Icon(Icons.delete),
      ),
    );
  }

  _onEntryAdded(DatabaseEvent event) {
    print('_onEntryAdded');
    setState(() {
      entryList.add(MessageEntry.fromSnapshot(event.snapshot));
      entryList.sort((e1, e2) => e1.dateTime.compareTo(e2.dateTime));
    });
  }

  _onEntryRemoved(DatabaseEvent event) {
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
