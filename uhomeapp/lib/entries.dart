import 'dart:convert';
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
    print('IoEntry.fromSnapshot');
    reference = ref;
    key = snapshot.key;
    owner = snapshot.value['owner'];
    name = snapshot.value['name'];
    code = snapshot.value['code'];
    value = snapshot.value['value'];
    cb = snapshot.value['cb'];
  }

  IoEntry.fromMap(DatabaseReference ref, String k, dynamic v) {
    print('IoEntry.fromMap');
    reference = ref;
    key = k;
    owner = v['owner'];
    name = v['name'];
    code = v['code'];
    value = v['value'];
    if (v.containsValue('cb') == true) {
      cb = v['cb'];
    }
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

const String kOpCodeStringex0 = 'ex0';
const String kOpCodeStringldi = 'ldi';
const String kOpCodeStringld24 = 'ld24';
const String kOpCodeStringld = 'ld';
const String kOpCodeStringst24 = 'st24';
const String kOpCodeStringst = 'st';
const String kOpCodeStringlt = 'lt';
const String kOpCodeStringgt = 'gt';
const String kOpCodeStringeqi = 'eqi';
const String kOpCodeStringeq = 'eq';
const String kOpCodeStringbz = 'bz';
const String kOpCodeStringbnz = 'bnz';
const String kOpCodeStringdly = 'dly';
const String kOpCodeStringstne = 'stne';
const String kOpCodeStringlte = 'lte';
const String kOpCodeStringgte = 'gte';
const String kOpCodeStringjmp = 'jmp';
const String kOpCodeStringhalt = 'halt';

enum OpCode {
  ex0,
  ldi,
  ld24,
  ld,
  st24,
  st,
  lt,
  gt,
  eqi,
  eq,
  bz,
  bnz,
  dly,
  stne,
  lte,
  gte,
  halt,
  jmp,
}

const Map<OpCode, bool> kOpCodeIsImmediate = const {
  OpCode.ex0: true,
  OpCode.ldi: true,
  OpCode.ld24: false,
  OpCode.ld: false,
  OpCode.st24: false,
  OpCode.st: false,
  OpCode.lt: false,
  OpCode.gt: false,
  OpCode.eqi: true,
  OpCode.eq: false,
  OpCode.bz: true,
  OpCode.bnz: true,
  OpCode.dly: true,
  OpCode.stne: false,
  OpCode.lte: false,
  OpCode.gte: false,
  OpCode.jmp: true,
  OpCode.halt: true,
};

const Map<OpCode, String> kOpCode2Name = const {
  OpCode.ex0: kOpCodeStringex0,
  OpCode.ldi: kOpCodeStringldi,
  OpCode.ld24: kOpCodeStringld24,
  OpCode.ld: kOpCodeStringld,
  OpCode.st24: kOpCodeStringst24,
  OpCode.st: kOpCodeStringst,
  OpCode.lt: kOpCodeStringlt,
  OpCode.gt: kOpCodeStringgt,
  OpCode.eqi: kOpCodeStringeqi,
  OpCode.eq: kOpCodeStringeq,
  OpCode.bz: kOpCodeStringbz,
  OpCode.bnz: kOpCodeStringbnz,
  OpCode.dly: kOpCodeStringdly,
  OpCode.stne: kOpCodeStringstne,
  OpCode.lte: kOpCodeStringlte,
  OpCode.gte: kOpCodeStringgte,
  OpCode.jmp: kOpCodeStringjmp,
  OpCode.halt: kOpCodeStringhalt,
};

const Map<String, OpCode> kName2Opcode = const {
  kOpCodeStringex0: OpCode.ex0,
  kOpCodeStringldi: OpCode.ldi,
  kOpCodeStringld24: OpCode.ld24,
  kOpCodeStringld: OpCode.ld,
  kOpCodeStringst24: OpCode.st24,
  kOpCodeStringst: OpCode.st,
  kOpCodeStringlt: OpCode.lt,
  kOpCodeStringgt: OpCode.gt,
  kOpCodeStringeqi: OpCode.eqi,
  kOpCodeStringeq: OpCode.eq,
  kOpCodeStringbz: OpCode.bz,
  kOpCodeStringbnz: OpCode.bnz,
  kOpCodeStringdly: OpCode.dly,
  kOpCodeStringstne: OpCode.stne,
  kOpCodeStringlte: OpCode.lte,
  kOpCodeStringgte: OpCode.gte,
  kOpCodeStringjmp: OpCode.jmp,
  kOpCodeStringhalt: OpCode.halt,
};

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

  ExecEntry.fromSnapshot(DatabaseReference ref, DataSnapshot snapshot) {
    print('ExecEntry.fromSnapshot');
    reference = ref;
    key = snapshot.key;
    owner = snapshot.value['owner'];
    name = snapshot.value['name'];
    snapshot.value['p']
        .forEach((e) => p.add(new InstrEntry(e['i'], e['v'].toString())));
    // print('size: ${p.length}');
    cb = snapshot.value['cb'];
  }

  ExecEntry.fromMap(DatabaseReference ref, String k, dynamic v) {
    print('ExecEntry.fromMap');
    reference = ref;
    key = k;
    owner = v['owner'];
    name = v['name'];
    v['p'].forEach((e) => p.add(new InstrEntry(e['i'], e['v'].toString())));
    // print('size: ${p.length}');
    if (v.containsValue('cb') == true) {
      cb = v['cb'];
    }
  }

  setOwner(String _owner) {
    owner = _owner;
  }

  Map toJson() {
    print('ExecEntry.toJson');
    Map map = new Map();
    map['owner'] = owner;
    map['name'] = name;
    map['p'] = p;
    map['cb'] = cb;
    return map;
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
