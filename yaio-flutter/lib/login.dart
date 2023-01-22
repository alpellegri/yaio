import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'domain.dart';
import 'firebase_utils.dart';

Map<String, dynamic> domains = <String, dynamic>{};

class Login extends StatefulWidget {
  const Login({
    super.key,
    required this.title,
  });
  static const String routeName = '/yaio';
  final String title;

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  late DatabaseReference _fcmRef;
  late DatabaseReference _rootRef;
  late StreamSubscription<DatabaseEvent> _onRootAddSubscription;
  late StreamSubscription<DatabaseEvent> _onRootEditedSubscription;
  late StreamSubscription<DatabaseEvent> _onRootRemoveSubscription;
  bool _connected = false;
  final Map<String, dynamic> _map = <String, dynamic>{};
  final NavDrawer drawer = const NavDrawer();
  String? _curr_domain;

  @override
  void initState() {
    super.initState();

    _connected = false;
    signInWithGoogle().then((onValue) {
      FirebaseMessaging.instance.getToken().then((String? token) {
        assert(token != null);

        loadPreferences().then((map) {
          print('getRootRef: ${getRootRef()}');

          _rootRef = FirebaseDatabase.instance.ref().child(getRootRef()!);
          _onRootAddSubscription =
              _rootRef.onChildAdded.listen(_onRootEntryAdded);
          _onRootEditedSubscription =
              _rootRef.onChildChanged.listen(_onRootEntryChanged);
          _onRootRemoveSubscription =
              _rootRef.onChildRemoved.listen(_onRootEntryRemoved);

          _fcmRef = FirebaseDatabase.instance.ref().child(getFcmTokenRef()!);
          _fcmRef.once().then((DatabaseEvent onValue) {
            print('once: ${onValue.snapshot.value}');
            Map map = onValue.snapshot.value as Map;
            bool tokenFound = false;
            map.forEach((key, value) {
              if (value == token) {
                print('key test: $key');
                tokenFound = true;
              }
            });
            if (tokenFound == false) {
              _fcmRef.push().set(token);
              print('token saved: $token');
            }
            setState(() {
              _connected = true;
              _curr_domain = getDomain()!;
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
    String domain = event.snapshot.key!;
    dynamic value = event.snapshot.value;
    domains.putIfAbsent(domain, () => value);
    setState(() {
      _map.putIfAbsent(domain, () => value);
    });
    _updateAllNodes(domain, value);
  }

  void _onRootEntryChanged(DatabaseEvent event) {
    // print('_onRootEntryChanged ${event.snapshot.key} ${event.snapshot.value}');
    String domain = event.snapshot.key!;
    dynamic value = event.snapshot.value;
    setState(() {
      _map.update(domain, (dynamic v) => value);
    });
    // _updateAllNodes(domain, value);
  }

  void _onRootEntryRemoved(DatabaseEvent event) {
    // print('_onRootEntryRemoved ${event.snapshot.key} ${event.snapshot.value}');
    String domain = event.snapshot.key!;
    domains.removeWhere((key, value) => key == domain);
    setState(() {
      _map.removeWhere((key, value) => key == domain);
    });
  }

  void _updateAllNodes(String domain, dynamic value) {
    DateTime now = DateTime.now();
    String root = getRootRef()!;
    value.forEach((node, v) {
      String dataSource = '$root/$domain/$node/control';
      DatabaseReference dataRef =
          FirebaseDatabase.instance.ref().child('$dataSource/time');
      dataRef.set(now.millisecondsSinceEpoch ~/ 1000);
    });
  }

  @override
  Widget build(BuildContext context) {
    if ((_connected == false) || (_curr_domain == null) || (_map.isEmpty)) {
      return Scaffold(
        drawer: (_connected == false) ? null : drawer,
        appBar: AppBar(
          title: (_connected == false)
              ? const Text('Login to Yaio...')
              : Text(widget.title),
        ),
        body: ((_connected == false))
            ? (const SizedBox(
                height: 3.0, child: LinearProgressIndicator(value: null)))
            : (const Text('Select a domain')),
      );
    } else {
      return Domain(
        domain: _curr_domain!,
      );
    }
  }
}
