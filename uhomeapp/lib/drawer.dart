import 'package:flutter/material.dart';
import 'home.dart';
import 'setup.dart';
import 'node_setup.dart';
import 'radiocode.dart';
import 'timer.dart';
import 'digital_io.dart';
import 'logical_io.dart';
import 'functions.dart';
import 'log_history.dart';
import 'chart_history.dart';
import 'firebase_utils.dart';

final MyDrawer drawer = new MyDrawer();

final Map<String, WidgetBuilder> menuRoutes = <String, WidgetBuilder>{
  Home.routeName: (BuildContext context) => new Home(title: 'Home'),
  Setup.routeName: (BuildContext context) => new Setup(title: 'Device'),
  NodeSetup.routeName: (BuildContext context) =>
      new NodeSetup(title: 'Node Setup'),
  DigitalIO.routeName: (BuildContext context) =>
      new DigitalIO(title: 'Digital IO'),
  LogicalIO.routeName: (BuildContext context) =>
      new LogicalIO(title: 'Logical IO'),
  RadioCode.routeName: (BuildContext context) =>
      new RadioCode(title: 'Radio Code'),
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
    print(getFirebaseUser().photoUrl);
    return new Drawer(
      child: new ListView(children: <Widget>[
        new UserAccountsDrawerHeader(
          accountName: new Text(getFirebaseUser().displayName),
          accountEmail: new Text(getFirebaseUser().email),
          currentAccountPicture: new CircleAvatar(
            backgroundImage: new NetworkImage(
              getFirebaseUser().photoUrl,
            ),
          ),
        ),
        new ListTile(
            leading: new Icon(Icons.home),
            title: new Text('Home'),
            onTap: () {
              Navigator.of(context)
                ..pop()
                ..pushNamed(Home.routeName);
            }),
        new ListTile(
            leading: new Icon(Icons.developer_board),
            title: new Text('Device'),
            onTap: () {
              Navigator.of(context)
                ..pop()
                ..pushNamed(Setup.routeName);
            }),
        new ListTile(
            leading: new Icon(Icons.label_outline),
            title: new Text('Digital IO'),
            onTap: () {
              Navigator.of(context)
                ..pop()
                ..pushNamed(DigitalIO.routeName);
            }),
        new ListTile(
            leading: new Icon(Icons.label_outline),
            title: new Text('Logical IO'),
            onTap: () {
              Navigator.of(context)
                ..pop()
                ..pushNamed(LogicalIO.routeName);
            }),
        new ListTile(
            leading: new Icon(Icons.settings_input_antenna),
            title: new Text('Radio Code'),
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
            title: new Text('Log History'),
            onTap: () {
              Navigator.of(context)
                ..pop()
                ..pushNamed(LogHistory.routeName);
            }),
        new ListTile(
            leading: new Icon(Icons.timeline),
            title: new Text('Chart History'),
            onTap: () {
              Navigator.of(context)
                ..pop()
                ..pushNamed(ChartHistory.routeName);
            }),
      ]),
    );
  }
}
