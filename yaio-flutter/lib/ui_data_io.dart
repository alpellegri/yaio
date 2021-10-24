import 'package:flutter/material.dart';
import 'entries.dart';
import 'firebase_utils.dart';

class DataValueWidget extends StatelessWidget {
  final IoEntry entry;

  DataValueWidget(this.entry);

  @override
  Widget build(BuildContext context) {
    return new Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        new Text(
          entry.getStringValue(),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}

class DataItemWidget extends StatelessWidget {
  final IoEntry entry;

  DataItemWidget(this.entry);

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: new EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: new Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          new Expanded(
            child: new Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                new Expanded(
                    child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    new Text(
                      entry.key,
                      textAlign: TextAlign.left,
                    ),
                    new Text(
                      '${kEntryId2Name[DataCode.values[entry.code]]}',
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                )),
                new DataValueWidget(entry),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DataConfigWidget extends StatefulWidget {
  final IoEntry data;
  final ValueChanged<IoEntry> onChangedValue;

  DataConfigWidget({Key key, this.data, this.onChangedValue}) : super(key: key);

  @override
  _DataConfigWidget createState() => new _DataConfigWidget();
}

class _DataConfigWidget extends State<DataConfigWidget> {
  IoEntry data;
  TextEditingController ctrl_1 = new TextEditingController();
  TextEditingController ctrl_2 = new TextEditingController();
  TextEditingController ctrl_3 = new TextEditingController();

  @override
  void initState() {
    super.initState();
    data = widget.data;
    data.ioctl ??= 0;
    if (widget.data.value != null) {
      ctrl_1.text = getValueCtrl1(data);
      ctrl_2.text = getValueCtrl2(data);
      ctrl_3.text = getValueCtrl3(data);
    }
  }

  Widget build(BuildContext context) {
    Widget w;
    switch (DataCode.values[data.code]) {
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
      case DataCode.PhyDOut:
      case DataCode.PhyAOut:
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
      case DataCode.PhyDIn:
      case DataCode.PhyAIn:
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
                  hintText: 'identifier',
                  labelText: 'ID',
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
        data.value ??= false;
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
              new TextField(
                controller: ctrl_3,
                onSubmitted: (v) {
                  setState(() {
                    data = setValueCtrl3(data, v);
                  });
                  widget.onChangedValue(data);
                },
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'seconds',
                  labelText: 'Seconds',
                ),
              ),
              new TimerOptWidget(
                  value: data.ioctl, onChanged: _handleTimerChanged),
            ]);
        break;
      case DataCode.Timeout:
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
              new TextField(
                controller: ctrl_3,
                onSubmitted: (v) {
                  setState(() {
                    data = setValueCtrl3(data, v);
                  });
                  widget.onChangedValue(data);
                },
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'seconds',
                  labelText: 'Seconds',
                ),
              ),
            ]);
        break;
      default:
        w = new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new Container(),
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
                const Text('Polarity'),
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
            const Text('Days of the week'),
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

class DataIoShortDialogWidget extends StatefulWidget {
  final String domain;
  final String node;
  final IoEntry data;

  DataIoShortDialogWidget({this.domain, this.node, this.data});

  @override
  _DataIoShortDialogWidgetState createState() =>
      new _DataIoShortDialogWidgetState(domain, node, data);
}

class _DataIoShortDialogWidgetState extends State<DataIoShortDialogWidget> {
  final String domain;
  final String node;
  final IoEntry data;

  void _handleChangedValue(IoEntry newValue) {
    print('_handleTapboxChanged ${newValue.value}');
    data.value = newValue.value;
  }

  _DataIoShortDialogWidgetState(this.domain, this.node, this.data);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new AlertDialog(
        title: const Text('Edit'),
        content: new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new DataConfigWidget(
                data: data,
                onChangedValue: _handleChangedValue,
              ),
            ]),
        actions: <Widget>[
          new TextButton(
              child: const Text('SAVE'),
              onPressed: () {
                try {
                  data.reference.child(data.key).set(data.toJson());
                  nodeRefresh(domain, node);
                } catch (exception) {
                  print('bug');
                }
                Navigator.pop(context, null);
              }),
          new TextButton(
              child: const Text('DISCARD'),
              onPressed: () {
                Navigator.pop(context, null);
              }),
        ]);
  }
}
