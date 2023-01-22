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
  for (var v in message.list) {
    Future(() async {
      print(v);
      await message.ref.child(v).remove();
    }).then((_) {
      print('Future is complete');
    });
  }
  // message.list.clear();
}

class ChartHistory extends StatefulWidget {
  final String domain;
  final String node;
  final String name;

  const ChartHistory({
    Key? key,
    required this.domain,
    required this.node,
    required this.name,
  }) : super(key: key);

  @override
  _ChartHistoryState createState() => _ChartHistoryState();
}

class _ChartHistoryState extends State<ChartHistory> {
  late DatabaseReference _entryRef;
  late StreamSubscription<DatabaseEvent> _onValueSub;
  final List<String> _toRemove = [];
  final _kdays = 7;

  final List<List<TimeSeries>> _toDisplayDays = [];
  List<charts.Series<TimeSeries, DateTime>> serieDays = [];
  final List<TimeSeries> _toDisplayLong = [];
  List<charts.Series<TimeSeries, DateTime>> serieLong = [];

  @override
  void initState() {
    super.initState();

    for (var i = 0; i < _kdays; i++) {
      _toDisplayDays.add([]);
      var colorP = charts.MaterialPalette.indigo.shadeDefault;
      var colorD = charts.MaterialPalette.gray.shade500;
      var color = (i == (_kdays - 1)) ? (colorP) : (colorD);
      serieDays.add(charts.Series<TimeSeries, DateTime>(
        id: 'Data ${i}',
        colorFn: (_, __) => color,
        domainFn: (TimeSeries values, _) => values.time,
        measureFn: (TimeSeries values, _) => values.value,
        data: _toDisplayDays[i],
      ));
    }

    serieLong.add(charts.Series<TimeSeries, DateTime>(
      id: 'Data',
      colorFn: (_, __) => charts.MaterialPalette.indigo.shadeDefault,
      domainFn: (TimeSeries values, _) => values.time,
      measureFn: (TimeSeries values, _) => values.value,
      data: _toDisplayLong,
    ));

    print('_ChartHistoryState: ${getLogRef()}/${widget.domain}/${widget.name}');
    _entryRef = FirebaseDatabase.instance
        .ref()
        .child('${getLogRef()}/${widget.domain}/${widget.name}');
    _onValueSub = _entryRef.onValue.listen(_onValue);
  }

  @override
  void dispose() {
    super.dispose();
    _toRemove.clear();
    _onValueSub.cancel();
  }

  @override
  Widget build(BuildContext context) {
    // clean old in a different thread
    if (false) {
      ComputeMessage message = new ComputeMessage(_entryRef, _toRemove);
      compute(clear, message);
    } else {
      if (_toRemove.isNotEmpty) {
        Future(() async {
          print('Running the Future');
          // wait 1s while displaing
          await Future.delayed(const Duration(seconds: 1));
        }).then((_) {
          // print('Future is complete');
          for (var v in _toRemove) {
            Future(() async {
              await _entryRef.child(v).remove();
            }).then((_) {
              // print('Future is complete');
              print(v);
              _toRemove.remove(v);
            });
          }
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
      ),
      body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            (_toDisplayLong.isEmpty)
                ? (Container())
                : (Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      height: 300.0,
                      child: charts.TimeSeriesChart(
                        serieLong,
                        animate: false,
                        // Optionally pass in a [DateTimeFactory] used by the chart. The factory
                        // should create the same type of [DateTime] as the data provided. If none
                        // specified, the default creates local date time.
                        // dateTimeFactory: const charts.LocalDateTimeFactory(),
                        primaryMeasureAxis: const charts.NumericAxisSpec(
                            tickProviderSpec:
                                charts.BasicNumericTickProviderSpec(
                                    zeroBound: false)),
                      ),
                    ),
                  )),
            (_toDisplayDays[0].isEmpty)
                ? (Container())
                : (Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      height: 300.0,
                      child: charts.TimeSeriesChart(
                        serieDays,
                        animate: false,
                        // Optionally pass in a [DateTimeFactory] used by the chart. The factory
                        // should create the same type of [DateTime] as the data provided. If none
                        // specified, the default creates local date time.
                        // dateTimeFactory: const charts.LocalDateTimeFactory(),
                        primaryMeasureAxis: const charts.NumericAxisSpec(
                            tickProviderSpec:
                                charts.BasicNumericTickProviderSpec(
                                    zeroBound: false)),
                      ),
                    ),
                  ))
          ]),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFloatingActionButtonPressed,
        tooltip: 'delete',
        child: const Icon(Icons.delete),
      ),
    );
  }

  void _onValue(DatabaseEvent event) {
    // print('_onValue ${event.snapshot.key} ${event.snapshot.value}');
    dynamic data = event.snapshot.value;

    _toRemove.clear();
    for (var i = 0; i < _kdays; i++) {
      _toDisplayDays[i].clear();
    }
    _toDisplayLong.clear();

    final now = DateTime.now();
    final setpoint =
        DateTime(now.year, now.month, now.day, 23, 59, 59, 999, 999);
    // print(setpoint);
    data.forEach((k, v) {
      // print('value: ${v.toString()}');
      DateTime dt = DateTime.fromMillisecondsSinceEpoch(v['t'] * 1000);
      DateTime limit = now.subtract(Duration(days: _kdays));
      if (dt.isAfter(limit) == true) {
        _toDisplayLong.add(TimeSeries(dt, (v['v'].toDouble())));
      } else {
        // add object to be removed
        // print('el $k ${v['t']} ${v['v']}');
        _toRemove.add(k);
      }

      var i = 0;
      var found = 0;
      while ((i < _kdays) && (found == 0)) {
        DateTime limitUp = setpoint.subtract(Duration(days: (i)));
        DateTime limitLow = setpoint.subtract(Duration(days: (i + 1)));
        if ((dt.isAfter(limitLow) == true) && (dt.isBefore(limitUp) == true)) {
          found = 1;
          _toDisplayDays[(_kdays - 1) - i]
              .add(TimeSeries(dt.add(Duration(days: i)), (v['v'].toDouble())));
        }
        i++;
      }
    });

    setState(() {
      if (_toDisplayLong.isNotEmpty) {
        _toDisplayLong.sort((a, b) => a.time.compareTo(b.time));
      }
      for (var i = 0; i < _kdays; i++) {
        if (_toDisplayDays[i].isNotEmpty) {
          _toDisplayDays[i].sort((a, b) => a.time.compareTo(b.time));
        }
      }
    });
  }

  void _onFloatingActionButtonPressed() {
    _entryRef.remove();
    setState(() {
      for (var i = 0; i < _kdays; i++) {
        _toDisplayDays[i].clear();
      }
    });
  }
}

/// Sample time series data type.
class TimeSeries {
  final DateTime time;
  final double value;

  TimeSeries(this.time, this.value);
}
