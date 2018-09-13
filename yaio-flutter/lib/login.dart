import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'domain.dart';
import 'firebase_utils.dart';

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
  StreamSubscription<Event> _onAddSubscription;
  StreamSubscription<Event> _onEditedSubscription;
  StreamSubscription<Event> _onRemoveSubscription;
  bool _connected = false;
  Map<String, dynamic> _map = new Map<String, dynamic>();

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
          _onAddSubscription = _rootRef.onChildAdded.listen(_onRootEntryAdded);
          _onEditedSubscription =
              _rootRef.onChildChanged.listen(_onRootEntryChanged);
          _onRemoveSubscription =
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
              // _connected = true;
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
    _onAddSubscription.cancel();
    _onEditedSubscription.cancel();
    _onRemoveSubscription.cancel();
  }

  void _onRootEntryAdded(Event event) {
    print('_onRootEntryAdded ${event.snapshot.key} ${event.snapshot.value}');
    String domain = event.snapshot.key;
    dynamic value = event.snapshot.value;
    setState(() {
      _connected = true;
    });

    setState(() {
      _map.putIfAbsent(domain, () => value);
    });

    // update all nodes
    DateTime now = new DateTime.now();
    String root = getRootRef();
    value.forEach((node, v) {
      String dataSource = '$root/$domain/$node/control';
      DatabaseReference dataRef =
          FirebaseDatabase.instance.reference().child('$dataSource/time');
      dataRef.set(now.millisecondsSinceEpoch ~/ 1000);
    });
  }

  void _onRootEntryChanged(Event event) {
    // print('_onRootEntryChanged ${event.snapshot.key} ${event.snapshot.value}');
    String domain = event.snapshot.key;
    dynamic value = event.snapshot.value;
    setState(() {
      _map.putIfAbsent(domain, () => value);
    });
    /*_map.forEach((kd, v) {
      v.forEach((kn, v) {
        print('$kd/$kn: ${v.toString()}');
      });
    });*/
  }

  void _onRootEntryRemoved(Event event) {
    print('_onRootEntryRemoved ${event.snapshot.key} ${event.snapshot.value}');
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      drawer: (_connected == false) ? null : drawer,
      appBar: new AppBar(
        title: (_connected == false)
            ? const Text('Login to Yaio...')
            : new Text(widget.title),
      ),
      body: ((_connected == false))
          ? (new LinearProgressIndicator(value: null))
          : (new ListView.builder(
              shrinkWrap: true,
              itemCount: _map.keys.length,
              itemBuilder: (context, domain) {
                String _domain = _map.keys.toList()[domain];
                return new DomainCard(name: _domain, map: _map[_domain]);
                // return new Text(_domain);
              },
            )),
    );
  }
}

class DomainCard extends StatelessWidget {
  final String name;
  final dynamic map;

  const DomainCard({Key key, this.name, this.map}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Card(
      shape: new BeveledRectangleBorder(
        borderRadius: BorderRadius.circular(0.0),
      ),
      child: new Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new ListTile(
            leading:
                new Icon(Icons.domain),
            title: new Text(name),
            subtitle: new Text('Currently ${map.keys.length} device present'),
          ),
          new ButtonTheme.bar(
            // make buttons use the appropriate styles for cards
            child: new ButtonBar(
              children: <Widget>[
                new FlatButton(
                  child: const Text('VIEW'),
                  onPressed: () => Navigator.push(
                        context,
                        new MaterialPageRoute(
                          builder: (BuildContext context) =>
                              new Domain(domain: name, map: map),
                          fullscreenDialog: true,
                        ),
                      ), //modified
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
