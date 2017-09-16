// Copyright 2017, the Flutter project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Database Example',
      home: new MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final DatabaseReference _controlRef =
    FirebaseDatabase.instance.reference().child('control');
  final DatabaseReference _statusRef =
    FirebaseDatabase.instance.reference().child('status');
  final DatabaseReference _startupRef =
    FirebaseDatabase.instance.reference().child('startup');

  StreamSubscription<Event> _controlSubscription;
  StreamSubscription<Event> _statusSubscription;
  StreamSubscription<Event> _startupSubscription;
  bool _anchorToBottom = false;

  Map<String, Object> _control = {
    'alarm': false,
    'radio_learn': false,
    'radio_update': false,
    'reboot': false,
    'time': 0,
  };
  Map<String, Object> _status = {
    'alarm': false,
    'heap': 0,
    'humidity': 0,
    'monitor': false,
    'temperature': 0,
    'time': 0,
  };
  Map<String, Object> _startup = {
    'bootcnt': 0,
    'time': 0,
    'version': '',
  };

  @override
  void initState() {
    super.initState();

    FirebaseDatabase.instance.setPersistenceEnabled(true);
    FirebaseDatabase.instance.setPersistenceCacheSizeBytes(10000000);
    _controlRef.keepSynced(true);
    _controlSubscription = _controlRef.onValue.listen((Event event) {
      setState(() {
        _control = event.snapshot.value;
      });
    });
    _statusSubscription = _statusRef.onValue.listen((Event event) {
      setState(() {
        _status = event.snapshot.value;
      });
    });
    _startupSubscription = _startupRef.onValue.listen((Event event) {
      setState(() {
        _startup = event.snapshot.value;
        print('startup onValue: $_startup');
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _statusSubscription.cancel();
    _controlSubscription.cancel();
  }

  Future<Null> _increment() async {
    await FirebaseAuth.instance.signInAnonymously();
    // TODO(jackson): This illustrates a case where transactions are needed
    final DataSnapshot snapshot = await _controlRef.once();
    setState(() {
      _control = snapshot.value;
      bool _alarm = _control['alarm'];
      _alarm = !_alarm;
      _control['alarm'] = _alarm;
      final DateTime _now = new DateTime.now();
      // update current time to notify change
      _control['time'] = (_now.millisecondsSinceEpoch/1000).round();
      _controlRef.set(_control);
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: const Text('uHome'),
        actions: <Widget>[
          new IconButton(
            icon: new Icon(Icons.playlist_play),
            tooltip: 'Air it',
            onPressed: _increment,
          ),
          new IconButton(
            icon: new Icon(Icons.playlist_add),
            tooltip: 'Restitch it',
            onPressed: _increment,
          ),
          new IconButton(
            icon: new Icon(Icons.playlist_add_check),
            tooltip: 'Repair it',
            onPressed: _increment,
          ),
        ],
      ),
      body: new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Container(
            child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                new Container(
                  padding: const EdgeInsets.all(8.0),
                  child: new Text('alarm: ${_status["alarm"]}',
                      textAlign: TextAlign.left, softWrap: true),
                ),
                new Container(
                  padding: const EdgeInsets.all(8.0),
                  child: new Text('Temperature: ${_status["temperature"]}',
                      textAlign: TextAlign.left, softWrap: true),
                ),
                new Container(
                  padding: const EdgeInsets.all(8.0),
                  child: new Text('Humidity: ${_status["humidity"]}',
                      textAlign: TextAlign.left, softWrap: true),
                ),
                new Container(
                  padding: const EdgeInsets.all(8.0),
                  child: new Text('SW version: ${_startup["version"]}',
                      textAlign: TextAlign.left, softWrap: true),
                ),
              ]
            )
          ),
          new ListTile(
            leading: new Checkbox(
              onChanged: (bool value) {
                setState(() {
                  _anchorToBottom = value;
                });
              },
              value: _anchorToBottom,
            ),
            title: const Text('Anchor to bottom'),
          ),
        ],
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _increment,
        tooltip: 'arm alarm',
        child: new Icon(Icons.power_settings_new),
      ),
    );
  }
}
