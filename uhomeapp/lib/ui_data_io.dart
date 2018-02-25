import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
              new TimerWidget(value: value, onChanged: _handleTimerChanged),
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

  void _handleTimerChanged(int newValue) {
    setState(() {
      value = newValue;
    });
    widget.onChanged(value);
  }
}

class TimerWidget extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  TimerWidget({Key key, this.value, this.onChanged});

  bool isChecked(int index, int value) => (value >> 16 & (1 << index)) != 0;

  void applyOnSelected(int index) {
    int newValue;
    if (index == 7) {
      int mask = 255 << 16;
      newValue = value; // clear bit
      int bit = newValue >> 23;
      bit *= 255;
      newValue &= ~mask;
      newValue |= bit << 16;
      newValue = newValue ^ mask; // toggle bit
    } else {
      int mask = 1 << (index + 16);
      newValue = value ^ mask; // toggle bit
      newValue &= ~(1 << 23); // clear most
    }
    print(newValue);
    onChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return new PopupMenuButton(
      padding: EdgeInsets.zero,
      onSelected: applyOnSelected,
      itemBuilder: (BuildContext context) {
        return [0, 1, 2, 3, 4, 5, 6, 7].map((int index) {
          return new PopupMenuItem<int>(
            value: index,
            child: new CheckedPopupMenuItem<int>(
                value: index,
                checked: isChecked(index, value),
                child: new Text(index.toString())),
          );
        }).toList();
      },
    );
  }
}
