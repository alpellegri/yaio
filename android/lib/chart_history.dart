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
  static double ymax = 300.0;
  List<THEntry> entryList = new List();
  DatabaseReference _entryRef;
  StreamSubscription<Event> _onAddSubscription;
  static Chart chart = new Chart();

  CustomPaint _myCustomPainter = new CustomPaint(
    size: new Size(xmax, ymax),
    painter: chart,
  );

  _ChartHistoryState() {
    _entryRef = FirebaseDatabase.instance.reference().child(kTHRef);
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

    final Paint paintTH = new Paint()..color = Colors.white;

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
      delta = 0.1 * (tMax - tMin);
      tMin -= delta;
      tMax += delta;
      delta = 0.1 * (hMax - hMin);
      hMin -= delta;
      hMax += delta;
      double timeRatio = 300.0 / (timeMax - timeMin).toDouble();
      double tRatio = 100.0 / (tMax - tMin).toDouble();
      double hRatio = 100.0 / (hMax - hMin).toDouble();
      double tOffset = 0.0;
      double hOffset = 200.0;

      // grid
      _drawLines(canvas, tOffset, tMin, tMax, tRatio, 8);
      _drawLabels(canvas, tOffset, timeMin, timeMax, timeRatio, 8);
      _drawLines(canvas, hOffset, hMin, hMax, hRatio, 8);
      _drawLabels(canvas, hOffset, timeMin, timeMax, timeRatio, 8);

      // print('$timeMax, $timeMin ${timeMax - timeMin}');
      for (int i = 0; i < entryList.length; i++) {
        // print('$i, ${entryList[i].getTime()}');
        if (entryList[i].getTime() > timeMin) {
          double x = timeRatio * (entryList[i].getTime() - timeMin).toDouble();
          // x = i.toDouble();
          double t = tOffset - tRatio * (entryList[i].getT() - tMin);
          double h = hOffset - hRatio * (entryList[i].getH() - hMin);
          // canvas.drawLine(new Offset(x, 0.0), new Offset(x, t), paint);
          canvas.drawCircle(new Offset(x, t), 1.5, paintTH);
          canvas.drawCircle(new Offset(x, h), 1.5, paintTH);
        }
      }
    }
  }

  void add(THEntry entry) {
    entryList.add(entry);
  }

  ui.Paragraph _buildNumberLabel(double d) {
    ui.ParagraphBuilder builder = new ui.ParagraphBuilder(
      new ui.ParagraphStyle(
        fontSize: 10.0,
        textAlign: TextAlign.right,
      ),
    )
      ..pushStyle(new ui.TextStyle(color: Colors.amber[200]))
      ..addText(d.toStringAsFixed(1));
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
      ..layout(new ui.ParagraphConstraints(width: 30.0));
    return paragraph;
  }

  void _drawLines(ui.Canvas canvas, double offset, double min, double max,
      double ratio, int step) {
    final Paint paintLine = new Paint()..color = Colors.amber[200];

    double delta = (max - min) / step;
    for (double d = min; d <= max; d += delta) {
      double y = offset - ratio * (d - min);
      canvas.drawLine(new Offset(0.0, y), new Offset(300.0, y), paintLine);
      ui.Paragraph paragraph = _buildNumberLabel(d);
      canvas.drawParagraph(
        paragraph,
        new Offset(-40.0, y - 5),
      );
    }
  }

  void _drawLabels(ui.Canvas canvas, double offset, int min, int max,
      double ratio, int step) {
    final Paint paintLine = new Paint()..color = Colors.amber[200];

    DateTime dtmax = new DateTime.fromMillisecondsSinceEpoch(max);
    DateTime dt = new DateTime.fromMillisecondsSinceEpoch(min);

    // millisecondsSinceEpoch
    while (dt.isBefore(dtmax)) {
      double x = ratio * (dt.millisecondsSinceEpoch - min);
      double y = offset;
      String str = new DateFormat('d MMM').format(dt);
      canvas.drawLine(new Offset(x, y + 10), new Offset(x, y - 0.0), paintLine);

      ui.Paragraph paragraph = _buildDateLabel(str.toString());
      canvas.drawParagraph(
        paragraph,
        new Offset(x + 0, y + 10),
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
