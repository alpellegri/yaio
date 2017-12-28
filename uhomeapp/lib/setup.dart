import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'node_setup.dart';
import 'firebase_utils.dart';

class Setup extends StatefulWidget {
  Setup({Key key, this.title}) : super(key: key);

  static const String routeName = '/setup';

  final String title;

  @override
  _SetupState createState() => new _SetupState();
}

class _SetupState extends State<Setup> {
  final TextEditingController _ctrlSSID = new TextEditingController();
  final TextEditingController _ctrlPassword = new TextEditingController();
  final TextEditingController _ctrlDomain = new TextEditingController();
  final TextEditingController _ctrlNodeName = new TextEditingController();
  final FirebaseMessaging _fbMessaging = new FirebaseMessaging();
  bool _connected = false;
  DatabaseReference ref;

  _SetupState() {}

  @override
  void initState() {
    super.initState();
    print('_MyHomePageState');
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
        print("Settings registered: $settings");
      });
      _fbMessaging.getToken().then((String token) {
        assert(token != null);
        setFbToken(token);
        setState(() {
          _connected = true;
        });

        loadPreferences().then((map) {
          ref = FirebaseDatabase.instance.reference().child(getRootRef());

          if (map != null) {
            setState(() {
              _ctrlDomain.text = map['domain'];
              _ctrlSSID.text = map['ssid'];
              _ctrlPassword.text = map['password'];
              _ctrlNodeName.text = map['nodename'];
            });
          }
        });
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
        body: new ListView(children: <Widget>[
          new Card(
            child: new Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                new TextField(
                  controller: _ctrlDomain,
                  decoration: new InputDecoration(
                    hintText: 'Domain',
                  ),
                ),
                new TextField(
                  controller: _ctrlNodeName,
                  decoration: new InputDecoration(
                    hintText: 'Node Name',
                  ),
                ),
                new ButtonTheme.bar(
                    child: new ButtonBar(children: <Widget>[
                      new FlatButton(
                        child: new Text('SET'),
                        onPressed: _changePreferences,
                      ),
                      new FlatButton(
                        child: new Text('RESET'),
                        onPressed: _resetPreferences,
                      ),
                      new FlatButton(
                        child: new Text('CONFIGURE'),
                        onPressed: () {
                          Navigator.of(context)
                            ..pushNamed(NodeSetup.routeName);
                        },
                      ),
                ])),
              ],
            ),
          ),
        ]),
        floatingActionButton: new FloatingActionButton(
          onPressed: _onFloatingActionButtonPressed,
          tooltip: 'add',
          child: new Icon(Icons.add),
        ),
      );
    }
  }

  void _onFloatingActionButtonPressed() {
    print('_onFloatingActionButtonPressed');
  }

  void _changePreferences() {
    print('_savePreferences');
    savePreferencesDN(_ctrlDomain.text, _ctrlNodeName.text);
  }

  void _resetPreferences() {
    print('_savePreferences');
    savePreferencesDN(_ctrlDomain.text, _ctrlNodeName.text);

    DatabaseReference ref;
    ref = FirebaseDatabase.instance.reference().child(getControlRef());
    ref.set(getControlDefault());
    ref = FirebaseDatabase.instance.reference().child(getStartupRef());
    ref.set(getStartupDefault());
    ref = FirebaseDatabase.instance.reference().child(getStatusRef());
    ref.set(getStatusDefault());
  }
}
