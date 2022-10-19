import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'login.dart';
import 'device.dart';
import 'log_history.dart';
import 'version.dart';
import 'domain.dart';
import 'firebase_utils.dart';

final Map<String, WidgetBuilder> menuRoutes = <String, WidgetBuilder>{
  Device.routeName: (BuildContext context) =>
      new Device(title: 'Manage Domains and Nodes'),
  Messages.routeName: (BuildContext context) =>
      new Messages(title: 'Notifications'),
  VersionInfo.routeName: (BuildContext context) =>
      new VersionInfo(title: 'Version'),
};

class NavDrawer extends StatefulWidget {
  @override
  NavDrawerState createState() => NavDrawerState();
}

class NavDrawerState extends State<NavDrawer> with TickerProviderStateMixin {
  static final Animatable<Offset> _drawerDetailsTween = Tween<Offset>(
    begin: const Offset(0.0, -1.0),
    end: Offset.zero,
  ).chain(CurveTween(
    curve: Curves.fastOutSlowIn,
  ));

  AnimationController _controller;
  Animation<double> _drawerContentsOpacity;
  Animation<Offset> _drawerDetailsPosition;
  bool _showDrawerContents = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _drawerContentsOpacity = CurvedAnimation(
      parent: ReverseAnimation(_controller),
      curve: Curves.fastOutSlowIn,
    );
    _drawerDetailsPosition = _controller.drive(_drawerDetailsTween);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: new Column(
        children: <Widget>[
          new UserAccountsDrawerHeader(
            accountName: new Text(getFirebaseUser().user.displayName),
            accountEmail: new Text(getFirebaseUser().user.email),
            /*currentAccountPicture: new CircleAvatar(
              backgroundImage: new NetworkImage(
                getFirebaseUser().providerData[1].photoURL,
              ),
            ),*/
            margin: EdgeInsets.zero,
            onDetailsPressed: () {
              _showDrawerContents = !_showDrawerContents;
              if (_showDrawerContents)
                _controller.reverse();
              else
                _controller.forward();
            },
          ),
          new MediaQuery.removePadding(
            context: context,
            // DrawerHeader consumes top MediaQuery padding.
            removeTop: true,
            child: new Expanded(
              child: new ListView(
                dragStartBehavior: DragStartBehavior.down,
                padding: const EdgeInsets.only(top: 8.0),
                children: <Widget>[
                  new Stack(
                    children: <Widget>[
                      // The initial contents of the drawer.
                      new FadeTransition(
                        opacity: _drawerContentsOpacity,
                        child: new Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              new ListTile(
                                  leading: const Icon(Icons.notifications),
                                  title: const Text('Notification'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.of(context)
                                        .pushNamed(Messages.routeName);
                                  }),
                              new ListTile(
                                  leading: const Icon(Icons.receipt),
                                  title: const Text('Version Info'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.of(context)
                                        .pushNamed(VersionInfo.routeName);
                                  }),
                            ]),
                      ),
                      // The drawer's "details" view.
                      new SlideTransition(
                        position: _drawerDetailsPosition,
                        child: new FadeTransition(
                          opacity: new ReverseAnimation(_drawerContentsOpacity),
                          child: new Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              new ListTile(
                                leading: new Icon(Icons.home),
                                title: ((getDomain() == null)
                                    ? (const Text(''))
                                    : (new Text(getDomain()))),
                                trailing: PopupMenuButton<String>(
                                    icon: const Icon(Icons.edit),
                                    onSelected: (value) {
                                      savePreferencesD(value);
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        new MaterialPageRoute(
                                          builder: (BuildContext context) =>
                                              new Domain(domain: value),
                                          fullscreenDialog: true,
                                        ),
                                      );
                                    },
                                    itemBuilder: (context) {
                                      return domains.keys.map((key) {
                                        return PopupMenuItem<String>(
                                          value: key,
                                          child: Text(key),
                                        );
                                      }).toList();
                                    }),
                              ),
                              new ListTile(
                                leading: const Icon(Icons.settings),
                                title: const Text('Manage Domains and Nodes'),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.of(context)
                                      .pushNamed(Device.routeName);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
