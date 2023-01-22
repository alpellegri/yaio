import 'package:flutter/material.dart';
import 'entries.dart';
import 'firebase_utils.dart';

class DataItemWidget extends StatelessWidget {
  final IoEntry entry;

  const DataItemWidget({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        // alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).primaryColorLight,
        ),
        child: Stack(
          children: <Widget>[
            Container(
              // alignment: Alignment.centerLeft,
              width: 4,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8)),
                color: Theme.of(context).primaryColor,
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              entry.key!,
                              textAlign: TextAlign.left,
                            ),
                            Text(
                              '${kEntryId2Name[DataCode.values[entry.code!]]}',
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        )),
                        Text(
                          entry.getStringValue(),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ));
  }
}

class DataConfigWidget extends StatefulWidget {
  final IoEntry data;
  final ValueChanged<IoEntry> onChangedValue;

  const DataConfigWidget({
    super.key,
    required this.data,
    required this.onChangedValue,
  });

  @override
  _DataConfigWidget createState() => _DataConfigWidget();
}

class _DataConfigWidget extends State<DataConfigWidget> {
  late IoEntry data;
  TextEditingController ctrl_1 = TextEditingController();
  TextEditingController ctrl_2 = TextEditingController();
  TextEditingController ctrl_3 = TextEditingController();

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
    switch (DataCode.values[data.code!]) {
      case DataCode.RadioRx:
        w = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
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
        w = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
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
              TextField(
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
        w = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
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
              TextField(
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
        w = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
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
        w = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
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
      case DataCode.String:
        w = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
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
        w = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Switch(
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
        w = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
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
              TextField(
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
              TextField(
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
              TimerOptWidget(
                value: data.ioctl!,
                onChanged: _handleTimerChanged,
              ),
            ]);
        break;
      case DataCode.Timeout:
        w = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
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
              TextField(
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
              TextField(
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
        w = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(),
            ]);
    }

    return Container(
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
  static const List<String> dayOption = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'All',
  ];

  const TimerOptWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

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
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(children: <Widget>[
            Expanded(
              child: Row(children: <Widget>[
                const Text('Polarity'),
                Checkbox(
                    value: ((value & (1 << 24)) != 0),
                    onChanged: (bool? v) {
                      int newValue = value;
                      newValue = (v == true)
                          ? (value | (1 << 24))
                          : (value & ~(1 << 24));
                      onChanged(newValue);
                    }),
              ]),
            ),
            const Text('Days of the week'),
            PopupMenuButton(
              padding: EdgeInsets.zero,
              onSelected: applyOnSelected,
              itemBuilder: (BuildContext context) {
                return dayOption.map((String opt) {
                  int index = dayOption.indexOf(opt);
                  return PopupMenuItem<int>(
                    value: index,
                    child: CheckedPopupMenuItem<int>(
                      value: index,
                      checked: isChecked(index, value),
                      child: Text(opt),
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

  const DataIoShortDialogWidget({
    super.key,
    required this.domain,
    required this.node,
    required this.data,
  });

  @override
  _DataIoShortDialogWidgetState createState() =>
      _DataIoShortDialogWidgetState(domain, node, data);
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
    return AlertDialog(
        title: const Text('Edit'),
        content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DataConfigWidget(
                data: data,
                onChangedValue: _handleChangedValue,
                key: null,
              ),
            ]),
        actions: <Widget>[
          TextButton(
              child: const Text('SAVE'),
              onPressed: () {
                try {
                  data.reference.child(data.key!).set(data.toJson());
                  nodeRefresh(domain, node);
                } catch (exception) {
                  print('bug');
                }
                Navigator.pop(context, null);
              }),
          TextButton(
              child: const Text('DISCARD'),
              onPressed: () {
                Navigator.pop(context, null);
              }),
        ]);
  }
}
