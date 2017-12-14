import 'dart:async';

import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'drawer.dart';
import 'entries.dart';
import 'const.dart';

import 'dart:ui' as ui;
import 'dart:math' as math;

class ChartHistory extends StatefulWidget {
  ChartHistory({Key key, this.title}) : super(key: key);

  static const String routeName = '/chart_history';

  final String title;

  @override
  _ChartHistoryState createState() => new _ChartHistoryState();
}

class _ChartHistoryState extends State<ChartHistory> {
  static double xmax = 300.0;
  static double ymax = 600.0;
  List<THEntry> entryList = new List();
  DatabaseReference _entryRef;
  StreamSubscription<Event> _onAddSubscription;
  static Chart chart = new Chart();

  CustomPaint _myCustomPainter = new CustomPaint(
    size: new Size(xmax, ymax),
    painter: chart,
  );

  _ChartHistoryState() {
    _entryRef = FirebaseDatabase.instance.reference().child(dTHRef);
    _onAddSubscription = _entryRef.onChildAdded.listen(_onEntryAdded);
  }

  @override
  void initState() {
    super.initState();
    print('_ChartHistoryState');
  }

  @override
  void dispose() {
    super.dispose();
    _onAddSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      drawer: drawer,
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new Container(
        alignment: FractionalOffset.center,
        child: _myCustomPainter,
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _onFloatingActionButtonPressed,
        tooltip: 'add',
        child: new Icon(Icons.add),
      ),
    );
  }

  void _onFloatingActionButtonPressed() {}

  void _onEntryAdded(Event event) {
    setState(() {
      chart.add(new THEntry.fromSnapshot(_entryRef, event.snapshot));
    });
  }
}

class Chart extends CustomPainter {
  List<THEntry> entryList = new List();

  @override
  void paint(Canvas canvas, Size size) {
    int timeMin;
    int timeMax;
    double tMin;
    double tMax;
    double hMin;
    double hMax;

    final Paint paintT = new Paint()..color = Colors.amber[300];
    final Paint paintH = new Paint()..color = Colors.amber[100];

    if (entryList.length > 0) {
      DateTime dtmax = new DateTime.now();
      DateTime dtmin = dtmax;
      dtmin = dtmax.subtract(new Duration(
        days: 7,
        hours: dtmin.hour,
        minutes: dtmin.minute,
        seconds: dtmin.second,
        milliseconds: dtmin.millisecond,
      ));
      timeMin = dtmin.millisecondsSinceEpoch;
      timeMax = dtmax.millisecondsSinceEpoch;
      tMin = entryList
          .where((entry) => entry.time > timeMin)
          .map((entry) => entry.t)
          .reduce(math.min);
      tMax = entryList
          .where((entry) => entry.time > timeMin)
          .map((entry) => entry.t)
          .reduce(math.max);
      hMin = entryList
          .where((entry) => entry.time > timeMin)
          .map((entry) => entry.h)
          .reduce(math.min);
      hMax = entryList
          .where((entry) => entry.time > timeMin)
          .map((entry) => entry.h)
          .reduce(math.max);

      double delta;
      delta = 0.1 * (timeMax - timeMin).toDouble();
      timeMin -= delta.toInt();
      timeMax += delta.toInt();
      double timeRatio = 300.0 / (timeMax - timeMin).toDouble();
      delta = 0.1 * (tMax - tMin);
      tMin -= delta;
      tMax += delta;
      double tRatio = 150.0 / (tMax - tMin).toDouble();
      delta = 0.1 * (hMax - hMin);
      hMin -= delta;
      hMax += delta;
      double hRatio = 150.0 / (hMax - hMin).toDouble();
      double tOffset = 200.0;
      double hOffset = 450.0;

      // grid
      _drawLines(canvas, tOffset, 0.0, 150.0, 12);
      _drawLabelsY(canvas, 1, tOffset, tMin, tMax, tRatio, 12, '°C');
      _drawLabelsX(canvas, tOffset, timeMin, timeMax, timeRatio, 8);
      // grid
      _drawLines(canvas, hOffset, 0.0, 150.0, 12);
      _drawLabelsY(canvas, 1, hOffset, hMin, hMax, hRatio, 12, '%');
      _drawLabelsX(canvas, hOffset, timeMin, timeMax, timeRatio, 8);

      // print('$timeMax, $timeMin ${timeMax - timeMin}');
      for (int i = 0; i < entryList.length; i++) {
        // print('$i, ${entryList[i].getTime()}');
        if (entryList[i].getTime() > timeMin) {
          double x = timeRatio * (entryList[i].getTime() - timeMin).toDouble();
          double h = hOffset - hRatio * (entryList[i].getH() - hMin);
          canvas.drawCircle(new Offset(x, h), 1.5, paintH);
          double t = tOffset - tRatio * (entryList[i].getT() - tMin);
          canvas.drawCircle(new Offset(x, t), 1.5, paintT);
        }
      }
    }
  }

  void add(THEntry entry) {
    entryList.add(entry);
  }

  ui.Paragraph _buildNumberLabel(String str) {
    ui.ParagraphBuilder builder = new ui.ParagraphBuilder(
      new ui.ParagraphStyle(
        fontSize: 10.0,
        textAlign: TextAlign.right,
      ),
    )
      ..pushStyle(new ui.TextStyle(color: Colors.amber[200]))
      ..addText(str);
    final ui.Paragraph paragraph = builder.build()
      ..layout(new ui.ParagraphConstraints(width: 30.0));
    return paragraph;
  }

  ui.Paragraph _buildDateLabel(String str) {
    ui.ParagraphBuilder builder = new ui.ParagraphBuilder(
      new ui.ParagraphStyle(
        fontSize: 10.0,
        textAlign: TextAlign.right,
      ),
    )
      ..pushStyle(new ui.TextStyle(color: Colors.amber[200]))
      ..addText(str);
    final ui.Paragraph paragraph = builder.build()
      ..layout(new ui.ParagraphConstraints(width: 25.0));
    return paragraph;
  }

  void _drawLines(
      ui.Canvas canvas, double offset, double min, double max, int step) {
    final Paint paintLine = new Paint()..color = Colors.amber[200];

    double delta = (max - min) / step;
    double d = min;
    for (int i = 0; i <= step; i++) {
      double y = offset - (d - min);
      canvas.drawLine(new Offset(0.0, y), new Offset(300.0, y), paintLine);
      d += delta;
    }
  }

  void _drawLabelsY(ui.Canvas canvas, int type, double offset, double min,
      double max, double ratio, int step, String unit) {
    double delta = (max - min) / step;
    double d = min;
    for (int i = 0; i <= step; i++) {
      double y = offset - ratio * (d - min);
      ui.Paragraph paragraph = _buildNumberLabel(d.toStringAsFixed(1) + unit);
      canvas.drawParagraph(
        paragraph,
        new Offset(-40.0 + 350 * type, y - 5),
      );
      d += delta;
    }
  }

  void _drawLabelsX(ui.Canvas canvas, double offset, int min, int max,
      double ratio, int step) {
    final Paint paintLine = new Paint()..color = Colors.amber[200];

    DateTime dtmax = new DateTime.fromMillisecondsSinceEpoch(max);
    DateTime dt = new DateTime.fromMillisecondsSinceEpoch(min);

    DateTime now = new DateTime.now();
    while (dt.isBefore(dtmax) && dt.isBefore(now)) {
      double x = ratio * (dt.millisecondsSinceEpoch - min);
      double y = offset;
      String str = new DateFormat('d\nMMM').format(dt);
      canvas.drawLine(new Offset(x, y + 10), new Offset(x, y - 0.0), paintLine);

      ui.Paragraph paragraph = _buildDateLabel(str.toString());
      canvas.drawParagraph(
        paragraph,
        new Offset(x - 0.0, y + 15),
      );

      dt = dt.add(new Duration(days: 1));
    }
  }

  @override
  bool shouldRepaint(Chart oldDelegate) {
    // Since this Line painter has no fields, it always paints
    // the same thing, and therefore we return false here. If
    // we had fields (set from the constructor) then we would
    // return true if any of them differed from the same
    // fields on the oldDelegate.
    return false;
  }
}
