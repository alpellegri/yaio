import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  static const String kWsUri = 'ws://192.168.2.1';
  ServiceWebSocket ws;
  Icon iconConnStatus;
  bool connStatus;
  Map _nodeConfigMap = new Map();
  final TextEditingController _ctrlSSID = new TextEditingController();
  final TextEditingController _ctrlPassword = new TextEditingController();
  final TextEditingController _ctrlDomain = new TextEditingController();
  final TextEditingController _ctrlNodeName = new TextEditingController();
  SharedPreferences _prefs;
  String _nodeConfigJson;

  _NodeSetupState() {
    ws = new ServiceWebSocket(kWsUri, _openCb, _dataCb, _errorCb, _closeCb);
  }

  Future<Null> initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _nodeConfigJson = _prefs.getString('node_config_json');

    if (_nodeConfigJson != null) {
      _nodeConfigMap = JSON.decode(_nodeConfigJson);
      _ctrlSSID.text = _nodeConfigMap['ssid'];
      _ctrlPassword.text = _nodeConfigMap['password'];
      _ctrlDomain.text = _nodeConfigMap['domain'];
      _ctrlNodeName.text = _nodeConfigMap['nodename'];
    }
    _nodeConfigMap['uid'] = getFirebaseUser().uid;
    _nodeConfigJson = JSON.encode(_nodeConfigMap);
  }

  @override
  void initState() {
    super.initState();
    initSharedPreferences();
    connStatus = false;
    iconConnStatus = const Icon(Icons.settings_remote);
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
              new TextField(
                controller: _ctrlSSID,
                decoration: new InputDecoration(
                  hintText: 'SSID',
                ),
              ),
              new TextField(
                controller: _ctrlPassword,
                decoration: new InputDecoration(
                  hintText: 'Password',
                ),
              ),
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
                  child: new Text('SAVE'),
                  onPressed: _savePreferences,
                ),
              ])),
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
        onPressed: (connStatus == false) ? ws.open : ws.close,
        tooltip: 'Connect or Disconnect to Node',
        child: iconConnStatus,
      ),
    );
  }

  void _sendParameters() {
    ws.send(_nodeConfigJson);
  }

  void _savePreferences() {
    if (_prefs != null) {
      _nodeConfigMap['ssid'] = _ctrlSSID.text;
      _nodeConfigMap['password'] = _ctrlPassword.text;
      _nodeConfigMap['domain'] = _ctrlDomain.text;
      _nodeConfigMap['nodename'] = _ctrlNodeName.text;
      _nodeConfigJson = '';
      _prefs.setString('node_config_json', _nodeConfigJson);
      setState(() {
        _nodeConfigJson = JSON.encode(_nodeConfigMap);
      });
      _prefs.setString('node_config_json', _nodeConfigJson);
    }
  }

  void _openCb() {
    print('_openCb');
    setState(() {
      connStatus = true;
      iconConnStatus = const Icon(Icons.settings_remote, color: Colors.red);
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
      connStatus = false;
      iconConnStatus = const Icon(Icons.settings_remote);
    });
  }

  void _closeCb() {
    print('_closeCb');
    setState(() {
      connStatus = false;
      iconConnStatus = const Icon(Icons.settings_remote);
    });
  }
}
