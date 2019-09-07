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
  StreamSubscription<Event> _onAddSubscription;
  List<charts.Series<TimeSeries, DateTime>> _seriesList =
      new List<charts.Series<TimeSeries, DateTime>>();
  List<String> _toDelete = new List<String>();

  @override
  void initState() {
    super.initState();

    print('_ChartHistoryState: ${getLogRef()}/${widget.domain}/${widget.name}');
    _entryRef = FirebaseDatabase.instance
        .reference()
        .child('${getLogRef()}/${widget.domain}/${widget.name}');
    _onAddSubscription = _entryRef.onValue.listen(_onEntryAdded);
  }

  @override
  void dispose() {
    super.dispose();
    _toDelete.clear();
    _seriesList.clear();
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
            // print(v);
            // _entryRef.child(v).remove();
            Future(() async {
              print(v);
              await _entryRef.child(v).remove();
            }).then((_) {
              //print('Future is complete');
            });
          });
          _toDelete.clear();
        });
      }
    }

    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.name),
      ),
      body: (_seriesList.length == 0)
          ? (new Container())
          : (new Padding(
              padding: const EdgeInsets.all(8.0),
              child: new SizedBox(
                height: 300.0,
                child: new charts.TimeSeriesChart(
                  _seriesList,
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

  void _onEntryAdded(Event event) {
    print('_onEntryAdded');
    List<TimeSeries> data = new List<TimeSeries>();
    if ((event.snapshot.key != null) && (event.snapshot.value != null)) {
      event.snapshot.value.forEach((k, v) {
        // print('el $k ${v['t']} ${v['v']}');
        DateTime dt = new DateTime.fromMillisecondsSinceEpoch(v['t'] * 1000);
        DateTime start = DateTime.now().subtract(Duration(days: 7));
        if (dt.isAfter(start) == true) {
          data.add(new TimeSeries(dt, (v['v'].toDouble())));
          data.sort((a, b) => a.time.compareTo(b.time));
        } else {
          // add object to be removed
          setState(() {
            _toDelete.add(k);
          });
        }
      });

      charts.Series<TimeSeries, DateTime> serie =
          new charts.Series<TimeSeries, DateTime>(
        id: 'Data',
        colorFn: (_, __) => charts.MaterialPalette.indigo.shadeDefault,
        domainFn: (TimeSeries values, _) => values.time,
        measureFn: (TimeSeries values, _) => values.value,
        data: data,
      );
      setState(() {
        _seriesList.clear();
        _seriesList.add(serie);
      });
    }
  }

  void _onFloatingActionButtonPressed() {
    _entryRef.remove();
    setState(() {
      _seriesList.clear();
    });
  }
}

/// Sample time series data type.
class TimeSeries {
  final DateTime time;
  final double value;

  TimeSeries(this.time, this.value);
}
