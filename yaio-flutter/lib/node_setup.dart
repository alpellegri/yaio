import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'const.dart';
import 'firebase_utils.dart';

class ServiceWebSocket {
  String? _wsUri;
  Function()? _onOpen;
  Function(String)? _onData;
  Function(String)? _onError;
  Function()? _onClose;
  WebSocket? _socket;

  ServiceWebSocket(
    String wsUri,
    Function() onOpen,
    Function(String) onData,
    Function(String) onError,
    Function() onClose,
  ) {
    _wsUri = wsUri;
    _onOpen = onOpen;
    _onData = onData;
    _onError = onError;
    _onClose = onClose;
  }

  Future<void> open() async {
    _socket = await WebSocket.connect(_wsUri!);
    _onOpen!();
    _socket?.listen((value) => _onData!(value),
        onError: (e) => (_socket != null) ? _onError!(e) : {},
        onDone: () => (_socket != null) ? _onClose!() : {},
        cancelOnError: true);
  }

  void send(String value) {
    _socket?.add(value);
  }

  void close() {
    _socket?.close();
  }
}

class NodeSetup extends StatefulWidget {
  final String domain;
  final String node;

  const NodeSetup({
    super.key,
    required this.domain,
    required this.node,
  });

  @override
  _NodeSetupState createState() => _NodeSetupState();
}

class _NodeSetupState extends State<NodeSetup> {
  String response = "";
  late ServiceWebSocket _ws;
  Icon _iconConnStatus = const Icon(Icons.settings_remote);
  final Map _prefs = getPreferences();
  bool _connStatus = false;
  final TextEditingController _ctrlSSID = TextEditingController();
  final TextEditingController _ctrlPassword = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ws = ServiceWebSocket(
      kWsUri,
      _openCb,
      _dataCb,
      _errorCb,
      _closeCb,
    );
    _prefs['domain'] = widget.domain;
    _prefs['nodename'] = widget.node;
    _ctrlSSID.text = _prefs['ssid'] ?? "";
    _ctrlPassword.text = _prefs['password'] ?? "";
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configure ${widget.domain}/${widget.node}'),
      ),
      body: ListView(children: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                const SizedBox(width: 16.0),
                const Icon(Icons.router),
                const SizedBox(width: 32.0),
                Expanded(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                      TextField(
                        controller: _ctrlSSID,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          hintText: 'Access Point Name',
                          labelText: 'WiFi NAME *',
                        ),
                        onChanged: (v) {
                          setState(() {
                            _prefs['ssid'] = v;
                          });
                        },
                      ),
                      const SizedBox(height: 12.0),
                      TextField(
                        controller: _ctrlPassword,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          hintText: 'Access Point Password',
                          labelText: 'WiFi PASSWORD *',
                        ),
                        onChanged: (v) {
                          setState(() {
                            _prefs['password'] = v;
                          });
                        },
                      ),
                      const SizedBox(height: 12.0),
                    ])),
                const SizedBox(width: 32.0),
                TextButton(
                  child: const Text('SAVE'),
                  onPressed: () {
                    savePreferencesSP(_ctrlSSID.text, _ctrlPassword.text);
                  },
                ),
                const SizedBox(width: 16.0),
              ],
            ),
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.developer_board),
              title: Text(widget.domain),
              subtitle: Text(widget.node),
              trailing: TextButton(
                onPressed: _sendParameters,
                child: Text('SUBMIT'),
              ),
            ),
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Configuration file'),
            Text(json.encode(_prefs)),
          ],
        ),
      ]),
      floatingActionButton: FloatingActionButton(
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
