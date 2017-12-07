import 'package:flutter/material.dart';
import 'drawer.dart';

class ChartHistory extends StatefulWidget {
  ChartHistory({Key key, this.title}) : super(key: key);

  static const String routeName = '/chart_history';

  final String title;

  @override
  _ChartHistory createState() => new _ChartHistory();
}

class _ChartHistory extends State<ChartHistory> {
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
