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
      children: <Widget>[
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
        children: <Widget>[
          new Expanded(
            child: new Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Expanded(
                    child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
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
  final IoEntry data;
  final ValueChanged<IoEntry> onChangedValue;

  DynamicEditWidget({Key key, this.data, this.onChangedValue})
      : super(key: key);

  @override
  _DynamicEditWidget createState() => new _DynamicEditWidget();
}

class _DynamicEditWidget extends State<DynamicEditWidget> {
  IoEntry data;
  TextEditingController ctrl_1 = new TextEditingController();
  TextEditingController ctrl_2 = new TextEditingController();

  @override
  void initState() {
    super.initState();
    data = widget.data;
    if (widget.data.value != null) {
      ctrl_1.text = getValueCtrl1(data);
      ctrl_2.text = getValueCtrl2(data);
    }
  }

  Widget build(BuildContext context) {
    Widget w;
    switch (DataCode.values[data.code]) {
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
                    data = setValueCtrl1(data, v);
                  });
                  widget.onChangedValue(data);
                },
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'pin',
                  labelText: 'Pin',
                ),
              ),
            ]);
        break;
      case DataCode.PhyOut:
      case DataCode.RadioTx:
        w = new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new TextField(
                controller: ctrl_1,
                onSubmitted: (v) {
                  setState(() {
                    data = setValueCtrl1(data, v);
                  });
                  widget.onChangedValue(data);
                },
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'pin',
                  labelText: 'Pin',
                ),
              ),
              new TextField(
                controller: ctrl_2,
                onSubmitted: (v) {
                  setState(() {
                    data = setValueCtrl2(data, v);
                  });
                  widget.onChangedValue(data);
                },
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'value',
                  labelText: 'Value',
                ),
              ),
            ]);
        break;
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
                    data = setValueCtrl1(data, v);
                  });
                  widget.onChangedValue(data);
                },
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'pin',
                  labelText: 'Pin',
                ),
              ),
              new TextField(
                controller: ctrl_2,
                onSubmitted: (v) {
                  setState(() {
                    data = setValueCtrl2(data, v);
                  });
                  widget.onChangedValue(data);
                },
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'period',
                  labelText: 'Period [min]',
                ),
              ),
            ]);
        break;
      case DataCode.RadioMach:
        w = new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new TextField(
                controller: ctrl_1,
                onSubmitted: (v) {
                  setState(() {
                    data = setValueCtrl1(data, v);
                  });
                  widget.onChangedValue(data);
                },
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'value',
                  labelText: 'Value',
                ),
              ),
            ]);
        break;
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
                    data = setValueCtrl2(data, v);
                  });
                  widget.onChangedValue(data);
                },
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'value',
                  labelText: 'Value',
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
                    data.value = v;
                  });
                  widget.onChangedValue(data);
                },
                decoration: const InputDecoration(
                  hintText: 'value',
                  labelText: 'Value',
                ),
              ),
            ]);
        break;
      case DataCode.Bool:
        data.value = data.value ?? false;
        w = new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new Switch(
                  value: data.value,
                  onChanged: (bool v) {
                    setState(() {
                      data = setValueCtrl1(data, v.toString());
                    });
                    widget.onChangedValue(data);
                  }),
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
                    data = setValueCtrl1(data, v);
                  });
                  widget.onChangedValue(data);
                },
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'hour',
                  labelText: 'Hour',
                ),
              ),
              new TextField(
                controller: ctrl_2,
                onSubmitted: (v) {
                  setState(() {
                    data = setValueCtrl2(data, v);
                  });
                  widget.onChangedValue(data);
                },
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'minutes',
                  labelText: 'Minutes',
                ),
              ),
              new TimerOptWidget(
                  value: data.ioctl, onChanged: _handleTimerChanged),
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
      data.ioctl = newValue;
    });
    widget.onChangedValue(data);
  }
}

class TimerOptWidget extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  static const List<String> dayOption = const [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'All',
  ];

  TimerOptWidget({Key key, this.value, this.onChanged});

  bool isChecked(int index, int value) => (value >> 16 & (1 << index)) != 0;

  void applyOnSelected(int index) {
    int newValue;
    if (index == 7) {
      int mask = 0xFF << 16;
      newValue = value;
      int bit = (newValue & (1 << 23)) >> 23;
      bit *= 0xFF;
      newValue &= ~mask;
      newValue |= bit << 16;
      newValue = newValue ^ mask; // toggle bit
    } else {
      int mask = 1 << (index + 16);
      newValue = value ^ mask; // toggle bit
      newValue &= ~(1 << 23); // clear most
    }
    onChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    print('TimerOptWidget $value');
    return new Container(
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Row(children: <Widget>[
            new Expanded(
              child: new Row(children: <Widget>[
                new Text('Event Polarity'),
                new Checkbox(
                    value: ((value & (1 << 24)) != 0),
                    onChanged: (bool v) {
                      int newValue = value;
                      newValue = (v == true)
                          ? (value | (1 << 24))
                          : (value & ~(1 << 24));
                      onChanged(newValue);
                    }),
              ]),
            ),
            new Text('Days of the week'),
            new PopupMenuButton(
              padding: EdgeInsets.zero,
              onSelected: applyOnSelected,
              itemBuilder: (BuildContext context) {
                return dayOption.map((String opt) {
                  int index = dayOption.indexOf(opt);
                  return new PopupMenuItem<int>(
                    value: index,
                    child: new CheckedPopupMenuItem<int>(
                      value: index,
                      checked: isChecked(index, value),
                      child: new Text(opt),
                    ),
                  );
                }).toList();
              },
            ),
          ]),
        ],
      ),
    );
  }
}
