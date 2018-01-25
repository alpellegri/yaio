import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'entries.dart';
import 'firebase_utils.dart';

class ExecProg extends StatefulWidget {
  ExecProg({Key key, this.title}) : super(key: key);

  static const String routeName = '/exec_prog';

  final String title;

  @override
  _ExecProgState createState() => new _ExecProgState();
}

class _ExecProgState extends State<ExecProg> {

  @override
  void initState() {
    super.initState();
    print('_ExecState');
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      drawer: drawer,
      appBar: new AppBar(
        // title: new Text(widget.title),
      ),
      body: new Text('hi'),
    );
  }
}
