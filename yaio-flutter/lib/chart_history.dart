import 'dart:async';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'entries.dart';
import 'firebase_utils.dart';

import 'dart:ui' as ui;
import 'dart:math' as math;

const xsize = 280.0;
const ysize = 150.0;

class Render {
  Canvas _canvas;
  double _yOffset;
  double _xMin;
  double _yMin;
  double _xMax;
  double _yMax;
  double _xRatio;
  double _yRatio;

  Render(Canvas canvas, double yOffset, double xMin, double xMax, double yMin,
      double yMax) {
    _canvas = canvas;
    _yOffset = yOffset;
    _xMin = xMin;
    _yMin = yMin;
    _xMax = xMax;
    _yMax = yMax;
    _xRatio = xsize / (xMax - xMin);
    _yRatio = ysize / (yMax - yMin);
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

  void drawXGrid(int step, Paint paint) {
    DateTime dtmax = new DateTime.fromMillisecondsSinceEpoch(_xMax.toInt());
    DateTime dt = new DateTime.fromMillisecondsSinceEpoch(_xMin.toInt());

    DateTime now = new DateTime.now();
    while (dt.isBefore(dtmax) && dt.isBefore(now)) {
      double x = _xRatio * (dt.millisecondsSinceEpoch - _xMin.toInt());
      double y = _yOffset;
      String str = new DateFormat('d\nMMM').format(dt);
      _canvas.drawLine(new Offset(x, y + 10), new Offset(x, y - 0.0), paint);

      ui.Paragraph paragraph = _buildDateLabel(str.toString());
      _canvas.drawParagraph(
        paragraph,
        new Offset(x - 0.0, y + 15),
      );

      dt = dt.add(new Duration(days: step));
    }
  }

  void drawYGrid(int step, Paint paint, String unit) {
    double delta = ysize / step;
    double d = 0.0;
    for (int i = 0; i <= step; i++) {
      double y = _yOffset - d;
      double yval = d / _yRatio + _yMin;
      _canvas.drawLine(new Offset(0.0, y), new Offset(xsize, y), paint);
      ui.Paragraph paragraph =
          _buildNumberLabel(yval.toStringAsFixed(1) + unit);
      _canvas.drawParagraph(
        paragraph,
        new Offset(-40.0, y - 5),
      );
      _canvas.drawParagraph(
        paragraph,
        new Offset((xsize + 10.0), y - 5),
      );
      d += delta;
    }
  }

  void drawLine(double x0, double y0, double x1, double y1, Paint paint) {
    double _x0 = (x0 - _xMin) * _xRatio;
    double _x1 = (x1 - _xMin) * _xRatio;
    double _y0 = _yOffset - (y0 - _yMin) * _yRatio;
    double _y1 = _yOffset - (y1 - _yMin) * _yRatio;
    _canvas.drawLine(new Offset(_x0, _y0), new Offset(_x1, _y1), paint);
  }

  void drawCircle(double x, double y, double d, Paint paint) {
    double _x = (x - _xMin) * _xRatio;
    double _y = _yOffset - (y - _yMin) * _yRatio;
    _canvas.drawCircle(new Offset(_x, _y), d, paint);
  }
}

class ChartHistory extends StatefulWidget {
  ChartHistory({Key key, this.title}) : super(key: key);

  static const String routeName = '/chart_history';

  final String title;

  @override
  _ChartHistoryState createState() => new _ChartHistoryState();
}

class _ChartHistoryState extends State<ChartHistory> {
  List<THEntry> entryList = new List();
  DatabaseReference _entryRef;
  StreamSubscription<Event> _onAddSubscription;
  static Chart chart = new Chart();

  CustomPaint _myCustomPainter = new CustomPaint(
    size: new Size(xsize, 600.0),
    painter: chart,
  );

  _ChartHistoryState() {
    _entryRef = FirebaseDatabase.instance.reference().child(getTHRef());
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
    final Paint paintT = new Paint()..color = Colors.amber[300];
    final Paint paintH = new Paint()..color = Colors.amber[100];

    if (entryList.length > 0) {
      DateTime dtmax = new DateTime.now();
      DateTime dtmin = dtmax.subtract(new Duration(
        days: 7,
        hours: dtmax.hour,
        minutes: dtmax.minute,
        seconds: dtmax.second,
        milliseconds: dtmax.millisecond,
      ));
      int tmMin = dtmin.millisecondsSinceEpoch;
      int tmMax = dtmax.millisecondsSinceEpoch;
      double tempMin = entryList
          .where((entry) => entry.time > tmMin)
          .map((entry) => entry.t)
          .reduce(math.min);
      double tempMax = entryList
          .where((entry) => entry.time > tmMin)
          .map((entry) => entry.t)
          .reduce(math.max);
      double humMin = entryList
          .where((entry) => entry.time > tmMin)
          .map((entry) => entry.h)
          .reduce(math.min);
      double humMax = entryList
          .where((entry) => entry.time > tmMin)
          .map((entry) => entry.h)
          .reduce(math.max);

      double delta;
      delta = 0.1 * (tmMax - tmMin).toDouble();
      int timeMin = tmMin - delta.toInt();
      int timeMax = tmMax + delta.toInt();
      delta = 0.1 * (tempMax - tempMin);
      tempMin -= delta;
      tempMax += delta;
      delta = 0.1 * (humMax - humMin);
      humMin -= delta;
      humMax += delta;
      double tOffset = 200.0;
      double hOffset = 450.0;

      Render renderT = new Render(canvas, tOffset, timeMin.toDouble(),
          timeMax.toDouble(), tempMin, tempMax);
      Render renderH = new Render(canvas, hOffset, timeMin.toDouble(),
          timeMax.toDouble(), humMin, humMax);

      // grid T
      renderT.drawYGrid(12, paintT, '°C');
      renderT.drawXGrid(1, paintT);
      // grid H
      renderH.drawYGrid(12, paintH, '%');
      renderH.drawXGrid(1, paintH);

      for (int i = 0; i < entryList.length; i++) {
        if (entryList[i].getTime() > tmMin) {
          renderT.drawCircle(entryList[i].getTime().toDouble(),
              entryList[i].getT(), 1.3, paintT);
          renderH.drawCircle(entryList[i].getTime().toDouble(),
              entryList[i].getH(), 1.3, paintH);
        }
      }
    }
  }

  void add(THEntry entry) {
    entryList.add(entry);
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
