import 'package:flutter/material.dart';
import 'drawer.dart';

class Timer extends StatefulWidget {
  Timer({Key key, this.title}) : super(key: key);

  static const String routeName = '/timer';

  final String title;

  @override
  _TimerState createState() => new _TimerState();
}

class _TimerState extends State<Timer> {
  @override
  void initState() {
    super.initState();
    print('_TimerState');
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
