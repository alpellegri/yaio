import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'node_setup.dart';
import 'firebase_utils.dart';
import 'const.dart';

class DeviceConfig extends StatefulWidget {
  final String domain;
  final String node;
  final dynamic value;

  const DeviceConfig({
    super.key,
    required this.domain,
    required this.node,
    this.value,
  });

  @override
  _DeviceConfigState createState() => _DeviceConfigState();
}

class _DeviceConfigState extends State<DeviceConfig> {
  late DatabaseReference _rootRef;
  late DatabaseReference _controlRef;
  late DatabaseReference _statusRef;
  late DatabaseReference _startupRef;
  late StreamSubscription<DatabaseEvent> _controlSub;
  late StreamSubscription<DatabaseEvent> _statusSub;
  late StreamSubscription<DatabaseEvent> _startupSub;

  @override
  void initState() {
    super.initState();

    _rootRef = FirebaseDatabase.instance.ref().child(getRootRef()!);
    _controlRef =
        _rootRef.child(widget.domain).child(widget.node).child('control');
    _statusRef =
        _rootRef.child(widget.domain).child(widget.node).child('status');
    _startupRef =
        _rootRef.child(widget.domain).child(widget.node).child('startup');
    _controlSub = _controlRef.onValue.listen(_onValueControl);
    _statusSub = _statusRef.onValue.listen(_onValueStatus);
    _startupSub = _startupRef.onValue.listen(_onValueStartup);
  }

  @override
  void dispose() {
    super.dispose();
    _controlSub.cancel();
    _statusSub.cancel();
    _startupSub.cancel();
  }

  @override
  Widget build(BuildContext context) {
    print('_DeviceConfigState');
    String diffTime = '';
    DateTime startupTime = DateTime.fromMillisecondsSinceEpoch(
        int.parse(widget.value['startup']['time'].toString()) * 1000);
    if (_checkConnected() == true) {
      DateTime current = DateTime.now();
      DateTime heartbeatTime = DateTime.fromMillisecondsSinceEpoch(
          int.parse(widget.value['status']['time'].toString()) * 1000);
      Duration diff = current.difference(heartbeatTime);
      if (diff.inDays > 0) {
        diffTime = '${diff.inDays} days ago';
      } else if (diff.inHours > 0) {
        diffTime = '${diff.inHours} hours ago';
      } else if (diff.inMinutes > 0) {
        diffTime = '${diff.inMinutes} minutes ago';
      } else if (diff.inSeconds > 0) {
        diffTime = '${diff.inSeconds} seconds ago';
      } else {
        diffTime = 'now';
      }
    }
    bool online = false;

    if ((widget.value['status'] != null) && (widget.value['control'] != null)) {
      DateTime statusTime = DateTime.fromMillisecondsSinceEpoch(
          int.parse(widget.value['status']['time'].toString()) * 1000);
      DateTime controlTime = DateTime.fromMillisecondsSinceEpoch(
          int.parse(widget.value['control']['time'].toString()) * 1000);
      Duration diff = statusTime.difference(controlTime);
      online = (diff.inSeconds >= 0);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.node),
      ),
      body: ListView(children: <Widget>[
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: (false)
                    ? (const Icon(Icons.link_off))
                    : (const Icon(Icons.developer_board)),
                title: const Text('Node'),
                subtitle: Text('${widget.domain}/${widget.node}'),
                trailing: TextButton(
                  child: const Text('CONFIGURE'),
                  onPressed: (false)
                      ? null
                      : () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (BuildContext context) => NodeSetup(
                                    domain: widget.domain, node: widget.node),
                                fullscreenDialog: true,
                              ));
                        },
                ),
              ),
            ]),
        (_checkConnected() == false)
            ? (Container())
            : (Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: (online)
                        ? (Icon(Icons.cloud_done, color: Colors.green[400]))
                        : (Icon(Icons.cloud_queue, color: Colors.red[400])),
                    title: Text('HeartBeat: $diffTime'),
                    subtitle: Text(
                        'Device Memory: ${widget.value['status']["heap"]}'),
                  ),
                  ListTile(
                    leading: (widget.value['control']['reboot'] == kNodeUpdate)
                        ? (const CircularProgressIndicator(
                            value: null,
                          ))
                        : (const Icon(Icons.update)),
                    title: const Text('Update Device'),
                    subtitle: const Text('Configuration'),
                    trailing: TextButton(
                      child: const Text('UPDATE'),
                      onPressed: () {
                        _nodeActionRequest(kNodeUpdate);
                      },
                    ),
                  ),
                  ListTile(
                    leading: (widget.value['control']['reboot'] == kNodeReboot)
                        ? (const CircularProgressIndicator(
                            value: null,
                          ))
                        : (const Icon(Icons.power_settings_new)),
                    title: const Text('PowerUp'),
                    subtitle: Text(startupTime.toString()),
                    trailing: TextButton(
                      child: const Text('RESTART'),
                      onPressed: () {
                        _nodeActionRequest(kNodeReboot);
                      },
                    ),
                  ),
                  ListTile(
                    leading: (widget.value['control']['reboot'] == kNodeFlash)
                        ? (const CircularProgressIndicator(
                            value: null,
                          ))
                        : (const Icon(Icons.cloud_download)),
                    title: const Text('Firmware Version'),
                    subtitle: Text('${widget.value['startup']["version"]}'),
                    trailing: TextButton(
                      child: const Text('UPGRADE'),
                      onPressed: () {
                        _nodeActionRequest(kNodeFlash);
                      },
                    ),
                  ),
                  ListTile(
                    leading: (widget.value['control']['reboot'] == kNodeErase)
                        ? (const CircularProgressIndicator(
                            value: null,
                          ))
                        : (const Icon(Icons.delete)),
                    title: const Text('Erase device'),
                    subtitle: Text(widget.node),
                    trailing: TextButton(
                      child: const Text('ERASE'),
                      onPressed: () {
                        _nodeActionRequest(kNodeErase);
                      },
                    ),
                  ),
                ],
              )),
      ]),
    );
  }

  void _onValueStartup(DatabaseEvent event) {
    setState(() {
      widget.value['startup'] = event.snapshot.value;
    });
  }

  void _onValueControl(DatabaseEvent event) {
    setState(() {
      widget.value['control'] = event.snapshot.value;
    });
  }

  void _onValueStatus(DatabaseEvent event) {
    setState(() {
      widget.value['status'] = event.snapshot.value;
    });
  }

  bool _checkConnected() {
    return (widget.value['status'] != null);
  }

  void _nodeActionRequest(int value) {
    widget.value['control']['reboot'] = value;
    DateTime now = DateTime.now();
    widget.value['control']['time'] = now.millisecondsSinceEpoch ~/ 1000;
    _controlRef.set(widget.value['control']);
  }
}
