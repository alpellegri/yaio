import 'package:flutter/material.dart';
import 'entries.dart';

class DynamicDataWidget extends StatelessWidget {
  final IoEntry entry;

  DynamicDataWidget(this.entry);

  @override
  Widget build(BuildContext context) {
    return new Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        new Text(
          entry.getValue().toString(),
          textScaleFactor: 1.2,
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}

class DataIoItemWidget extends StatelessWidget {
  final IoEntry entry;

  DataIoItemWidget(this.entry);

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: new EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
      child: new Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          new Expanded(
            child: new Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Expanded(
                    child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    new Text(
                      entry.key,
                      textScaleFactor: 1.2,
                      textAlign: TextAlign.left,
                    ),
                    new Text(
                      '${kEntryId2Name[DataCode.values[entry.code]]}',
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                )),
                new DynamicDataWidget(entry),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DynamicEditWidget extends StatefulWidget {
  final int type;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  DynamicEditWidget({Key key, this.type, this.value, this.onChanged})
      : super(key: key);

  @override
  _DynamicEditWidget createState() => new _DynamicEditWidget();
}

class _DynamicEditWidget extends State<DynamicEditWidget> {
  int type;
  dynamic value = 0;
  TextEditingController ctrl_1 = new TextEditingController();
  TextEditingController ctrl_2 = new TextEditingController();

  @override
  void initState() {
    super.initState();
    type = widget.type;
    if (widget.value != null) {
      value = widget.value;
      print('_DynamicEditWidget initState $value');
      ctrl_1.text = getValueCtrl1(type, value).toString();
      ctrl_2.text = getValueCtrl2(type, value).toString();
    }
  }

  Widget build(BuildContext context) {
    Widget w;
    switch (DataCode.values[type]) {
      case DataCode.PhyIn:
      case DataCode.RadioRx:
        w = new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new TextField(
                controller: ctrl_1,
                onSubmitted: (v) {
                  setState(() {
                    value = setValueCtrl1(value, type, v);
                  });
                  widget.onChanged(value);
                },
                keyboardType: TextInputType.number,
                decoration: new InputDecoration(
                  hintText: 'pin',
                ),
              ),
            ]);
        break;
      case DataCode.PhyOut:
      case DataCode.RadioTx:
      case DataCode.DhtTemperature:
      case DataCode.DhtHumidity:
        w = new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new TextField(
                controller: ctrl_1,
                onSubmitted: (v) {
                  setState(() {
                    value = setValueCtrl1(value, type, v);
                  });
                  widget.onChanged(value);
                },
                keyboardType: TextInputType.number,
                decoration: new InputDecoration(
                  hintText: 'pin',
                ),
              ),
              new TextField(
                controller: ctrl_2,
                onSubmitted: (v) {
                  setState(() {
                    value = setValueCtrl2(value, type, v);
                  });
                  widget.onChanged(value);
                },
                keyboardType: TextInputType.number,
                decoration: new InputDecoration(
                  hintText: 'data value',
                ),
              ),
            ]);
        break;
      case DataCode.RadioMach:
      case DataCode.Int:
      case DataCode.Float:
        w = new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new TextField(
                controller: ctrl_2,
                onSubmitted: (v) {
                  setState(() {
                    value = setValueCtrl2(value, type, v);
                  });
                  widget.onChanged(value);
                },
                keyboardType: TextInputType.number,
                decoration: new InputDecoration(
                  hintText: 'value',
                ),
              ),
            ]);
        break;
      case DataCode.Messaging:
        w = new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new TextField(
                controller: ctrl_2,
                onSubmitted: (v) {
                  setState(() {
                    value = setValueCtrl2(value, type, v);
                  });
                  widget.onChanged(value);
                },
                decoration: new InputDecoration(
                  hintText: 'value',
                ),
              ),
            ]);
        break;
      case DataCode.Bool:
        w = new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new TextField(
                controller: ctrl_2,
                onSubmitted: (v) {
                  setState(() {
                    value = setValueCtrl2(value, type, v);
                  });
                  widget.onChanged(value);
                },
                keyboardType: TextInputType.number,
                decoration: new InputDecoration(
                  hintText: 'value',
                ),
              ),
            ]);
        break;
      case DataCode.Timer:
        w = new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new TextField(
                controller: ctrl_1,
                onSubmitted: (v) {
                  setState(() {
                    value = setValueCtrl1(value, type, v);
                  });
                  widget.onChanged(value);
                },
                keyboardType: TextInputType.number,
                decoration: new InputDecoration(
                  hintText: 'hour',
                ),
              ),
              new TextField(
                controller: ctrl_2,
                onSubmitted: (v) {
                  setState(() {
                    value = setValueCtrl2(value, type, v);
                  });
                  widget.onChanged(value);
                },
                keyboardType: TextInputType.number,
                decoration: new InputDecoration(
                  hintText: 'minutes',
                ),
              ),
            ]);
        break;
      default:
        w = new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(''),
            ]);
    }

    return new Container(
      child: w,
    );
  }
}
