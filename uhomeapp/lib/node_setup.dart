import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'const.dart';
import 'drawer.dart';
import 'firebase_utils.dart';

typedef void CallVoid();
typedef void CallString(String data);

class ServiceWebSocket {
  String _wsUri;
  CallVoid _onOpen;
  CallString _onData;
  CallString _onError;
  CallVoid _onClose;
  WebSocket _socket;

  ServiceWebSocket(String wsUri, Function onOpen, Function onData,
      Function onError, Function onClose) {
    _wsUri = wsUri;
    _onOpen = onOpen;
    _onData = onData;
    _onError = onError;
    _onClose = onClose;
  }

  Future<Null> open() async {
    _socket = await WebSocket.connect(_wsUri);
    _onOpen();
    _socket.listen((value) => _onData(value),
        onError: (e) => (_socket != null) ? _onError(e) : {},
        onDone: () => (_socket != null) ? _onClose() : {},
        cancelOnError: true);
  }

  void send(String value) {
    (_socket != null) ? _socket.add(value) : {};
  }

  void close() {
    (_socket != null) ? _socket.close() : {};
  }
}

class NodeSetup extends StatefulWidget {
  NodeSetup({Key key, this.title}) : super(key: key);

  static const String routeName = '/node_setup';

  final String title;

  @override
  _NodeSetupState createState() => new _NodeSetupState();
}

class _NodeSetupState extends State<NodeSetup> {
  String response = "";
  ServiceWebSocket _ws;
  Icon _iconConnStatus;
  bool _connStatus;
  Map _prefs;
  String _nodeConfigJson;
  final TextEditingController _ctrlSSID = new TextEditingController();
  final TextEditingController _ctrlPassword = new TextEditingController();

  _NodeSetupState() {
    _ws = new ServiceWebSocket(kWsUri, _openCb, _dataCb, _errorCb, _closeCb);
  }

  @override
  void initState() {
    super.initState();
    _connStatus = false;
    _iconConnStatus = const Icon(Icons.settings_remote);
    _prefs = getPreferences();
    _nodeConfigJson = JSON.encode(_prefs);
    _ctrlSSID.text = _prefs['ssid'];
    _ctrlPassword.text = _prefs['password'];
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              new ListTile(
                leading: new Icon(Icons.router),
                title: new TextField(
                  controller: _ctrlSSID,
                  decoration: new InputDecoration(
                    hintText: 'SSID',
                  ),
                ),
                subtitle: new TextField(
                  controller: _ctrlPassword,
                  decoration: new InputDecoration(
                    hintText: 'PASSWORD',
                  ),
                ),
                trailing: new ButtonTheme.bar(
                  // make buttons use the appropriate styles for cards
                  child: new ButtonBar(
                    children: <Widget>[
                      new FlatButton(
                        child: new Text('SET'),
                        onPressed: () {
                          savePreferencesSP(_ctrlSSID.text, _ctrlPassword.text);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              new ListTile(
                  leading: new Icon(Icons.device_hub),
                  title: new Text('Domain'),
                  subtitle: new Text(_prefs["domain"])),
              new ListTile(
                  leading: new Icon(Icons.developer_board),
                  title: new Text('Node'),
                  subtitle: new Text(_prefs["nodename"])),
            ],
          ),
        ),
        new Card(
          child: new Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new ListTile(
                leading: const Icon(Icons.show_chart),
                title: const Text('Current Configration'),
                trailing: new ButtonTheme.bar(
                    child: new ButtonBar(children: <Widget>[
                  new FlatButton(
                    child: new Text('SEND TO NODE'),
                    onPressed: _sendParameters,
                  ),
                ])),
              ),
              new Text('$_nodeConfigJson'),
            ],
          ),
        ),
      ]),
      floatingActionButton: new FloatingActionButton(
        onPressed: (_connStatus == false) ? _ws.open : _ws.close,
        tooltip: 'Connect or Disconnect to Node',
        child: _iconConnStatus,
      ),
    );
  }

  void _sendParameters() {
    _ws.send(_nodeConfigJson);
  }

  void _openCb() {
    print('_openCb');
    setState(() {
      _connStatus = true;
      _iconConnStatus = const Icon(Icons.settings_remote, color: Colors.red);
    });
  }

  void _dataCb(String data) {
    print('_dataCb: $data');
    setState(() {
      response = data;
    });
  }

  void _errorCb(String data) {
    print('_errorCb');
    setState(() {
      _connStatus = false;
      _iconConnStatus = const Icon(Icons.settings_remote);
    });
  }

  void _closeCb() {
    print('_closeCb');
    setState(() {
      _connStatus = false;
      _iconConnStatus = const Icon(Icons.settings_remote);
    });
  }
}
