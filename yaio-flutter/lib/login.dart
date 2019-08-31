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
  final FirebaseMessaging _fbMessaging = new FirebaseMessaging();
  DatabaseReference _fcmRef;
  DatabaseReference _rootRef;
  StreamSubscription<Event> _onRootAddSubscription;
  StreamSubscription<Event> _onRootEditedSubscription;
  StreamSubscription<Event> _onRootRemoveSubscription;
  bool _connected = false;
  Map<String, dynamic> _map = new Map<String, dynamic>();
  final NavDrawer drawer = new NavDrawer();
  String _curr_domain;

  @override
  void initState() {
    super.initState();

    _connected = false;
    signInWithGoogle().then((onValue) {
      _fbMessaging.configure(
        onMessage: (Map<String, dynamic> message) {
          print("onMessage: $message");
          // _showItemDialog(message);
        },
        onLaunch: (Map<String, dynamic> message) {
          print("onLaunch: $message");
          // _navigateToItemDetail(message);
        },
        onResume: (Map<String, dynamic> message) {
          print("onResume: $message");
          // _navigateToItemDetail(message);
        },
      );

      _fbMessaging.requestNotificationPermissions(
          const IosNotificationSettings(sound: true, badge: true, alert: true));
      _fbMessaging.onIosSettingsRegistered
          .listen((IosNotificationSettings settings) {
        print('Settings registered: $settings');
      });
      _fbMessaging.getToken().then((String token) {
        assert(token != null);

        loadPreferences().then((map) {
          print('getRootRef: ${getRootRef()}');

          _rootRef = FirebaseDatabase.instance.reference().child(getRootRef());
          _onRootAddSubscription = _rootRef.onChildAdded.listen(_onRootEntryAdded);
          _onRootEditedSubscription =
              _rootRef.onChildChanged.listen(_onRootEntryChanged);
          _onRootRemoveSubscription =
              _rootRef.onChildRemoved.listen(_onRootEntryRemoved);

          _fcmRef =
              FirebaseDatabase.instance.reference().child(getFcmTokenRef());
          _fcmRef.once().then((DataSnapshot onValue) {
            print('once: ${onValue.value}');
            Map map = onValue.value;
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

  void _onRootEntryAdded(Event event) {
    // print('_onRootEntryAdded ${event.snapshot.key} ${event.snapshot.value}');
    String domain = event.snapshot.key;
    dynamic value = event.snapshot.value;
    domains.putIfAbsent(domain, () => value);
    setState(() {
      _map.putIfAbsent(domain, () => value);
    });
    _updateAllNodes(domain, value);
  }

  void _onRootEntryChanged(Event event) {
    // print('_onRootEntryChanged ${event.snapshot.key} ${event.snapshot.value}');
    String domain = event.snapshot.key;
    dynamic value = event.snapshot.value;
    setState(() {
      _map.update(domain, (dynamic v) => value);
    });
    // _updateAllNodes(domain, value);
  }

  void _onRootEntryRemoved(Event event) {
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
    print('$_connected, $_curr_domain, ${_map.length}');
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
            : (new ListView.builder(
                physics: BouncingScrollPhysics(),
                shrinkWrap: true,
                itemCount: _map.keys.length,
                itemBuilder: (context, domain) {
                  String _domain = _map.keys.toList()[domain];
                  return new DomainCard(name: _domain, map: _map[_domain]);
                },
              )),
      );
    } else {
      print('hello');
      return new Domain(domain: _curr_domain);
    }
  }
}

class DomainCard extends StatelessWidget {
  final String name;
  final dynamic map;

  const DomainCard({Key key, this.name, this.map}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        new InkWell(
          child: new ListTile(
            leading: const Icon(Icons.domain),
            title: new Text(name),
            subtitle: new Text('${map.keys.length} device'),
          ),
          onTap: () => Navigator.push(
            context,
            new MaterialPageRoute(
              builder: (BuildContext context) =>
                  new Domain(domain: name),
              fullscreenDialog: true,
            ),
          ), //modified
        ),
      ],
    );
  }
}
