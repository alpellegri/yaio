import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'firebase_utils.dart';

class Setup extends StatefulWidget {
  Setup({Key key, this.title}) : super(key: key);

  static const String routeName = '/setup';

  final String title;

  @override
  _SetupState createState() => new _SetupState();
}

class _SetupState extends State<Setup> {
  final FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();
  String _infoConfig = "";
  String _homeScreenText = "Waiting for token...";
  bool _connected = false;

  _SetupState() {}

  @override
  void initState() {
    super.initState();
    print('_MyHomePageState');
    _connected = false;
    signInWithGoogle().then((onValue) {
      _firebaseMessaging.configure(
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

      _firebaseMessaging.requestNotificationPermissions(
          const IosNotificationSettings(sound: true, badge: true, alert: true));
      _firebaseMessaging.onIosSettingsRegistered
          .listen((IosNotificationSettings settings) {
        print("Settings registered: $settings");
      });
      _firebaseMessaging.getToken().then((String token) {
        assert(token != null);
        setState(() {
          _homeScreenText = "Push Messaging token: $token";
        });
        _connected = true;
      });
    });
  }

  @override
  void dispose() {}

  @override
  Widget build(BuildContext context) {
    if (_connected == false) {
      return new Scaffold(
          drawer: drawer,
          appBar: new AppBar(
            title: new Text(widget.title),
          ),
          body: new LinearProgressIndicator(
            value: null,
          ));
    } else {
      return new Scaffold(
        drawer: drawer,
        appBar: new AppBar(
          title: new Text(widget.title),
        ),
        body: new Text(_homeScreenText),
        floatingActionButton: new FloatingActionButton(
          onPressed: _onFloatingActionButtonPressed,
          tooltip: 'add',
          child: new Icon(Icons.add),
        ),
      );

    }
  }

  void _onFloatingActionButtonPressed() {}
}
