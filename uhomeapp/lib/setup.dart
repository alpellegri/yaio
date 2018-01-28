import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'node_setup.dart';
import 'firebase_utils.dart';
import 'const.dart';

class Setup extends StatefulWidget {
  Setup({Key key, this.title}) : super(key: key);

  static const String routeName = '/setup';

  final String title;

  @override
  _SetupState createState() => new _SetupState();
}

class _SetupState extends State<Setup> {
  final FirebaseMessaging _fbMessaging = new FirebaseMessaging();
  bool _connected = false;

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
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_connected == false) {
      return new Scaffold(
          drawer: drawer,
          appBar: new AppBar(
            title: new Text(widget.title),
          ),
          body: new LinearProgressIndicator(value: null));
    } else {
      return new Scaffold(
        drawer: drawer,
        appBar: new AppBar(
          title: new Text(widget.title),
        ),
        body: new ExpasionPanelsDemo(),
      );
    }
  }
}

class ListItem extends StatelessWidget {
  final String value;
  final FormFieldState<String> field;

  ListItem(this.value, this.field);

  @override
  Widget build(BuildContext context) {
    return new Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
      new Radio<String>(
        value: value,
        groupValue: field.value,
        onChanged: field.onChanged,
      ),
      new Text(value),
    ]);
  }
}

typedef Widget DemoItemBodyBuilder<T>(DemoItem<T> item);
typedef String ValueToString<T>(T value);

class DualHeaderWithHint extends StatelessWidget {
  const DualHeaderWithHint({this.name, this.value, this.hint, this.showHint});

  final String name;
  final String value;
  final String hint;
  final bool showHint;

  Widget _crossFade(Widget first, Widget second, bool isExpanded) {
    return new AnimatedCrossFade(
      firstChild: first,
      secondChild: second,
      firstCurve: const Interval(0.0, 0.6, curve: Curves.fastOutSlowIn),
      secondCurve: const Interval(0.4, 1.0, curve: Curves.fastOutSlowIn),
      sizeCurve: Curves.fastOutSlowIn,
      crossFadeState:
          isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    return new Row(children: <Widget>[
      new Expanded(
        child: new Container(
          margin: const EdgeInsets.only(left: 24.0),
          child: new FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: new Text(
              name,
              style: textTheme.body1.copyWith(fontSize: 15.0),
            ),
          ),
        ),
      ),
      new Expanded(
          child: new Container(
              margin: const EdgeInsets.only(left: 24.0),
              child: _crossFade(
                  new Text(value,
                      style: textTheme.caption.copyWith(fontSize: 15.0)),
                  new Text(hint,
                      style: textTheme.caption.copyWith(fontSize: 15.0)),
                  showHint)))
    ]);
  }
}

class CollapsibleBody extends StatelessWidget {
  const CollapsibleBody({
    this.margin: EdgeInsets.zero,
    this.child,
    this.onSave,
    this.onCancel,
    this.onAdd,
  });

  final EdgeInsets margin;
  final Widget child;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    return new Column(children: <Widget>[
      new Container(
          margin: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 0.0) -
              margin,
          child: new Center(
              child: new DefaultTextStyle(
                  style: textTheme.caption.copyWith(fontSize: 15.0),
                  child: child))),
      new ButtonTheme.bar(
          child: new ButtonBar(children: <Widget>[
        new FlatButton(
            onPressed: onAdd,
            child: const Text(
              'ADD',
            )),
        new FlatButton(
            onPressed: onCancel,
            child: const Text(
              'CANCEL',
            )),
        new FlatButton(
            onPressed: onSave,
            // textTheme: ButtonTextTheme.accent,
            child: const Text('SAVE')),
      ])),
    ]);
  }
}

class DemoItem<T> {
  DemoItem({
    this.name,
    this.value,
    this.hint,
    this.builder,
    this.valueToString,
  })
      : textController = new TextEditingController(text: valueToString(value));

  List query = new List();
  final String name;
  final String hint;
  final TextEditingController textController;
  final DemoItemBodyBuilder<T> builder;
  final ValueToString<T> valueToString;
  T value;
  bool isExpanded = false;
  bool isModeEdit = false;

  ExpansionPanelHeaderBuilder get headerBuilder {
    return (BuildContext context, bool isExpanded) {
      return new DualHeaderWithHint(
          name: name,
          value: valueToString(value),
          hint: hint,
          showHint: isExpanded);
    };
  }
}

class ExpasionPanelsDemo extends StatefulWidget {
  @override
  _ExpansionPanelsDemoState createState() => new _ExpansionPanelsDemoState();
}

class _ExpansionPanelsDemoState extends State<ExpasionPanelsDemo> {
  DatabaseReference _fcmRef;
  bool _nodeNeedUpdate = false;

  DatabaseReference _rootRef;
  StreamSubscription<Event> _onAddSubscription;
  List<DemoItem<dynamic>> _demoItems;
  Map<String, dynamic> entryMap = new Map<String, dynamic>();
  bool _isPreferencesReady = false;
  String _ctrlDomainName = '';
  String _ctrlNodeName = '';
  bool _isNeedCreate = true;

  @override
  void initState() {
    super.initState();

    loadPreferences().then((map) {
      setState(() {
        _isPreferencesReady = true;
      });

      print('getRootRef: ${getRootRef()}');
      _rootRef = FirebaseDatabase.instance.reference().child(getRootRef());
      _onAddSubscription = _rootRef.onChildAdded.listen(_onEntryAdded);
      if (map.isNotEmpty) {
        setState(() {
          _ctrlDomainName = map['domain'];
          _ctrlNodeName = map['nodename'];
        });
      }

      _fcmRef = FirebaseDatabase.instance.reference().child(getFcmTokenRef());
      _fcmRef.once().then((DataSnapshot onValue) {
        print("once: ${onValue.value}");
        Map map = onValue.value;
        bool tokenFound = false;
        String token = getFbToken();
        if (map != null) {
          map.forEach((key, value) {
            if (value == token) {
              print("key test: $key");
              tokenFound = true;
            }
          });
        }
        if (tokenFound == false) {
          _nodeNeedUpdate = true;
          _fcmRef.push().set(token);
          print("token saved: $token");
        }

        // at the end, not before
        // FirebaseDatabase.instance.setPersistenceEnabled(true);
        // FirebaseDatabase.instance.setPersistenceCacheSizeBytes(10000000);
      });

      _demoItems = <DemoItem<dynamic>>[
        new DemoItem<String>(
            name: 'Domain',
            value: _ctrlDomainName,
            hint: 'Select domain',
            valueToString: (String location) => location,
            builder: (DemoItem<String> item) {
              void close() {
                setState(() {
                  item.isExpanded = false;
                  item.isModeEdit = false;
                });
              }

              void add() {
                setState(() {
                  item.isModeEdit = true;
                });
              }

              return new Form(
                  child: new Builder(builder: (BuildContext context) {
                return new CollapsibleBody(
                  onSave: () {
                    Form.of(context).save();
                    _ctrlDomainName = item.value;
                    close();
                  },
                  onCancel: () {
                    Form.of(context).reset();
                    close();
                  },
                  onAdd: () {
                    add();
                  },
                  child: (item.isModeEdit == true)
                      ? (new TextFormField(
                          controller: item.textController,
                          decoration: new InputDecoration(
                            hintText: item.hint,
                            labelText: item.name,
                          ),
                          onSaved: (String value) {
                            item.value = value;
                          },
                        ))
                      : (new FormField<String>(
                          initialValue: item.value,
                          onSaved: (String result) {
                            item.value = result;
                          },
                          builder: (FormFieldState<String> field) {
                            return new ListView.builder(
                              shrinkWrap: true,
                              reverse: true,
                              itemCount: item.query.length,
                              itemBuilder: (buildContext, index) {
                                return new InkWell(
                                    child:
                                        new ListItem(item.query[index], field));
                              },
                            );
                          })),
                );
              }));
            }),
        new DemoItem<String>(
            name: 'Node',
            value: _ctrlNodeName,
            hint: 'Select node',
            valueToString: (String location) => location,
            builder: (DemoItem<String> item) {
              void close() {
                setState(() {
                  item.isExpanded = false;
                  item.isModeEdit = false;
                });
              }

              void add() {
                setState(() {
                  item.isModeEdit = true;
                });
              }

              return new Form(
                  child: new Builder(builder: (BuildContext context) {
                return new CollapsibleBody(
                  onSave: () {
                    Form.of(context).save();
                    _ctrlNodeName = item.value;
                    _changePreferences();
                    close();
                  },
                  onCancel: () {
                    Form.of(context).reset();
                    close();
                  },
                  onAdd: () {
                    add();
                  },
                  child: (item.isModeEdit == true)
                      ? (new TextFormField(
                          controller: item.textController,
                          decoration: new InputDecoration(
                            hintText: item.hint,
                            labelText: item.name,
                          ),
                          onSaved: (String value) {
                            item.value = value;
                          },
                        ))
                      : (new FormField<String>(
                          initialValue: item.value,
                          onSaved: (String result) {
                            item.value = result;
                          },
                          builder: (FormFieldState<String> field) {
                            return new ListView.builder(
                              shrinkWrap: true,
                              reverse: true,
                              itemCount: item.query.length,
                              itemBuilder: (buildContext, index) {
                                return new InkWell(
                                    child:
                                        new ListItem(item.query[index], field));
                              },
                            );
                          })),
                );
              }));
            }),
      ];
    });
  }

  @override
  void dispose() {
    super.dispose();
    _onAddSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    if (_isPreferencesReady == false) {
      return new LinearProgressIndicator(value: null);
    } else {
      var update = _update();
      setState(() {
        _isNeedCreate = update;
      });
      print('_isNeedCreate $_isNeedCreate');
      return new ListView(children: <Widget>[
        new SingleChildScrollView(
          child: new SafeArea(
            top: false,
            bottom: false,
            child: new Container(
              margin: const EdgeInsets.all(24.0),
              child: new ExpansionPanelList(
                  expansionCallback: (int index, bool isExpanded) {
                    setState(() {
                      _demoItems[index].isExpanded = !isExpanded;
                    });
                  },
                  children: _demoItems.map((DemoItem<dynamic> item) {
                    return new ExpansionPanel(
                        isExpanded: item.isExpanded,
                        headerBuilder: item.headerBuilder,
                        body: item.builder(item));
                  }).toList()),
            ),
          ),
        ),
        new ListTile(
          leading: (_isNeedCreate == true)
              ? (const Icon(Icons.link_off))
              : (const Icon(Icons.link)),
          title: const Text('Selected Device'),
          subtitle: new Text('$_ctrlNodeName @ $_ctrlDomainName'),
          trailing: (_isNeedCreate == true)
              ? null
              : (new ButtonTheme.bar(
                  child: new ButtonBar(
                    children: <Widget>[
                      new FlatButton(
                        child: const Text('CONFIGURE'),
                        onPressed: () {
                          Navigator.of(context).pushNamed(NodeSetup.routeName);
                        },
                      ),
                    ],
                  ),
                )),
        ),
      ]);
    }
  }

  bool _update() {
    bool ret = true;
    var keyList = entryMap.keys.toList();
    _demoItems[0].query = keyList;
    var keyValue = _demoItems[0].value;
    if (keyList.contains(keyValue)) {
      keyList = entryMap[keyValue].keys.toList();
      _demoItems[1].query = keyList;
      keyValue = _demoItems[1].value;
      ret = !keyList.contains(keyValue);
    }
    return ret;
  }

  void _nodeUpdate(String source) {
    DatabaseReference dataRef;
    String root = getRootRef();
    String dataSource = '$root/$source/control';
    print(dataSource);
    dataRef = FirebaseDatabase.instance.reference().child('$dataSource/reboot');
    dataRef.set(kNodeUpdate);
    DateTime now = new DateTime.now();
    dataRef = FirebaseDatabase.instance.reference().child('$dataSource/time');
    dataRef.set(now.millisecondsSinceEpoch ~/ 1000);
  }

  void _onEntryAdded(Event event) {
    print('_onEntryAdded');

    setState(() {
      entryMap.putIfAbsent(event.snapshot.key, () => event.snapshot.value);
    });

    print(_nodeNeedUpdate);
    if (_nodeNeedUpdate == true) {
      var domain = event.snapshot.key;
      // value contain a map of nodes, each key is the name of the node
      var v = event.snapshot.value;
      v.forEach((node, v) {
        _nodeUpdate('$domain/$node/');
      });
    }
  }

  void _changePreferences() {
    savePreferencesDN(_ctrlDomainName, _ctrlNodeName);
    if (_isNeedCreate == true) {
      DatabaseReference ref;
      ref = FirebaseDatabase.instance.reference().child(getControlRef());
      ref.set(getControlDefault());
      ref = FirebaseDatabase.instance.reference().child(getStartupRef());
      ref.set(getStartupDefault());
      ref = FirebaseDatabase.instance.reference().child(getStatusRef());
      ref.set(getStatusDefault());
    }
  }
}
