import 'package:flutter/material.dart';
import 'node_setup.dart';
import 'radiocode.dart';
import 'timer.dart';
import 'digital_io.dart';
import 'logical_io.dart';
import 'functions.dart';
import 'log_history.dart';
import 'chart_history.dart';

final MyDrawer drawer = new MyDrawer();

final Map<String, WidgetBuilder> menuRoutes = <String, WidgetBuilder>{
  NodeSetup.routeName: (BuildContext context) =>
      new NodeSetup(title: 'NodeSetup'),
  DigitalIO.routeName: (BuildContext context) =>
      new DigitalIO(title: 'DigitalIO'),
  LogicalIO.routeName: (BuildContext context) =>
      new LogicalIO(title: 'LogicalIO'),
  RadioCode.routeName: (BuildContext context) =>
      new RadioCode(title: 'RadioCode'),
  Functions.routeName: (BuildContext context) =>
      new Functions(title: 'Functions'),
  Timer.routeName: (BuildContext context) => new Timer(title: 'Timer'),
  LogHistory.routeName: (BuildContext context) =>
      new LogHistory(title: 'Log History'),
  ChartHistory.routeName: (BuildContext context) =>
      new ChartHistory(title: 'Chart History'),
};

class MyDrawer extends StatefulWidget {
  @override
  _MyDrawerState createState() => new _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  @override
  Widget build(BuildContext context) {
    return new Drawer(
      child: new ListView(children: <Widget>[
        new DrawerHeader(child: new Text('Header')),
        new ListTile(
            leading: new Icon(Icons.developer_board),
            title: new Text('NodeSetup'),
            onTap: () {
              Navigator.of(context)
                ..pop()
                ..pushNamed(NodeSetup.routeName);
            }),
        new ListTile(
            leading: new Icon(Icons.label_outline),
            title: new Text('DigitalIO'),
            onTap: () {
              Navigator.of(context)
                ..pop()
                ..pushNamed(DigitalIO.routeName);
            }),
        new ListTile(
            leading: new Icon(Icons.label_outline),
            title: new Text('LogicalIO'),
            onTap: () {
              Navigator.of(context)
                ..pop()
                ..pushNamed(LogicalIO.routeName);
            }),
        new ListTile(
            leading: new Icon(Icons.settings_input_antenna),
            title: new Text('RadioCode'),
            onTap: () {
              Navigator.of(context)
                ..pop()
                ..pushNamed(RadioCode.routeName);
            }),
        new ListTile(
            leading: new Icon(Icons.functions),
            title: new Text('Functions'),
            onTap: () {
              Navigator.of(context)
                ..pop()
                ..pushNamed(Functions.routeName);
            }),
        new ListTile(
            leading: new Icon(Icons.alarm),
            title: new Text('Timer'),
            onTap: () {
              Navigator.of(context)
                ..pop()
                ..pushNamed(Timer.routeName);
            }),
        new ListTile(
            leading: new Icon(Icons.message),
            title: new Text('LogHistory'),
            onTap: () {
              Navigator.of(context)
                ..pop()
                ..pushNamed(LogHistory.routeName);
            }),
        new ListTile(
            leading: new Icon(Icons.show_chart),
            title: new Text('ChartHistory'),
            onTap: () {
              Navigator.of(context)
                ..pop()
                ..pushNamed(ChartHistory.routeName);
            }),
      ]),
    );
  }
}
