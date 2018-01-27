import 'dart:async';
import 'package:flutter/material.dart';
import 'drawer.dart';
import 'entries.dart';

class ExecProg extends StatefulWidget {
  static const String routeName = '/exec_prog';
  final String title;
  final List<InstrEntry> p;
  ExecProg({Key key, this.title, this.p}) : super(key: key);

  @override
  _ExecProgState createState() => new _ExecProgState(p);
}

class _ExecProgState extends State<ExecProg> {
  final List<InstrEntry> p;
  _ExecProgState(this.p);

  @override
  void initState() {
    super.initState();
    print('_ExecState');
  }

  @override
  Widget build(BuildContext context) {
    p.forEach((e) => print('$e.i $e.v'));
    return new Scaffold(
      drawer: drawer,
      appBar: new AppBar(
        // title: new Text(widget.title),
      ),
      body: new Text('hi'),
    );
  }
}
