import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'entries.dart';
import 'firebase_utils.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class ChartHistory extends StatefulWidget {
  final String domain;
  final String node;
  final String name;

  ChartHistory({Key key, this.domain, this.node, this.name})
      : super(key: key);

  @override
  _ChartHistoryState createState() => new _ChartHistoryState(domain, node, name);
}

class _ChartHistoryState extends State<ChartHistory> {
  final String domain;
  final String node;
  final String name;
  List<LogEntry> entryList = new List();
  DatabaseReference _entryRef;
  StreamSubscription<Event> _onAddSubscription;
  List<charts.Series<TimeSeries, DateTime>> seriesList =
      new List<charts.Series<TimeSeries, DateTime>>();

  _ChartHistoryState(this.domain, this.node, this.name) {
    print('_ChartHistoryState: ${getLogRef()}/$domain/$name');
    _entryRef =
        FirebaseDatabase.instance.reference().child('${getLogRef()}/$domain/$name');
    _onAddSubscription =
        _entryRef.onValue.listen(_onEntryAdded);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _onAddSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(name),
      ),
      body: (seriesList.length == 0)
          ? (const Text(''))
          : (new Padding(
              padding: const EdgeInsets.all(8.0),
              child: new SizedBox(
                height: 300.0,
                child: new charts.TimeSeriesChart(
                  seriesList,
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
    print('_onEntryAdded ${event.snapshot.key} ${event.snapshot.value}');
    List<TimeSeries> data = new List<TimeSeries>();
    if (event.snapshot.key != null) {
      event.snapshot.value.forEach((k, v) {
        DateTime dt = new DateTime.fromMillisecondsSinceEpoch(v['t'] * 1000);
        DateTime start = DateTime.now().subtract(Duration(days: 3));
        if (dt.isAfter(start) == true) {
          data.add(new TimeSeries(dt, (v['v'] + 0.0)));
          data.sort((a, b) => a.time.compareTo(b.time));
        } else {
          // remove the object
          print('remove $k');
          //_entryRef.child(k).remove();
        }
      });

      charts.Series<TimeSeries, DateTime> Serie =
          new charts.Series<TimeSeries, DateTime>(
        id: 'Sales',
        colorFn: (_, __) => charts.MaterialPalette.indigo.shadeDefault,
        domainFn: (TimeSeries sales, _) => sales.time,
        measureFn: (TimeSeries sales, _) => sales.value,
        data: data,
      );
      setState(() {
        seriesList.add(Serie);
      });
    }
  }

  void _onFloatingActionButtonPressed() {
    _entryRef.remove();
    setState(() {
      seriesList.clear();
    });
  }
}

/// Sample time series data type.
class TimeSeries {
  final DateTime time;
  final double value;

  TimeSeries(this.time, this.value);
}
