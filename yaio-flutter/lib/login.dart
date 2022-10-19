import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'domain.dart';
import 'firebase_utils.dart';

Map<String, dynamic> domains = new Map<String, dynamic>();

class Login extends StatefulWidget {
  Login({Key key, this.title}) : super(key: key);
  static const String routeName = '/yaio';
  final String title;

  @override
  _LoginState createState() => new _LoginState();
}

class _LoginState extends State<Login> {
  DatabaseReference _fcmRef;
  DatabaseReference _rootRef;
  StreamSubscription<DatabaseEvent> _onRootAddSubscription;
  StreamSubscription<DatabaseEvent> _onRootEditedSubscription;
  StreamSubscription<DatabaseEvent> _onRootRemoveSubscription;
  bool _connected = false;
  Map<String, dynamic> _map = new Map<String, dynamic>();
  final NavDrawer drawer = new NavDrawer();
  String _curr_domain;

  @override
  void initState() {
    super.initState();

    _connected = false;
    signInWithGoogle().then((onValue) {
      FirebaseMessaging.instance.getToken().then((String token) {
        assert(token != null);

        loadPreferences().then((map) {
          print('getRootRef: ${getRootRef()}');

          _rootRef = FirebaseDatabase.instance.reference().child(getRootRef());
          _onRootAddSubscription =
              _rootRef.onChildAdded.listen(_onRootEntryAdded);
          _onRootEditedSubscription =
              _rootRef.onChildChanged.listen(_onRootEntryChanged);
          _onRootRemoveSubscription =
              _rootRef.onChildRemoved.listen(_onRootEntryRemoved);

          _fcmRef =
              FirebaseDatabase.instance.ref().child(getFcmTokenRef());
          _fcmRef.once().then((DatabaseEvent onValue) {
            print('once: ${onValue.snapshot.value}');
            Map map = onValue.snapshot.value;
            bool tokenFound = false;
            if (map != null) {
              map.forEach((key, value) {
                if (value == token) {
                  print('key test: $key');
                  tokenFound = true;
                }
              });
            }
            if (tokenFound == false) {
              _fcmRef.push().set(token);
              print('token saved: $token');
            }
            setState(() {
              _connected = true;
              _curr_domain = getDomain();
            });
            // at the end, not before
            // FirebaseDatabase.instance.setPersistenceEnabled(true);
            // FirebaseDatabase.instance.setPersistenceCacheSizeBytes(10000000);
            // Navigator.of(context).pushNamed(Device.routeName);
          });
        });
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _onRootAddSubscription.cancel();
    _onRootEditedSubscription.cancel();
    _onRootRemoveSubscription.cancel();
  }

  void _onRootEntryAdded(DatabaseEvent event) {
    // print('_onRootEntryAdded ${event.snapshot.key} ${event.snapshot.value}');
    String domain = event.snapshot.key;
    dynamic value = event.snapshot.value;
    domains.putIfAbsent(domain, () => value);
    setState(() {
      _map.putIfAbsent(domain, () => value);
    });
    _updateAllNodes(domain, value);
  }

  void _onRootEntryChanged(DatabaseEvent event) {
    // print('_onRootEntryChanged ${event.snapshot.key} ${event.snapshot.value}');
    String domain = event.snapshot.key;
    dynamic value = event.snapshot.value;
    setState(() {
      _map.update(domain, (dynamic v) => value);
    });
    // _updateAllNodes(domain, value);
  }

  void _onRootEntryRemoved(DatabaseEvent event) {
    // print('_onRootEntryRemoved ${event.snapshot.key} ${event.snapshot.value}');
    String domain = event.snapshot.key;
    domains.removeWhere((key, value) => key == domain);
    setState(() {
      _map.removeWhere((key, value) => key == domain);
    });
  }

  void _updateAllNodes(String domain, dynamic value) {
    DateTime now = new DateTime.now();
    String root = getRootRef();
    value.forEach((node, v) {
      String dataSource = '$root/$domain/$node/control';
      DatabaseReference dataRef =
          FirebaseDatabase.instance.reference().child('$dataSource/time');
      dataRef.set(now.millisecondsSinceEpoch ~/ 1000);
    });
  }

  @override
  Widget build(BuildContext context) {
    if ((_connected == false) || (_curr_domain == null) || (_map.length == 0)) {
      return new Scaffold(
        drawer: (_connected == false) ? null : drawer,
        appBar: new AppBar(
          title: (_connected == false)
              ? const Text('Login to Yaio...')
              : new Text(widget.title),
        ),
        body: ((_connected == false))
            ? (new SizedBox(
                height: 3.0, child: new LinearProgressIndicator(value: null)))
            : (new Text('Select a domain')),
      );
    } else {
      return new Domain(domain: _curr_domain);
    }
  }
}
