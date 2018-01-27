import 'package:firebase_database/firebase_database.dart';

const String kStringPhyIn = 'PhyIn';
const String kStringPhyOut = 'PhyOut';
const String kStringLogIn = 'LogIn';
const String kStringLogOut = 'LogOut';
const String kStringRadioIn = 'RadioIn';
const String kStringRadioOut = 'RadioOut';
const String kStringRadioElem = 'RadioElem';
const String kStringTimer = 'Timer';
const String kStringBool = 'Bool';
const String kStringInt = 'Int';
const String kStringFloat = 'Float';
const String kStringRadioRx = 'RadioRx';
const String kStringMessaging = 'Messaging';

enum DataCode {
  PhyIn,
  PhyOut,
  LogIn,
  LogOut,
  RadioIn,
  RadioOut,
  RadioElem,
  Timer,
  Bool,
  Int,
  Float,
  RadioRx,
  Messaging,
}

const Map<DataCode, String> kEntryId2Name = const {
  DataCode.PhyIn: kStringPhyIn,
  DataCode.PhyOut: kStringPhyOut,
  DataCode.LogIn: kStringLogIn,
  DataCode.LogOut: kStringLogOut,
  DataCode.RadioIn: kStringRadioIn,
  DataCode.RadioOut: kStringRadioOut,
  DataCode.RadioElem: kStringRadioElem,
  DataCode.Timer: kStringTimer,
  DataCode.Bool: kStringBool,
  DataCode.Int: kStringInt,
  DataCode.Float: kStringFloat,
  DataCode.RadioRx: kStringRadioRx,
  DataCode.Messaging: kStringMessaging,
};

const Map<String, DataCode> kEntryName2Id = const {
  kStringPhyIn: DataCode.PhyIn,
  kStringPhyOut: DataCode.PhyOut,
  kStringLogIn: DataCode.LogIn,
  kStringLogOut: DataCode.LogOut,
  kStringRadioIn: DataCode.RadioIn,
  kStringRadioOut: DataCode.RadioOut,
  kStringRadioElem: DataCode.RadioElem,
  kStringTimer: DataCode.Timer,
  kStringBool: DataCode.Bool,
  kStringInt: DataCode.Int,
  kStringFloat: DataCode.Float,
  kStringRadioRx: DataCode.RadioRx,
  kStringMessaging: DataCode.Messaging,
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
    cb = snapshot.value['cb'];
  }

  int getPin() {
    value ??= 0;
    return value >> shift;
  }

  setPin(int port) {
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
    return {
      'owner': owner,
      'name': name,
      'code': code,
      'value': value,
      'cb': cb,
    };
  }
}

enum Instruction {
  ex0, // exception, illegal op-code 0
  ldi, // load immediate arg value into ACC (this involves a fetch from DB)
  ld24, // load arg value into ACC (this involves a fetch from DB)
  ld, // load arg value into ACC (this involves a fetch from DB)
  st24, // store arg value into ACC (this involves a write back to DB)
  st, // store arg value into ACC (this involves a write back to DB)
  lt, // if ACC is less than arg, then ACC=1, else ACC=0
  gt, // if ACC is grater than arg, then ACC=1, else ACC=0
  eqi, // if ACC is equal to immediate arg value, then ACC=1, else ACC=0
  eq, // if ACC is equal to arg, then ACC=1, else ACC=0
  bz, // branch if ACC is zero
  bnz, // branch if ACC is not zero
  dly, // delay in ms
  stne,
  lte,
  gte,
  halt,
  jmp,
}

class InstrEntry {
  int i;
  String v;

  InstrEntry(this.i, this.v);
}

class ExecEntry {
  DatabaseReference reference;
  String key;
  String owner;
  String name;
  String cb;
  List<InstrEntry> p = new List<InstrEntry>();

  ExecEntry(DatabaseReference ref) : reference = ref;

  ExecEntry.fromSnapshot(DatabaseReference ref, DataSnapshot snapshot)
      : reference = ref,
        key = snapshot.key,
        owner = snapshot.value['owner'],
        name = snapshot.value['name'],
        cb = snapshot.value['cb']{
    print('ExecEntry.fromSnapshot');
    snapshot.value['p'].forEach((e) => p.add(new InstrEntry(e['i'], e['v'].toString())));
    print('size: ${p.length}');
  }

  setOwner(String _owner) {
    owner = _owner;
  }

  toJson() {
    return {
      'owner': owner,
      'name': name,
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
