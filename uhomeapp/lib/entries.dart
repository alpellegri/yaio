import 'package:firebase_database/firebase_database.dart';

const int kDOut = 0;
const int kRadioIn = 1;
const int kLOut = 2;
const int kDIn = 3;
const int kRadioOut = 4;
const int kRadioElem = 5;
const int kTimer = 6;

const String kStringDOut = 'DOut';
const String kStringLOut = 'LOut';
const String kStringDIn = 'DIn';
const String kStringRadioIn = 'RadioIn';
const String kStringRadioOut = 'RadioOut';
const String kStringRadioElem = 'RadioElem';
const String kStringTimerElem = 'Timer';

const Map<int, String> kEntryId2Name = const {
  kDOut: kStringDOut,
  kRadioIn: kStringRadioIn,
  kLOut: kStringLOut,
  kDIn: kStringDIn,
  kRadioOut: kStringRadioOut,
  kRadioElem: kStringRadioElem,
  kTimer: kStringTimerElem,
};

const Map<String, int> kEntryName2Id = const {
  kStringDOut: kDOut,
  kStringRadioIn: kRadioIn,
  kStringLOut: kLOut,
  kStringDIn: kDIn,
  kStringRadioOut: kRadioOut,
  kStringRadioElem: kRadioElem,
  kStringTimerElem: kTimer,
};

class IoEntry {
  static const int shift = 24;
  static const int mask = (1 << shift) - 1;
  DatabaseReference reference;
  String key;
  String owner;
  int type;
  String name;
  int id;
  String func;

  IoEntry(DatabaseReference ref) : reference = ref;

  IoEntry.fromSnapshot(DatabaseReference ref, DataSnapshot snapshot) {
    reference = ref;
    key = snapshot.key;
    owner = snapshot.value['owner'];
    type = snapshot.value['type'];
    name = snapshot.value['name'];
    id = snapshot.value['id'];
    func = snapshot.value['func'];
  }

  int getPort() {
    id ??= 0;
    return id >> shift;
  }

  setPort(int port) {
    id ??= 0;
    int value = id & mask;
    id = port << shift | value;
  }

  int getValue() {
    id ??= 0;
    return id & mask;
  }

  setValue(int value) {
    id ??= 0;
    int port = id >> shift;
    id = (port << shift) | (value & mask);
  }

  setOwner(String _owner) {
    owner = _owner;
  }

  toJson() {
    var json;
    if (func != null) {
      json = {
        'owner': owner,
        'type': type,
        'id': id,
        'name': name,
        'func': func,
      };
    } else {
      json = {
        'owner': owner,
        'type': type,
        'id': id,
        'name': name,
      };
    }
    return json;
  }
}

class FunctionEntry {
  DatabaseReference reference;
  String key;
  String owner;
  String name;
  String action;
  int delay;
  String next;

  FunctionEntry(DatabaseReference ref) : reference = ref;

  FunctionEntry.fromSnapshot(DatabaseReference ref, DataSnapshot snapshot)
      : reference = ref,
        key = snapshot.key,
        owner = snapshot.value['owner'],
        action = snapshot.value['action'],
        delay = snapshot.value['delay'],
        name = snapshot.value['name'],
        next = snapshot.value['next'];

  setOwner(String _owner) {
    owner = _owner;
  }

  toJson() {
    return {
      'owner': owner,
      'action': action,
      'delay': delay,
      'name': name,
      'next': next,
    };
  }
}

class LogEntry {
  String key;
  DateTime dateTime;
  String message;

  LogEntry(this.dateTime, this.message);

  LogEntry.fromSnapshot(DataSnapshot snapshot)
      : key = snapshot.key,
        dateTime = new DateTime.fromMillisecondsSinceEpoch(
            snapshot.value["time"] * 1000),
        message = snapshot.value["msg"];

  toJson() {
    return {
      'message': message,
      'date': dateTime.millisecondsSinceEpoch,
    };
  }
}

class THEntry {
  DatabaseReference reference;
  String key;
  double t;
  double h;
  int time;

  THEntry(DatabaseReference ref) : reference = ref;

  THEntry.fromSnapshot(DatabaseReference ref, DataSnapshot snapshot) {
    reference = ref;
    key = snapshot.key;
    t = snapshot.value['t'];
    h = snapshot.value['h'];
    time = snapshot.value['time'] * 1000;
  }

  double getT() {
    t ??= 0.0;
    return t;
  }

  double getH() {
    h ??= 0.0;
    return h;
  }

  int getTime() {
    time ??= 0;
    return time;
  }

  toJson() {
    return {
      't': t,
      'h': h,
      'time': time,
    };
  }
}
