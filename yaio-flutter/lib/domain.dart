import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'device2.dart';
import 'data_io.dart';
import 'exec.dart';
import 'firebase_utils.dart';
import 'entries.dart';
import 'chart_history.dart';
import 'ui_data_io.dart';
import 'drawer.dart';

class Domain extends StatefulWidget {
  final String domain;

  Domain({Key key, this.domain}) : super(key: key);

  @override
  _DomainState createState() => new _DomainState();
}

class _DomainState extends State<Domain> {
  List<IoEntry> entryList = new List();
  DatabaseReference _rootRef;
  StreamSubscription<Event> _onRootAddSubscription;
  StreamSubscription<Event> _onRootEditedSubscription;
  StreamSubscription<Event> _onRootRemoveSubscription;
  Map<String, dynamic> _map = new Map<String, dynamic>();
  DatabaseReference _dataRef;
  StreamSubscription<Event> _onDataAddSubscription;
  StreamSubscription<Event> _onDataChangedSubscription;
  StreamSubscription<Event> _onDataRemoveSubscription;
  final NavDrawer drawer = new NavDrawer();

  @override
  void initState() {
    print('_DomainState');
    super.initState();
    _rootRef = FirebaseDatabase.instance
        .reference()
        .child(getRootRef())
        .child(widget.domain);
    _onRootAddSubscription = _rootRef.onChildAdded.listen(_onRootEntryAdded);
    _onRootEditedSubscription =
        _rootRef.onChildChanged.listen(_onRootEntryChanged);
    _onRootRemoveSubscription =
        _rootRef.onChildRemoved.listen(_onRootEntryRemoved);

    _dataRef = FirebaseDatabase.instance
        .reference()
        .child(getUserRef())
        .child('obj/data')
        .child(widget.domain);
    _onDataAddSubscription = _dataRef.onChildAdded.listen(_onDataEntryAdded);
    _onDataChangedSubscription =
        _dataRef.onChildChanged.listen(_onDataEntryChanged);
    _onDataRemoveSubscription =
        _dataRef.onChildRemoved.listen(_onDataEntryRemoved);
  }

  @override
  void dispose() {
    super.dispose();
    _onRootAddSubscription.cancel();
    _onRootEditedSubscription.cancel();
    _onRootRemoveSubscription.cancel();
    _onDataAddSubscription.cancel();
    _onDataChangedSubscription.cancel();
    _onDataRemoveSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.domain),
      ),
      drawer: drawer,
      body: Container(
          child: SingleChildScrollView(
              child: new ListView.builder(
        shrinkWrap: true,
        physics: ClampingScrollPhysics(),
        itemCount: _map.keys.length,
        itemBuilder: (context, node) {
          String _node = _map.keys.toList()[node];
          return new DeviceCard(
              domain: widget.domain,
              node: _node,
              value: _map[_node],
              data: entryList);
        },
      ))),
    );
  }

  void _onRootEntryAdded(Event event) {
    // print('_onRootEntryAdded ${event.snapshot.key} ${event.snapshot.value}');
    String domain = event.snapshot.key;
    dynamic value = event.snapshot.value;
    setState(() {
      _map.putIfAbsent(domain, () => value);
    });
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
    setState(() {
      _map.removeWhere((key, value) => key == domain);
    });
  }

  void _onDataEntryAdded(Event event) {
    bool drawWr = event.snapshot.value['drawWr'];
    bool drawRd = event.snapshot.value['drawRd'];
    if ((drawWr == true) || (drawRd == true)) {
      setState(() {
        IoEntry entry = new IoEntry.fromMap(
            _dataRef, event.snapshot.key, event.snapshot.value);
        entryList.add(entry);
      });
    }
  }

  void _onDataEntryChanged(Event event) {
    bool drawWr = event.snapshot.value['drawWr'];
    bool drawRd = event.snapshot.value['drawRd'];
    if ((drawWr == true) || (drawRd == true)) {
      IoEntry oldValue =
          entryList.singleWhere((el) => el.key == event.snapshot.key);
      setState(() {
        entryList[entryList.indexOf(oldValue)] = new IoEntry.fromMap(
            _dataRef, event.snapshot.key, event.snapshot.value);
      });
    }
  }

  void _onDataEntryRemoved(Event event) {
    bool drawWr = event.snapshot.value['drawWr'];
    bool drawRd = event.snapshot.value['drawRd'];
    if ((drawWr == true) || (drawRd == true)) {
      IoEntry oldValue =
          entryList.singleWhere((el) => el.key == event.snapshot.key);
      setState(() {
        entryList.remove(oldValue);
      });
    }
  }
}

class DeviceCard extends StatefulWidget {
  final String domain;
  final String node;
  final dynamic value;
  final List<IoEntry> data;

  DeviceCard({Key key, this.domain, this.node, this.value, this.data})
      : super(key: key);

  @override
  _DeviceCardState createState() => new _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  @override
  Widget build(BuildContext context) {
    bool online = false;
    if ((widget.value['status'] != null) && (widget.value['control'] != null)) {
      DateTime statusTime = new DateTime.fromMillisecondsSinceEpoch(
          int.parse(widget.value['status']['time'].toString()) * 1000);
      DateTime controlTime = new DateTime.fromMillisecondsSinceEpoch(
          int.parse(widget.value['control']['time'].toString()) * 1000);
      Duration diff = statusTime.difference(controlTime);
      online = (diff.inSeconds >= -10);
      /*
      print('${widget.node} $online ----------');
      print(widget.value['status']['time']);
      print(widget.value['control']['time']);
      print(diff.inSeconds);
      */
    }
    // extract only data related to a node
    var query = widget.data.where((e) => (e.owner == widget.node)).toList();
    return new Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        new Container(
          decoration: new BoxDecoration(
              // color: Colors.grey[100],
              ),
          child: new Row(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              const SizedBox(width: 8.0),
              online
                  ? new Icon(Icons.link, color: Colors.green[400])
                  : new Icon(Icons.link_off, color: Colors.grey[400]),
              const SizedBox(width: 8.0),
              new Text(widget.node,
                  style: new TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  )),
              const SizedBox(width: 8.0),
              new Expanded(
                child: new Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    new PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        onSelected: _routeSelection,
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuItem<String>>[
                              new PopupMenuItem<String>(
                                  value: 'Settings',
                                  child: const Text('Settings')),
                              new PopupMenuItem<String>(
                                  value: 'Data IO',
                                  child: const Text('Data IO')),
                              new PopupMenuItem<String>(
                                  value: 'Routine',
                                  child: const Text('Routine')),
                            ]),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8.0),
        new ListView.builder(
          shrinkWrap: true,
          physics: BouncingScrollPhysics(),
          itemCount: query.length,
          itemBuilder: (buildContext, index) {
            if (query[index].drawWr == true) {
              return new InkWell(
                onTap: () {
                  _openEntryDialog(widget.node, query[index]);
                },
                child: new DataItemWidget(query[index]),
              );
            } else if (query[index].enLog == true) {
              return new InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      new MaterialPageRoute(
                        builder: (BuildContext context) => new ChartHistory(
                            domain: widget.domain,
                            node: widget.node,
                            name: query[index].key),
                        fullscreenDialog: true,
                      ));
                },
                child: new DataItemWidget(query[index]),
              );
            } else {
              return DataItemWidget(query[index]);
            }
          },
        ),
        new Divider(
            color: Colors.black12, thickness: .6, indent: 8, endIndent: 8),
      ],
    );
  }

  _routeSelection(String string) {
    if (string == 'Settings') {
      Navigator.push(
        context,
        new MaterialPageRoute(
          builder: (BuildContext context) => new DeviceConfig(
              domain: widget.domain, node: widget.node, value: widget.value),
          fullscreenDialog: true,
        ),
      );
    } else if (string == 'Data IO') {
      Navigator.push(
        context,
        new MaterialPageRoute(
          builder: (BuildContext context) =>
              new DataIO(domain: widget.domain, node: widget.node),
          fullscreenDialog: true,
        ),
      );
    } else if (string == 'Routine') {
      Navigator.push(
        context,
        new MaterialPageRoute(
          builder: (BuildContext context) =>
              new Exec(domain: widget.domain, node: widget.node),
          fullscreenDialog: true,
        ),
      );
    }
  }

  void _openEntryDialog(String node, IoEntry entry) {
    showDialog<Null>(
      context: context,
      builder: (BuildContext context) {
        return new DataIoShortDialogWidget(
            domain: widget.domain, node: node, data: entry);
      },
    );
  }
}
