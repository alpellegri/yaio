import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_utils.dart';
import 'const.dart';

class Device extends StatefulWidget {
  Device({Key key, this.title}) : super(key: key);
  static const String routeName = '/device';
  final String title;

  @override
  _DeviceState createState() => new _DeviceState();
}

class _DeviceState extends State<Device> {
  @override
  void initState() {
    super.initState();
    print('_DeviceState');
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new ExpansionPanelsDemo(),
    );
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
        onChanged: field.didChange,
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
      firstCurve: const Interval(0.0, 0.75, curve: Curves.fastOutSlowIn),
      secondCurve: const Interval(0.25, 1.0, curve: Curves.fastOutSlowIn),
      sizeCurve: Curves.fastOutSlowIn,
      crossFadeState:
          isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Row(children: <Widget>[
      new Expanded(
        child: new Container(
          margin: const EdgeInsets.only(left: 24.0),
          child: new Text(name),
        ),
      ),
      new Container(
          margin: const EdgeInsets.only(left: 24.0),
          child: _crossFade(new Text(value), new Text(hint), showHint))
    ]);
  }
}

class CollapsibleBody extends StatelessWidget {
  const CollapsibleBody({
    this.margin: EdgeInsets.zero,
    this.child,
    this.isEditMode,
    this.onSelect,
    this.onAdd,
    this.onRemove,
  });

  final EdgeInsets margin;
  final Widget child;
  final bool isEditMode;
  final VoidCallback onSelect;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    var widget;
    if (isEditMode == false) {
      widget = new Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            new TextButton(
                onPressed: onRemove,
                child: const Text('REMOVE')),
            new TextButton(
                onPressed: onAdd,
                child: const Text('ADD')),
            new TextButton(
                onPressed: onSelect,
                child: const Text('SELECT')),
          ]);
    } else {
      widget = new Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            new TextButton(
                onPressed: onSelect,
                child: const Text('SAVE')),
          ]);
    }

    return new Column(children: <Widget>[
      new Container(
          margin: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 0.0) -
              margin,
          child: child),
      widget,
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
  }) : textController = new TextEditingController(text: valueToString(value));

  List query = new List();
  final String name;
  final String hint;
  final TextEditingController textController;
  final DemoItemBodyBuilder<T> builder;
  final ValueToString<T> valueToString;
  T value;
  bool isExpanded = false;
  bool isEditMode = false;

  ExpansionPanelHeaderBuilder get headerBuilder {
    return (BuildContext context, bool isExpanded) {
      return new DualHeaderWithHint(
          name: name,
          value: valueToString(value),
          hint: hint,
          showHint: isExpanded);
    };
  }

  Widget build() => builder(this);
}

class ExpansionPanelsDemo extends StatefulWidget {
  @override
  _ExpansionPanelsDemoState createState() => new _ExpansionPanelsDemoState();
}

class _ExpansionPanelsDemoState extends State<ExpansionPanelsDemo> {
  bool _nodeNeedUpdate = false;

  DatabaseReference _rootRef;
  StreamSubscription<Event> _onAddSubscription;
  StreamSubscription<Event> _onEditedSubscription;
  StreamSubscription<Event> _onRemoveSubscription;
  List<DemoItem<dynamic>> _demoItems;
  Map<String, dynamic> entryMap = new Map<String, dynamic>();
  String _ctrlDomainName;
  String _ctrlNodeName;
  bool _isNeedCreate = true;

  @override
  void initState() {
    super.initState();
    _rootRef = FirebaseDatabase.instance.reference().child(getRootRef());
    _onAddSubscription = _rootRef.onChildAdded.listen(_onRootEntryAdded);
    _onEditedSubscription = _rootRef.onChildChanged.listen(_onRootEntryChanged);
    _onRemoveSubscription = _rootRef.onChildRemoved.listen(_onRootEntryRemoved);
    _ctrlDomainName = getDomain() ?? '';
    _ctrlNodeName = getNode() ?? '';

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
                item.isEditMode = false;
              });
            }

            void add() {
              setState(() {
                item.isEditMode = true;
              });
            }

            return new Form(child: new Builder(builder: (BuildContext context) {
              return new CollapsibleBody(
                onSelect: () {
                  Form.of(context).save();
                  _ctrlDomainName = item.value;
                  close();
                },
                onAdd: () {
                  add();
                },
                onRemove: () {
                  if (_isNeedCreate == false) {
                    _rootRef.child(item.value).remove();
                  }
                  setState(() {
                    _ctrlDomainName = '';
                    _ctrlNodeName = '';
                  });
                  close();
                },
                isEditMode: item.isEditMode,
                child: (item.isEditMode == true)
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
                            physics: BouncingScrollPhysics(),
                            shrinkWrap: true,
                            reverse: true,
                            itemCount: item.query.length,
                            itemBuilder: (buildContext, index) {
                              return new InkWell(
                                child: new ListItem(item.query[index], field),
                              );
                            },
                          );
                        })),
              );
            }));
          }),
      new DemoItem<String>(
          name: 'Device',
          value: _ctrlNodeName,
          hint: 'Select Device',
          valueToString: (String location) => location,
          builder: (DemoItem<String> item) {
            void close() {
              setState(() {
                item.isExpanded = false;
                item.isEditMode = false;
              });
            }

            void add() {
              setState(() {
                item.isEditMode = true;
              });
            }

            return new Form(child: new Builder(builder: (BuildContext context) {
              return new CollapsibleBody(
                onSelect: () {
                  Form.of(context).save();
                  _ctrlNodeName = item.value;
                  _changePreferences();
                  close();
                },
                onAdd: () {
                  add();
                },
                onRemove: () {
                  if (_isNeedCreate == false) {
                    _rootRef.child(_ctrlDomainName).child(item.value).remove();
                  }
                  setState(() {
                    _ctrlNodeName = '';
                  });
                  close();
                },
                isEditMode: item.isEditMode,
                child: (item.isEditMode == true)
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
                            physics: BouncingScrollPhysics(),
                            shrinkWrap: true,
                            reverse: true,
                            itemCount: item.query.length,
                            itemBuilder: (buildContext, index) {
                              return new InkWell(
                                child: new ListItem(item.query[index], field),
                              );
                            },
                          );
                        })),
              );
            }));
          }),
    ];
  }

  @override
  void dispose() {
    super.dispose();
    _onAddSubscription.cancel();
    _onEditedSubscription.cancel();
    _onRemoveSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    _isNeedCreate = _updateItemMenu();
    print('_isNeedCreate $_isNeedCreate');

    return new SingleChildScrollView(
      child: new Container(
          margin: const EdgeInsets.all(16.0),
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
                    body: item.build());
              }).toList())),
    );
  }

  bool _updateItemMenu() {
    bool ret = true;
    var keyList = entryMap.keys.toList();
    setState(() {
      _demoItems[0].query = keyList;
    });
    var keyValue = _demoItems[0].value;
    if (keyList.contains(keyValue)) {
      var keyList2 = entryMap[keyValue].keys.toList();
      setState(() {
        _demoItems[1].query = keyList2;
      });
      var keyValue2 = _demoItems[1].value;
      ret = !keyList2.contains(keyValue2);
    }
    return ret;
  }

  void _nodeUpdate(String domain, String node) {
    DatabaseReference dataRef;
    String root = getRootRef();
    String dataSource = '$root/$domain/$node/control';
    print(dataSource);
    dataRef = FirebaseDatabase.instance.reference().child('$dataSource/reboot');
    dataRef.set(kNodeUpdate);
    DateTime now = new DateTime.now();
    dataRef = FirebaseDatabase.instance.reference().child('$dataSource/time');
    dataRef.set(now.millisecondsSinceEpoch ~/ 1000);
  }

  void _onRootEntryAdded(Event event) {
    // print('_onRootEntryAdded ${event.snapshot.key} ${event.snapshot.value}');
    // print(_nodeNeedUpdate);
    var domain = event.snapshot.key;
    var v = event.snapshot.value;
    if (_nodeNeedUpdate == true) {
      // value contain a map of nodes, each key is the name of the node
      v.forEach((node, v) {
        _nodeUpdate(domain, node);
      });
    }

    setState(() {
      // print(event.snapshot.key);
      entryMap.putIfAbsent(event.snapshot.key, () => event.snapshot.value);
      _updateItemMenu();
    });
  }

  void _onRootEntryChanged(Event event) {
    // print('_onRootEntryChanged ${event.snapshot.key} ${event.snapshot.value}');
    setState(() {
      entryMap[event.snapshot.key] = event.snapshot.value;
      _updateItemMenu();
    });
  }

  void _onRootEntryRemoved(Event event) {
    // print('_onRootEntryRemoved ${event.snapshot.key} ${event.snapshot.value}');
    setState(() {
      entryMap.remove(event.snapshot.key);
    });
    _updateItemMenu();
  }

  void _changePreferences() {
    savePreferencesDN(_ctrlDomainName, _ctrlNodeName);
    if (_isNeedCreate == true) {
      DatabaseReference ref;
      ref = FirebaseDatabase.instance.reference().child(getControlRef());
      ref.set(getControlDefault());
      ref = FirebaseDatabase.instance.reference().child(getStartupRef());
      ref.set(getStartupDefault());
    }
  }
}
