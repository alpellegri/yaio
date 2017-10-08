import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
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
        onError: (e) => _onError(e),
        onDone: () => _onClose(),
        cancelOnError: true);
  }

  send() {
    _socket.add('ciao');
  }

  close() {
    _socket.close();
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
  int cnt = 0;
  String response = "";
  static const String kWsUri = 'ws://192.168.2.1:81'; // kWsUri = 'ws://echo.websocket.org';
  ServiceWebSocket ws;
  Icon iconConnStatus;
  bool connStatus;
  Map _fbJsonMap;
  Map _nodeConfigMap = new Map();
  String _nodeConfig = "";

  _NodeSetupState() {
    ws = new ServiceWebSocket(kWsUri, _openCb, _dataCb, _errorCb, _closeCb);
  }

  @override
  void initState() {
    super.initState();
    configFirefase().then((value) {
      _fbJsonMap = value;
      _nodeConfigMap['firebase_url'] = _fbJsonMap['project_info']['firebase_url'];
      _nodeConfigMap['storage_bucket'] = _fbJsonMap['project_info']['storage_bucket'];
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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
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
                new FlatButton(
                  child: new Text('CLOSE'),
                  onPressed: ws.close,
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
