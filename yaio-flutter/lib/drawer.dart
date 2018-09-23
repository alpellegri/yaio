import 'package:flutter/material.dart';
import 'device.dart';
import 'log_history.dart';
import 'firebase_utils.dart';

final MyDrawer drawer = new MyDrawer();

final Map<String, WidgetBuilder> menuRoutes = <String, WidgetBuilder>{
  Device.routeName: (BuildContext context) => new Device(title: 'Device'),
  Messages.routeName: (BuildContext context) => new Messages(title: 'Messages'),
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
            leading: const Icon(Icons.developer_board),
            title: const Text('Device'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(Device.routeName);
            }),
        new ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Messages'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(Messages.routeName);
            }),
      ]),
    );
  }
}
