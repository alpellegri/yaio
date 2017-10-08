import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'drawer.dart';

typedef void CallVoid();
typedef void CallString(String data);

class ServiceWebSocket {
  // static const String wsUri = 'ws://192.168.2.1:81';
  String _WsUri;
  CallVoid _onOpen;
  CallString _onData;
  CallString _onError;
  CallVoid _onClose;

  WebSocket _socket;

  ServiceWebSocket(String wsUri, Function onOpen, Function onData,
      Function onError, Function onClose) {
    _WsUri = wsUri;
    _onOpen = onOpen;
    _onData = onData;
    _onError = onError;
    _onClose = onClose;
    print('ServiceWebSocket c');
  }

  Future<Null> open() async {
    print('connWebSocket');
    _socket = await WebSocket.connect(_WsUri);
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
  static const String kWsUri = 'ws://echo.websocket.org';
  ServiceWebSocket ws;
  Icon iconConnStatus;
  bool connStatus;

  _NodeSetupState() {
    ws = new ServiceWebSocket(kWsUri, _openCb, _dataCb, _errorCb, _closeCb);
  }

  @override
  void initState() {
    super.initState();
    print('_NodeSetupState');
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
