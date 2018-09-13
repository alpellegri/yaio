import 'package:flutter/material.dart';
import 'device2.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_utils.dart';
import 'entries.dart';
import 'chart_history.dart';
import 'ui_data_io.dart';

class Domain extends StatefulWidget {
  final String domain;
  final dynamic map;

  Domain({Key key, this.domain, this.map}) : super(key: key);

  @override
  _DomainState createState() => new _DomainState(domain, map);
}

class _DomainState extends State<Domain> {
  final String domain;
  dynamic map = new Map<String, dynamic>();
  List<IoEntry> entryList = new List();
  DatabaseReference _dataRef;
  StreamSubscription<Event> _onAddSubscription;
  StreamSubscription<Event> _onChangedSubscription;
  StreamSubscription<Event> _onRemoveSubscription;

  _DomainState(this.domain, this.map);

  @override
  void initState() {
    super.initState();
    _dataRef = FirebaseDatabase.instance
        .reference()
        .child(getUserRef())
        .child('obj/data')
        .child(domain);
    _onAddSubscription = _dataRef.onChildAdded.listen(_onEntryAdded);
    _onChangedSubscription = _dataRef.onChildChanged.listen(_onEntryChanged);
    _onRemoveSubscription = _dataRef.onChildRemoved.listen(_onEntryRemoved);
  }

  @override
  void dispose() {
    super.dispose();
    _onAddSubscription.cancel();
    _onChangedSubscription.cancel();
    _onRemoveSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.domain),
      ),
      body: new ListView.builder(
        shrinkWrap: true,
        physics: ClampingScrollPhysics(),
        itemCount: map.keys.length,
        itemBuilder: (context, node) {
          String _node = map.keys.toList()[node];
          return new DeviceCard(
              domain: domain, name: _node, value: map[_node], data: entryList);
        },
      ),
    );
  }

  void _onEntryAdded(Event event) {
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

  void _onEntryChanged(Event event) {
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

  void _onEntryRemoved(Event event) {
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
  final String name;
  final dynamic value;
  final List<IoEntry> data;

  DeviceCard({Key key, this.domain, this.name, this.value, this.data})
      : super(key: key);

  @override
  _DeviceCardState createState() =>
      new _DeviceCardState(domain, name, value, data);
}

class _DeviceCardState extends State<DeviceCard> {
  final String domain;
  final String name;
  final dynamic value;
  final List<IoEntry> data;

  _DeviceCardState(this.domain, this.name, this.value, this.data);

  @override
  Widget build(BuildContext context) {
    bool online = false;
    if ((value['status'] != null) && (value['control'] != null)) {
      DateTime statusTime = new DateTime.fromMillisecondsSinceEpoch(
          int.parse(value['status']['time'].toString()) * 1000);
      DateTime controlTime = new DateTime.fromMillisecondsSinceEpoch(
          int.parse(value['control']['time'].toString()) * 1000);
      Duration diff = statusTime.difference(controlTime);
      online = (diff.inSeconds >= 0);
    }
    // extract only data related to a node
    var query = data.where((e) => (e.owner == name)).toList();
    return Card(
      elevation: 2.0,
      shape: new BeveledRectangleBorder(
        borderRadius: BorderRadius.circular(0.0),
      ),
      child: Column(
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
                new Text(
                  name,
                  style: new TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  )
                ),
                const SizedBox(width: 8.0),
                new Expanded(
                  child: new Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      new IconButton(
                        padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                        // alignment: Alignment.topRight,
                        icon: Icon(Icons.more_vert, color: Colors.grey),
                        onPressed: () => Navigator.push(
                              context,
                              new MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    new DeviceConfig(
                                        domain: domain,
                                        name: name,
                                        value: value),
                                fullscreenDialog: true,
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8.0),
          // new Divider(height: 0.0),
          new ListView.builder(
            shrinkWrap: true,
            physics: ClampingScrollPhysics(),
            itemCount: query.length,
            itemBuilder: (buildContext, index) {
              if (query[index].drawWr == true) {
                return new InkWell(
                  onTap: () {
                    _openEntryDialog(name, query[index]);
                  },
                  child: new DataItemWidget(query[index]),
                );
              } else if (query[index].enLog == true) {
                return new InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        new MaterialPageRoute(
                          builder: (BuildContext context) =>
                              new ChartHistory(query[index].key),
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
        ],
      ),
    );
  }

  void _openEntryDialog(String node, IoEntry entry) {
    showDialog<Null>(
      context: context,
      builder: (BuildContext context) {
        return new DataIoShortDialogWidget(
            domain: domain, node: node, data: entry);
      },
    );
  }
}
