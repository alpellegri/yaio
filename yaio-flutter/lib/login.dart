import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'device.dart';
import 'firebase_utils.dart';

class Login extends StatefulWidget {
  Login({Key key, this.title}) : super(key: key);

  static const String routeName = '/setup';

  final String title;

  @override
  _LoginState createState() => new _LoginState();
}

class _LoginState extends State<Login> {
  final FirebaseMessaging _fbMessaging = new FirebaseMessaging();
  DatabaseReference _fcmRef;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    print('_LoginState');
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
            });
            // at the end, not before
            // FirebaseDatabase.instance.setPersistenceEnabled(true);
            // FirebaseDatabase.instance.setPersistenceCacheSizeBytes(10000000);
            Navigator.of(context).pushNamed(Device.routeName);
          });
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      drawer: drawer,
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: (_connected == false)
          ? (new LinearProgressIndicator(value: null))
          : (new Text('Welcome to Yaio')),
    );
  }
}
