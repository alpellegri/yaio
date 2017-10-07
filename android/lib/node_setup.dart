import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'drawer.dart';

Future<Null> initWebSocket() async {
  final String fbConfig = await rootBundle.loadString('android/app/google-services.json');
  print('mystring - ${fbConfig}');

  print('initWebSocket');
  WebSocket socket = await WebSocket.connect('ws://echo.websocket.org');
  socket.listen((value) {
    print("Received: $value");
  });
  print('initWebSocket - connected');
  socket.add('Hello, World!');
}

class NodeSetup extends StatefulWidget {
  NodeSetup({Key key, this.title}) : super(key: key);

  static const String routeName = '/node_setup';

  final String title;

  @override
  _NodeSetupState createState() => new _NodeSetupState();
}

class _NodeSetupState extends State<NodeSetup> {
  @override
  void initState() {
    super.initState();
    print('_NodeSetupState');
    initWebSocket();
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
      body: new Container(),
      floatingActionButton: new FloatingActionButton(
        onPressed: _onFloatingActionButtonPressed,
        tooltip: 'add',
        child: new Icon(Icons.add),
      ),
    );
  }

  void _onFloatingActionButtonPressed() {}
}
