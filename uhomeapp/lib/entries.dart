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
  String name;
  int code;
  int value;
  String cb;

  IoEntry(DatabaseReference ref) : reference = ref;

  IoEntry.fromSnapshot(DatabaseReference ref, DataSnapshot snapshot) {
    reference = ref;
    key = snapshot.key;
    owner = snapshot.value['owner'];
    name = snapshot.value['name'];
    code = snapshot.value['code'];
    value = snapshot.value['value'];
    cb = snapshot.value['func'];
  }

  int getPort() {
    value ??= 0;
    return value >> shift;
  }

  setPort(int port) {
    value ??= 0;
    value = value & mask;
    value = port << shift | value;
  }

  int getValue() {
    value ??= 0;
    return value & mask;
  }

  setValue(int value) {
    value ??= 0;
    int port = value >> shift;
    value = (port << shift) | (value & mask);
  }

  setOwner(String _owner) {
    owner = _owner;
  }

  toJson() {
    var json;
    if (cb != null) {
      json = {
        'owner': owner,
        'name': name,
        'code': code,
        'value': value,
        'cb': cb,
      };
    } else {
      json = {
        'owner': owner,
        'name': name,
        'code': code,
        'value': value,
      };
    }
    return json;
  }
}

enum Instruction {
  ldi, // load immediate arg value into ACC (this involves a fetch from DB)
  ld, // load arg value into ACC (this involves a fetch from DB)
  st, // store arg value into ACC (this involves a write back to DB)
  rd, // read arg value locally into ACC
  wr, // write arg value locally into ACC
  lt, // if ACC is less than arg, then ACC=1, else ACC=0
  gt, // if ACC is grater than arg, then ACC=1, else ACC=0
  eqi, // if ACC is equal to immediate arg value, then ACC=1, else ACC=0
  eq, // if ACC is equal to arg, then ACC=1, else ACC=0
  bz, // branch if ACC is zero
  bnz, // branch if ACC is not zero
}

class FunctionEntry {
  DatabaseReference reference;
  String key;
  String owner;
  String name;
  int code;
  String value;
  String cb;

  FunctionEntry(DatabaseReference ref) : reference = ref;

  FunctionEntry.fromSnapshot(DatabaseReference ref, DataSnapshot snapshot)
      : reference = ref,
        key = snapshot.key,
        owner = snapshot.value['owner'],
        code = snapshot.value['code'],
        value = snapshot.value['value'],
        name = snapshot.value['name'],
        cb = snapshot.value['cb'];

  setOwner(String _owner) {
    owner = _owner;
  }

  toJson() {
    return {
      'owner': owner,
      'name': name,
      'code': code,
      'value': value,
      'cb': cb,
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
