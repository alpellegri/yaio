import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'drawer.dart';

class ServiceWebSocket {
  // static const String wsUri = 'ws://192.168.2.1:81';
  String _WsUri;
  Function _onOpen;
  Function _onData;
  Function _onError;
  Function _onClose;

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
    print('connWebSocket');
    _socket.listen((value) => _onData,
        onError: (e) => _onError, onDone: () => _onClose, cancelOnError: true);
  }

  send() {
    print('send');
    _socket.add('ciao');
  }

  close() {
    print('close');
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

  _NodeSetupState() {
    ws = new ServiceWebSocket(kWsUri, _open_cb, _data_cb, _error_cb, _close_cb);
  }

  @override
  void initState() {
    super.initState();
    print('_NodeSetupState');
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
              ]))
            ],
          ),
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: ws.open,
        tooltip: 'add',
        child: new Icon(Icons.add),
      ),
    );
  }

  void _open_cb() {
    print('_open_cb');
  }

  void _data_cb(String data) {
    print('_data_cb');
  }

  void _error_cb() {
    print('_error_cb');
  }

  void _close_cb() {
    print('_close_cb');
  }

  Future<Null> connWebSocket() async {
    // const String wsUri = 'ws://192.168.2.1:81';
    const String kWsUri = 'ws://echo.websocket.org';
    print('connWebSocket');
    WebSocket socket = await WebSocket.connect(kWsUri);

    socket.listen((value) {
      print('onData: $value');
      setState(() {
        response = value;
        cnt++;
      });
    }, onError: (e) {
      print('onError: $e');
    }, onDone: () {
      print('onDone:');
    }, cancelOnError: true);
    print('connWebSocket - connected');
    socket.add('[$cnt] Hello, World!');
  }
}
