import 'package:flutter/material.dart';
import 'drawer.dart';

class StatusPage extends StatefulWidget {
  StatusPage({Key key, this.title}) : super(key: key);

  static const String routeName = '/chart_history';

  final String title;

  @override
  _StatusPage createState() => new _StatusPage();
}

class _StatusPage extends State<StatusPage> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      drawer: drawer,
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new Container(),
      floatingActionButton: new FloatingActionButton(
        onPressed: _onFloatingActionButtonPressed,
        tooltip: 'add',
        child: new Icon(Icons.add),
      ),
    );
  }

  void _onFloatingActionButtonPressed() {}
}
