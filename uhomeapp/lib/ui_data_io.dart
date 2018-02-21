import 'package:flutter/material.dart';
import 'entries.dart';

class DynamicDataWidget extends StatelessWidget {
  final IoEntry entry;

  DynamicDataWidget(this.entry);

  @override
  Widget build(BuildContext context) {
    String v;
    switch (DataCode.values[entry.code]) {
      case DataCode.PhyIn:
      case DataCode.PhyOut:
      case DataCode.RadioRx:
      case DataCode.RadioMach:
      case DataCode.RadioTx:
        v = entry.getValue24().toString();
        break;
      case DataCode.DhtTemperature:
      case DataCode.DhtHumidity:
        v = (entry.getBits(15, 16) / 10).toString();
        break;
      case DataCode.Timer:
        v = ((entry.getBits(15, 8) * 60) + entry.getBits(7, 8)).toString();
        break;
      case DataCode.Bool:
      case DataCode.Int:
      case DataCode.Float:
      case DataCode.Messaging:
        v = entry.value.toString();
        break;
    }
    return new Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        new Text(
          v,
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

class DynamicEditWidget extends StatelessWidget {
  final int type;
  final TextEditingController pin;
  final TextEditingController value;

  DynamicEditWidget(this.type, this.pin, this.value);

  @override
  Widget build(BuildContext context) {
    switch (getMode(type)) {
      case 1:
      case 5:
        return new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new TextField(
                controller: pin,
                keyboardType: TextInputType.number,
                decoration: new InputDecoration(
                  hintText: 'pin value',
                ),
              ),
              new TextField(
                controller: value,
                keyboardType: TextInputType.number,
                decoration: new InputDecoration(
                  hintText: 'data value',
                ),
              ),
            ]);
        break;
      case 2:
        return new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new TextField(
                controller: value,
                keyboardType: TextInputType.number,
                decoration: new InputDecoration(
                  hintText: 'value',
                ),
              ),
            ]);
        break;
      case 3:
        return new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new TextField(
                controller: value,
                decoration: new InputDecoration(
                  hintText: 'value',
                ),
              ),
            ]);
      case 4:
        return new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new TextField(
                controller: value,
                keyboardType: TextInputType.number,
                decoration: new InputDecoration(
                  hintText: 'value',
                ),
              ),
            ]);
        break;
      case 6:
        return new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new TextField(
                controller: pin,
                keyboardType: TextInputType.number,
                decoration: new InputDecoration(
                  hintText: 'hour',
                ),
              ),
              new TextField(
                controller: value,
                keyboardType: TextInputType.number,
                decoration: new InputDecoration(
                  hintText: 'minutes',
                ),
              ),
            ]);
        break;
      default:
        return new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new Text(''),
            ]);
    }
  }
}
