import 'dart:async';
import 'package:flutter/material.dart';
import 'drawer.dart';
import 'entries.dart';

class ExecProgListItem extends StatelessWidget {
  final InstrEntry entry;

  ExecProgListItem(this.entry);

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
                      'opcode: ${entry.i} value: ${entry.v}',
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
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

class ExecProg extends StatefulWidget {
  static const String routeName = '/exec_prog';
  final String title;
  final List<InstrEntry> prog;

  ExecProg({Key key, this.title, this.prog}) : super(key: key);

  @override
  _ExecProgState createState() => new _ExecProgState(prog);
}

class _ExecProgState extends State<ExecProg> {
  final List<InstrEntry> prog;

  _ExecProgState(this.prog);

  @override
  void initState() {
    super.initState();
    print('_ExecProgState');
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      drawer: drawer,
      appBar: new AppBar(
          // title: new Text(widget.title),
          ),
      body: new ListView.builder(
        shrinkWrap: true,
        reverse: true,
        itemCount: prog.length,
        itemBuilder: (buildContext, index) {
          return new InkWell(
              // onTap: () => _openEntryDialog(entryList[index]),
              child: new ExecProgListItem(prog[index]));
        },
      ),
    );
  }
}
