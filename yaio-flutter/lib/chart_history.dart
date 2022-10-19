import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'firebase_utils.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/foundation.dart';

class ComputeMessage {
  DatabaseReference ref;
  List<String> list;

  ComputeMessage(this.ref, this.list);
}

void clear(ComputeMessage message) {
  print(message.list.length);
  message.list.forEach((v) {
    Future(() async {
      print(v);
      await message.ref.child(v).remove();
    }).then((_) {
      print('Future is complete');
    });
  });
  //message.list.clear();
}

class ChartHistory extends StatefulWidget {
  final String domain;
  final String node;
  final String name;

  ChartHistory({Key key, this.domain, this.node, this.name}) : super(key: key);

  @override
  _ChartHistoryState createState() => new _ChartHistoryState();
}

class _ChartHistoryState extends State<ChartHistory> {
  DatabaseReference _entryRef;
  StreamSubscription<DatabaseEvent> _onAddSubscription;
  List<String> _toDelete = [];
  List<TimeSeries> _toAdd = [];
  List<TimeSeries> _clear = [];
  charts.Series<TimeSeries, DateTime> serie;

  @override
  void initState() {
    super.initState();

    serie = new charts.Series<TimeSeries, DateTime>(
      id: 'Data',
      colorFn: (_, __) => charts.MaterialPalette.indigo.shadeDefault,
      domainFn: (TimeSeries values, _) => values.time,
      measureFn: (TimeSeries values, _) => values.value,
      data: _toAdd,
    );

    print('_ChartHistoryState: ${getLogRef()}/${widget.domain}/${widget.name}');
    _entryRef = FirebaseDatabase.instance
        .reference()
        .child('${getLogRef()}/${widget.domain}/${widget.name}');
    _onAddSubscription = _entryRef.onChildAdded.listen(_onEntryAdded);
  }

  @override
  void dispose() {
    super.dispose();
    _toDelete.clear();
    _onAddSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    // clean old in a different thread
    if (false) {
      ComputeMessage message = new ComputeMessage(_entryRef, _toDelete);
      compute(clear, message);
    } else {
      if (_toDelete.length > 0) {
        Future(() async {
          print('Running the Future');
          // wait 1s while displaing
          await Future.delayed(const Duration(seconds: 1));
        }).then((_) {
          // print('Future is complete');
          _toDelete.forEach((v) {
            Future(() async {
              await _entryRef.child(v).remove();
            }).then((_) {
              // print('Future is complete');
              print(v);
              _toDelete.remove(v);
            });
          });
        });
      }
    }

    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.name),
      ),
      body: (_toAdd.length == 0)
          ? (new Container())
          : (new Padding(
              padding: const EdgeInsets.all(8.0),
              child: new SizedBox(
                height: 300.0,
                child: new charts.TimeSeriesChart(
                  [serie],
                  animate: true,
                  // Optionally pass in a [DateTimeFactory] used by the chart. The factory
                  // should create the same type of [DateTime] as the data provided. If none
                  // specified, the default creates local date time.
                  // dateTimeFactory: const charts.LocalDateTimeFactory(),
                  primaryMeasureAxis: new charts.NumericAxisSpec(
                      tickProviderSpec: new charts.BasicNumericTickProviderSpec(
                          zeroBound: false)),
                ),
              ),
            )),
      floatingActionButton: new FloatingActionButton(
        onPressed: _onFloatingActionButtonPressed,
        tooltip: 'delete',
        child: new Icon(Icons.delete),
      ),
    );
  }

  void _onEntryAdded(DatabaseEvent event) {
    // print('_onEntryAdded ${event.snapshot.key} ${event.snapshot.value}');
    String k = event.snapshot.key;
    dynamic v = event.snapshot.value;
    // print('el $k ${v['t']} ${v['v']}');
    DateTime dt = new DateTime.fromMillisecondsSinceEpoch(v['t'] * 1000);
    DateTime start = DateTime.now().subtract(Duration(days: 7));
    if (dt.isAfter(start) == true) {
      setState(() {
        _toAdd.add(new TimeSeries(dt, (v['v'].toDouble())));
      });
    } else {
      // add object to be removed
      print('el $k ${v['t']} ${v['v']}');
      setState(() {
        _toDelete.add(k);
      });
    }
  }

  void _onFloatingActionButtonPressed() {
    _entryRef.remove();
    setState(() {
      serie = new charts.Series<TimeSeries, DateTime>(
        id: 'Data',
        colorFn: (_, __) => charts.MaterialPalette.indigo.shadeDefault,
        domainFn: (TimeSeries values, _) => values.time,
        measureFn: (TimeSeries values, _) => values.value,
        data: _clear,
      );
    });
  }
}

/// Sample time series data type.
class TimeSeries {
  final DateTime time;
  final double value;

  TimeSeries(this.time, this.value);
}
