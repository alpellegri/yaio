import 'dart:async';
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

Map<String, dynamic> entryMap = new Map<String, dynamic>();

class _SetupState extends State<Setup> {
  DatabaseReference _entryRef;
  StreamSubscription<Event> _onAddSubscription;

  final TextEditingController _ctrlDomain = new TextEditingController();
  final TextEditingController _ctrlNodeName = new TextEditingController();
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

        loadPreferences().then((map) {
          print(getRootRef());
          _entryRef = FirebaseDatabase.instance.reference().child(getRootRef());
          _onAddSubscription = _entryRef.onChildAdded.listen(_onEntryAdded);
          if (map != null) {
            setState(() {
              _ctrlDomain.text = map['domain'];
              _ctrlNodeName.text = map['nodename'];
            });
          }
        });
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _onAddSubscription.cancel();
  }

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
                      Navigator.of(context)..pushNamed(NodeSetup.routeName);
                    },
                  ),
                ])),
              ],
            ),
          ),
        ]),
        /* body: new ExpasionPanelsDemo(), */
      );
    }
  }

  void _onEntryAdded(Event event) {
    print('_onEntryAdded');

    setState(() {
      entryMap.putIfAbsent(event.snapshot.key, () => event.snapshot.value);
    });
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
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    return new Row(children: <Widget>[
      new Expanded(
        flex: 2,
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
          flex: 3,
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
  const CollapsibleBody(
      {this.margin: EdgeInsets.zero, this.child, this.onSave, this.onCancel});

  final EdgeInsets margin;
  final Widget child;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    return new Column(children: <Widget>[
      new Container(
          margin: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0) -
              margin,
          child: new Center(
              child: new DefaultTextStyle(
                  style: textTheme.caption.copyWith(fontSize: 15.0),
                  child: child))),
      const Divider(height: 1.0),
      new Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: new Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                new Container(
                    margin: const EdgeInsets.only(right: 8.0),
                    child: new FlatButton(
                        onPressed: onCancel,
                        child: const Text('CANCEL',
                            style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 15.0,
                                fontWeight: FontWeight.w500)))),
                new Container(
                    margin: const EdgeInsets.only(right: 8.0),
                    child: new FlatButton(
                        onPressed: onSave,
                        textTheme: ButtonTextTheme.accent,
                        child: const Text('SAVE')))
              ]))
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
  // static const String routeName = '/material/expansion_panels';

  @override
  _ExpansionPanelsDemoState createState() => new _ExpansionPanelsDemoState();
}

class _ExpansionPanelsDemoState extends State<ExpasionPanelsDemo> {
  List<DemoItem<dynamic>> _demoItems;

  @override
  void initState() {
    super.initState();

    _demoItems = <DemoItem<dynamic>>[
      new DemoItem<String>(
          name: 'Domain',
          value: '',
          hint: 'Select domain',
          valueToString: (String location) => location,
          builder: (DemoItem<String> item) {
            void close() {
              setState(() {
                item.isExpanded = false;
              });
            }

            return new Form(child: new Builder(builder: (BuildContext context) {
              return new CollapsibleBody(
                onSave: () {
                  Form.of(context).save();
                  close();
                },
                onCancel: () {
                  Form.of(context).reset();
                  close();
                },
                child: new FormField<String>(
                    initialValue: item.value,
                    onSaved: (String result) {
                      item.value = result;
                    },
                    builder: (FormFieldState<String> field) {
                      // var query = entryMap.keys.toList();
                      return new ListView.builder(
                        shrinkWrap: true,
                        reverse: true,
                        itemCount: item.query.length,
                        itemBuilder: (buildContext, index) {
                          return new InkWell(
                              child: new ListItem(item.query[index], field));
                        },
                      );
                    }),
              );
            }));
          }),
      new DemoItem<String>(
          name: 'Node',
          value: '',
          hint: 'Select node',
          valueToString: (String location) => location,
          builder: (DemoItem<String> item) {
            void close() {
              setState(() {
                item.isExpanded = false;
              });
            }

            return new Form(child: new Builder(builder: (BuildContext context) {
              return new CollapsibleBody(
                onSave: () {
                  Form.of(context).save();
                  close();
                },
                onCancel: () {
                  Form.of(context).reset();
                  close();
                },
                child: new FormField<String>(
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
                              child: new ListItem(item.query[index], field));
                        },
                      );
                    }),
              );
            }));
          }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    _demoItems[0].query = entryMap.keys.toList();
    if (_demoItems[0].value != '') {
      _demoItems[1].query = entryMap[_demoItems[0].value].keys.toList();
    }
    return new Scaffold(
      body: new SingleChildScrollView(
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
    );
  }
}
