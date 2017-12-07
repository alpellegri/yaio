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
    final Paint paintLine = new Paint()..color = Colors.amber[200];

    if (entryList.length > 0) {
      timeMin = entryList.map((entry) => entry.time).reduce(math.min);
      timeMax = entryList.map((entry) => entry.time).reduce(math.max);
      tMin = entryList.map((entry) => entry.t).reduce(math.min);
      tMax = entryList.map((entry) => entry.t).reduce(math.max);
      hMin = entryList.map((entry) => entry.h).reduce(math.min);
      hMax = entryList.map((entry) => entry.h).reduce(math.max);

      tMin -= 1.0;
      tMax += 1.0;
      hMin -= 5.0;
      hMax += 5.0;
      double timeRatio = 300.0 / (timeMax - timeMin).toDouble();
      double tRatio = 100.0 / (tMax - tMin).toDouble();
      double hRatio = 100.0 / (hMax - hMin).toDouble();
      double tOffset = 0.0;
      double hOffset = 200.0;

      _drawLines(canvas, tOffset, tMin, tMax, tRatio, 1.0);
      _drawLines(canvas, hOffset, hMin, hMax, hRatio, 5.0);

      // print('$timeMax, $timeMin ${timeMax - timeMin}');
      for (int i = 0; i < entryList.length; i++) {
        // print('$i, ${entryList[i].getTime()}');
        double x = timeRatio * (entryList[i].getTime() - timeMin).toDouble();
        // x = i.toDouble();
        double t = tOffset - tRatio * (entryList[i].getT() - tMin);
        double h = hOffset - hRatio * (entryList[i].getH() - hMin);
        // canvas.drawLine(new Offset(x, 0.0), new Offset(x, t), paint);
        // print('$x, $t, $h');
        canvas.drawCircle(new Offset(x, t), 1.5, paintTH);
        canvas.drawCircle(new Offset(x, h), 1.5, paintTH);
      }
    }
  }

  void add(THEntry entry) {
    entryList.add(entry);
  }

  ui.Paragraph _buildParagraphForLeftLabel(double d) {
    ui.ParagraphBuilder builder = new ui.ParagraphBuilder(
      new ui.ParagraphStyle(
        fontSize: 10.0,
        textAlign: TextAlign.right,
      ),
    )
      ..pushStyle(new ui.TextStyle(color: Colors.amber[200]))
      ..addText((d).toString());
    final ui.Paragraph paragraph = builder.build()
      ..layout(new ui.ParagraphConstraints(width: 20.0));
    return paragraph;
  }

  void _drawLines(ui.Canvas canvas, double offset, double min, double max,
      double ratio, double step) {
    final Paint paintLine = new Paint()..color = Colors.amber[200];

    for (double d = min; d < max; d += step) {
      double y = offset - ratio * (d - min);
      canvas.drawLine(new Offset(0.0, y), new Offset(300.0, y), paintLine);
      ui.Paragraph paragraph = _buildParagraphForLeftLabel(d);
      canvas.drawParagraph(
        paragraph,
        new Offset(-30.0, y - 5),
      );
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
