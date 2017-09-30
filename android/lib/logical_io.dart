import 'package:flutter/material.dart';
import 'drawer.dart';

class LogicalIO extends StatefulWidget {
  LogicalIO({Key key, this.title}) : super(key: key);

  static const String routeName = '/logical_io';

  final String title;

  @override
  LogicalIOState createState() => new LogicalIOState();
}

class LogicalIOState extends State<LogicalIO> {
  @override
  void initState() {
    super.initState();
    print('LogicalIOState');
  }

  @override
  void dispose() {
    super.dispose();
  }
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
