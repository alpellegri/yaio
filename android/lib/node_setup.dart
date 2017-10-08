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

  void send() {
    (_socket != null) ? _socket.add('ciao') : {};
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
  static const String kWsUri = 'ws://192.168.2.1:81';
  ServiceWebSocket ws;
  Icon iconConnStatus;
  bool connStatus;
  Map _fbJsonMap;
  Map _nodeConfigMap = new Map();
  String _nodeConfig = "";
  final TextEditingController _ctrlSSID = new TextEditingController();
  final TextEditingController _ctrlPassword = new TextEditingController();
  final TextEditingController _ctrlFbSecretKey = new TextEditingController();
  final TextEditingController _ctrlFbMsgKey = new TextEditingController();

  _NodeSetupState() {
    ws = new ServiceWebSocket(kWsUri, _openCb, _dataCb, _errorCb, _closeCb);
  }

  @override
  void initState() {
    super.initState();
    configFirefase().then((value) {
      _fbJsonMap = value;
      _nodeConfigMap['firebase_url'] =
          _fbJsonMap['project_info']['firebase_url'];
      _nodeConfigMap['storage_bucket'] =
          _fbJsonMap['project_info']['storage_bucket'];
      print(JSON.encode(_nodeConfigMap));
    });
    connStatus = false;
    iconConnStatus = const Icon(Icons.settings_remote, color: Colors.grey);
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
      body: new Container(
        child: new Card(
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
                controller: _ctrlFbSecretKey,
                decoration: new InputDecoration(
                  hintText: 'Secret Key',
                ),
              ),
              new TextField(
                controller: _ctrlFbMsgKey,
                decoration: new InputDecoration(
                  hintText: 'Messaging Key',
                ),
              ),
              new ListTile(
                leading: const Icon(Icons.show_chart),
                title: const Text('Response'),
                subtitle: new Text('${response}'),
              ),
              new ButtonTheme.bar(
                  // make buttons use the appropriate styles for cards
                  child: new ButtonBar(children: <Widget>[
                new FlatButton(
                  child: new Text('SEND'),
                  onPressed: ws.send,
                ),
              ]))
            ],
          ),
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: (connStatus == false) ? ws.open : ws.close,
        tooltip: 'add',
        child: iconConnStatus,
      ),
    );
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
      iconConnStatus = const Icon(Icons.settings_remote, color: Colors.grey);
    });
  }

  void _closeCb() {
    print('_closeCb');
    setState(() {
      connStatus = false;
      iconConnStatus = const Icon(Icons.settings_remote, color: Colors.grey);
    });
  }
}
