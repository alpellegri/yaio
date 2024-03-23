import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_utils.dart';
import 'const.dart';

class Device extends StatefulWidget {
  const Device({
    super.key,
    required this.title,
  });
  static const String routeName = '/device';
  final String title;

  @override
  _DeviceState createState() => _DeviceState();
}

class _DeviceState extends State<Device> {
  @override
  void initState() {
    super.initState();
    print('_DeviceState');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ExpansionPanelsDemo(),
    );
  }
}

class ListItem extends StatelessWidget {
  final String value;
  final FormFieldState<String> field;

  ListItem({
    super.key,
    required this.value,
    required this.field,
  });

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
      Radio<String>(
        value: value,
        groupValue: field.value,
        onChanged: field.didChange,
      ),
      Text(value),
    ]);
  }
}

typedef Widget DemoItemBodyBuilder<T>(DemoItem<T> item);
typedef String ValueToString<T>(T value);

class DualHeaderWithHint extends StatelessWidget {
  const DualHeaderWithHint({
    super.key,
    required this.name,
    required this.value,
    required this.hint,
    required this.showHint,
  });

  final String name;
  final String value;
  final String hint;
  final bool showHint;

  Widget _crossFade(Widget first, Widget second, bool isExpanded) {
    return AnimatedCrossFade(
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
    return Row(children: <Widget>[
      Expanded(
        child: Container(
          margin: const EdgeInsets.only(left: 24.0),
          child: Text(name),
        ),
      ),
      Container(
          margin: const EdgeInsets.only(left: 24.0),
          child: _crossFade(Text(value), Text(hint), showHint))
    ]);
  }
}

class CollapsibleBody extends StatelessWidget {
  const CollapsibleBody({
    super.key,
    this.margin = EdgeInsets.zero,
    required this.child,
    required this.isEditMode,
    required this.onSelect,
    required this.onAdd,
    required this.onRemove,
  });

  final EdgeInsets margin;
  final Widget child;
  final bool isEditMode;
  final VoidCallback onSelect;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    Row widget;
    if (isEditMode == false) {
      widget = Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            TextButton(onPressed: onRemove, child: const Text('REMOVE')),
            TextButton(onPressed: onAdd, child: const Text('ADD')),
            TextButton(onPressed: onSelect, child: const Text('SELECT')),
          ]);
    } else {
      widget = Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            TextButton(onPressed: onSelect, child: const Text('SAVE')),
          ]);
    }

    return Column(children: <Widget>[
      Container(
          margin: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 0.0) -
              margin,
          child: child),
      widget,
    ]);
  }
}

class DemoItem<T> {
  DemoItem({
    required this.name,
    required this.value,
    required this.hint,
    required this.builder,
    required this.valueToString,
  }) : textController = TextEditingController(text: valueToString(value));

  List query = [];
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
      return DualHeaderWithHint(
          name: name,
          value: valueToString(value),
          hint: hint,
          showHint: isExpanded);
    };
  }

  Widget build() => builder(this);
}

class ExpansionPanelsDemo extends StatefulWidget {
  const ExpansionPanelsDemo({super.key});

  @override
  _ExpansionPanelsDemoState createState() => _ExpansionPanelsDemoState();
}

class _ExpansionPanelsDemoState extends State<ExpansionPanelsDemo> {
  final bool _nodeNeedUpdate = false;

  late DatabaseReference _rootRef;
  late StreamSubscription<DatabaseEvent> _onAddSubscription;
  late StreamSubscription<DatabaseEvent> _onEditedSubscription;
  late StreamSubscription<DatabaseEvent> _onRemoveSubscription;
  late List<DemoItem<dynamic>> _demoItems;
  Map<String, dynamic> entryMap = <String, dynamic>{};
  late String _ctrlDomainName;
  late String _ctrlNodeName;
  bool _isNeedCreate = true;

  @override
  void initState() {
    super.initState();
    _rootRef = FirebaseDatabase.instance.ref().child(getRootRef()!);
    _onAddSubscription = _rootRef.onChildAdded.listen(_onRootEntryAdded);
    _onEditedSubscription = _rootRef.onChildChanged.listen(_onRootEntryChanged);
    _onRemoveSubscription = _rootRef.onChildRemoved.listen(_onRootEntryRemoved);
    _ctrlDomainName = getDomain() ?? '';
    _ctrlNodeName = getNode() ?? '';

    _demoItems = <DemoItem<dynamic>>[
      DemoItem<String>(
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

            return Form(child: Builder(builder: (BuildContext context) {
              return CollapsibleBody(
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
                    ? (TextFormField(
                        controller: item.textController,
                        decoration: InputDecoration(
                          hintText: item.hint,
                          labelText: item.name,
                        ),
                        onSaved: (String? value) {
                          item.value = value!;
                        },
                      ))
                    : (FormField<String>(
                        initialValue: item.value,
                        onSaved: (String? result) {
                          item.value = result!;
                        },
                        builder: (FormFieldState<String> field) {
                          return ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            shrinkWrap: true,
                            reverse: true,
                            itemCount: item.query.length,
                            itemBuilder: (buildContext, index) {
                              return InkWell(
                                child: ListItem(
                                    value: item.query[index], field: field),
                              );
                            },
                          );
                        })),
              );
            }));
          }),
      DemoItem<String>(
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

            return Form(child: Builder(builder: (BuildContext context) {
              return CollapsibleBody(
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
                    ? (TextFormField(
                        controller: item.textController,
                        decoration: InputDecoration(
                          hintText: item.hint,
                          labelText: item.name,
                        ),
                        onSaved: (String? value) {
                          item.value = value!;
                        },
                      ))
                    : (FormField<String>(
                        initialValue: item.value,
                        onSaved: (String? result) {
                          item.value = result!;
                        },
                        builder: (FormFieldState<String> field) {
                          return ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            shrinkWrap: true,
                            reverse: true,
                            itemCount: item.query.length,
                            itemBuilder: (buildContext, index) {
                              return InkWell(
                                child: ListItem(
                                    value: item.query[index], field: field),
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

    return SingleChildScrollView(
      child: Container(
          margin: const EdgeInsets.all(16.0),
          child: ExpansionPanelList(
              expansionCallback: (int index, bool isExpanded) {
                setState(() {
                  _demoItems[index].isExpanded = !isExpanded;
                });
              },
              children: _demoItems.map((DemoItem<dynamic> item) {
                return ExpansionPanel(
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
    String root = getRootRef()!;
    String dataSource = '$root/$domain/$node/control';
    print(dataSource);
    dataRef = FirebaseDatabase.instance.ref().child('$dataSource/reboot');
    dataRef.set(kNodeUpdate);
    DateTime now = DateTime.now();
    dataRef = FirebaseDatabase.instance.ref().child('$dataSource/time');
    dataRef.set(now.millisecondsSinceEpoch ~/ 1000);
  }

  void _onRootEntryAdded(DatabaseEvent event) {
    // print('_onRootEntryAdded ${event.snapshot.key} ${event.snapshot.value}');
    // print(_nodeNeedUpdate);
    String domain = event.snapshot.key!;
    dynamic v = event.snapshot.value;
    if (_nodeNeedUpdate == true) {
      // value contain a map of nodes, each key is the name of the node
      v.forEach((node, v) {
        _nodeUpdate(domain, node);
      });
    }

    setState(() {
      // print(event.snapshot.key);
      entryMap.putIfAbsent(event.snapshot.key!, () => event.snapshot.value);
      _updateItemMenu();
    });
  }

  void _onRootEntryChanged(DatabaseEvent event) {
    // print('_onRootEntryChanged ${event.snapshot.key} ${event.snapshot.value}');
    setState(() {
      entryMap[event.snapshot.key!] = event.snapshot.value;
      _updateItemMenu();
    });
  }

  void _onRootEntryRemoved(DatabaseEvent event) {
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
      ref = FirebaseDatabase.instance.ref().child(getControlRef()!);
      ref.set(getControlDefault());
      ref = FirebaseDatabase.instance.ref().child(getStartupRef()!);
      ref.set(getStartupDefault());
    }
  }
}
