import 'package:flutter/material.dart';
import 'home.dart';
import 'device.dart';
import 'node_setup.dart';
import 'data_io.dart';
import 'exec.dart';
import 'log_history.dart';
import 'chart_history.dart';
import 'firebase_utils.dart';

final MyDrawer drawer = new MyDrawer();

final Map<String, WidgetBuilder> menuRoutes = <String, WidgetBuilder>{
  Home.routeName: (BuildContext context) => new Home(title: 'Home'),
  Device.routeName: (BuildContext context) => new Device(title: 'Device'),
  NodeSetup.routeName: (BuildContext context) =>
      new NodeSetup(title: 'Device Setup'),
  DataIO.routeName: (BuildContext context) => new DataIO(title: 'DataIO'),
  Exec.routeName: (BuildContext context) => new Exec(title: 'Routine'),
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
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.of(context).pushNamed(Home.routeName);
            }),
        new ListTile(
            leading: const Icon(Icons.developer_board),
            title: const Text('Device'),
            onTap: () {
              Navigator.of(context).pushNamed(Device.routeName);
            }),
        new ListTile(
            leading: const Icon(Icons.label_outline),
            title: const Text('Data IO'),
            onTap: () {
              Navigator.of(context).pushNamed(DataIO.routeName);
            }),
        new ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Routine'),
            onTap: () {
              Navigator.of(context).pushNamed(Exec.routeName);
            }),
        new ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Log History'),
            onTap: () {
              Navigator.of(context).pushNamed(LogHistory.routeName);
            }),
        new ListTile(
            leading: const Icon(Icons.timeline),
            title: const Text('Chart History'),
            onTap: () {
              Navigator.of(context).pushNamed(ChartHistory.routeName);
            }),
      ]),
    );
  }
}
