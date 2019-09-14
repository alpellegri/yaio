import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'const.dart';
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
  final String domain;
  final String node;

  NodeSetup({this.domain, this.node});

  @override
  _NodeSetupState createState() => new _NodeSetupState();
}

class _NodeSetupState extends State<NodeSetup> {
  String response = "";
  ServiceWebSocket _ws;
  Icon _iconConnStatus;
  bool _connStatus;
  Map _prefs;
  final TextEditingController _ctrlSSID = new TextEditingController();
  final TextEditingController _ctrlPassword = new TextEditingController();

  @override
  void initState() {
    super.initState();
    _ws = new ServiceWebSocket(kWsUri, _openCb, _dataCb, _errorCb, _closeCb);
    _connStatus = false;
    _iconConnStatus = const Icon(Icons.settings_remote);
    _prefs = getPreferences();
    _prefs['domain'] = widget.domain;
    _prefs['nodename'] = widget.node;
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
      appBar: new AppBar(
        title: new Text('Configure ${widget.domain}/${widget.node}'),
      ),
      body: new ListView(children: <Widget>[
        new Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            new Container(
              child: new Row(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  const SizedBox(width: 16.0),
                  new Icon(Icons.router),
                  const SizedBox(width: 32.0),
                  new Expanded(
                      child: new Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                        new TextField(
                          controller: _ctrlSSID,
                          decoration: const InputDecoration(
                            border: const UnderlineInputBorder(),
                            hintText: 'Access Point Name',
                            labelText: 'WiFi NAME *',
                          ),
                          onChanged: (v) {
                            setState(() {
                              print('....');
                              _prefs['ssid'] = v;
                            });
                          },
                        ),
                        const SizedBox(height: 12.0),
                        new TextField(
                          controller: _ctrlPassword,
                          decoration: const InputDecoration(
                            border: const UnderlineInputBorder(),
                            hintText: 'Access Point Password',
                            labelText: 'WiFi PASSWORD *',
                          ),
                          onChanged: (v) {
                            setState(() {
                              print('....');
                              _prefs['password'] = v;
                            });
                          },
                        ),
                        const SizedBox(height: 12.0),
                      ])),
                  const SizedBox(width: 32.0),
                  new FlatButton(
                    textColor: Theme.of(context).accentColor,
                    child: const Text('SAVE'),
                    onPressed: () {
                      savePreferencesSP(_ctrlSSID.text, _ctrlPassword.text);
                    },
                  ),
                  const SizedBox(width: 16.0),
                ],
              ),
            ),
          ],
        ),
        new Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new ListTile(
              leading: const Icon(Icons.developer_board),
              title: new Text('${widget.domain}'),
              subtitle: new Text('${widget.node}'),
              trailing: new FlatButton(
                textColor: Theme.of(context).accentColor,
                child: const Text('SUBMIT'),
                onPressed: _sendParameters,
              ),
            ),
          ],
        ),
        new Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new Text('Configuration file'),
            new Text('${json.encode(_prefs)}'),
          ],
        ),
      ]),
      floatingActionButton: new FloatingActionButton(
        onPressed: (_connStatus == false) ? _ws.open : _ws.close,
        tooltip: 'Connect or Disconnect to Device',
        child: _iconConnStatus,
      ),
    );
  }

  void _sendParameters() {
    String config = json.encode(_prefs);
    print(config);
    _ws.send(config);
  }

  void _openCb() {
    print('_openCb');
    setState(() {
      _connStatus = true;
      _iconConnStatus = const Icon(Icons.settings_remote, color: Colors.green);
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
