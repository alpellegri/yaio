import 'package:flutter/material.dart';
import 'home.dart';
import 'device.dart';
import 'node_setup.dart';
import 'data_io.dart';
import 'exec.dart';
import 'exec_edit.dart';
import 'log_history.dart';
import 'chart_history.dart';
import 'firebase_utils.dart';

final MyDrawer drawer = new MyDrawer();

final Map<String, WidgetBuilder> menuRoutes = <String, WidgetBuilder>{
  Home.routeName: (BuildContext context) => new Home(title: 'Home'),
  Device.routeName: (BuildContext context) => new Device(title: 'Device'),
  NodeSetup.routeName: (BuildContext context) =>
      new NodeSetup(title: 'Device Setup'),
  DataIO.routeName: (BuildContext context) => new DataIO(),
  Exec.routeName: (BuildContext context) => new Exec(),
  ExecEdit.routeName: (BuildContext context) =>
      new ExecEdit(title: 'Exec Edit'),
  ExecProg.routeName: (BuildContext context) =>
      new ExecProg(title: 'Exec Prog'),
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
              Navigator.of(context).pushNamed(Home.routeName);
            }),
        new ListTile(
            leading: new Icon(Icons.developer_board),
            title: new Text('Device'),
            onTap: () {
              Navigator.of(context).pushNamed(Device.routeName);
            }),
        new ListTile(
            leading: new Icon(Icons.label_outline),
            title: new Text('Data IO'),
            onTap: () {
              Navigator.of(context).pushNamed(DataIO.routeName);
            }),
        new ListTile(
            leading: new Icon(Icons.code),
            title: new Text('Routine'),
            onTap: () {
              Navigator.of(context).pushNamed(Exec.routeName);
            }),
        new ListTile(
            leading: new Icon(Icons.message),
            title: new Text('Log History'),
            onTap: () {
              Navigator.of(context).pushNamed(LogHistory.routeName);
            }),
        new ListTile(
            leading: new Icon(Icons.timeline),
            title: new Text('Chart History'),
            onTap: () {
              Navigator.of(context).pushNamed(ChartHistory.routeName);
            }),
      ]),
    );
  }
}
