import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'drawer.dart';

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
            ],
          ),
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: connWebSocket,
        tooltip: 'add',
        child: new Icon(Icons.add),
      ),
    );
  }

  Future<Null> connWebSocket() async {
    // const String wsUri = 'ws://192.168.2.1:81';
    const String wsUri = 'ws://echo.websocket.org';
    print('connWebSocket');
    WebSocket socket = await WebSocket.connect(wsUri);
    socket.listen((value) {
      print("Received: $value");
      setState(() {
        response = value;
        cnt++;
      });
    });
    print('connWebSocket - connected');
    socket.add('[$cnt] Hello, World!');
  }
}
