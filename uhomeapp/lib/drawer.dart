import 'package:flutter/material.dart';
import 'home.dart';
import 'setup.dart';
import 'node_setup.dart';
import 'data_io.dart';
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
  DataIO.routeName: (BuildContext context) => new DataIO(title: 'Data IO'),
  Functions.routeName: (BuildContext context) =>
      new Functions(title: 'Functions'),
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
            title: new Text('Data IO'),
            onTap: () {
              Navigator.of(context)
                ..pop()
                ..pushNamed(DataIO.routeName);
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
