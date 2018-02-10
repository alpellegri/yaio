import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';

const String kStringPhyIn = 'PhyIn';
const String kStringPhyOut = 'PhyOut';
const String kStringLogIn = 'LogIn';
const String kStringLogOut = 'LogOut';
const String kStringRadioIn = 'RadioIn';
const String kStringRadioOut = 'RadioTx';
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
  RadioTx,
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
  DataCode.RadioTx: kStringRadioOut,
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
  kStringRadioOut: DataCode.RadioTx,
  kStringRadioElem: DataCode.RadioElem,
  kStringTimer: DataCode.Timer,
  kStringBool: DataCode.Bool,
  kStringInt: DataCode.Int,
  kStringFloat: DataCode.Float,
  kStringRadioRx: DataCode.RadioRx,
  kStringMessaging: DataCode.Messaging,
};

int getMode(int type) {
  int mode;
  if (type != null) {
    switch (DataCode.values[type]) {
    // integer values with pin8 and value24
      case DataCode.PhyIn:
      case DataCode.PhyOut:
      case DataCode.RadioRx:
      case DataCode.RadioTx:
        mode = 1;
        break;
    // full integer or floating value
      case DataCode.RadioIn:
      case DataCode.Int:
      case DataCode.Float:
        mode = 2;
        break;
    // string value
      case DataCode.Messaging:
        mode = 3;
        break;
      default:
        mode = 0;
    }
  } else {
    mode = 0;
  }

  return mode;
}

class IoEntry {
  static const int shift = 24;
  static const int mask = (1 << shift) - 1;
  DatabaseReference reference;
  bool exist = false;
  String key;
  String owner;
  int code;
  dynamic value;
  String cb;

  IoEntry(DatabaseReference ref) : reference = ref;

  IoEntry.fromMap(DatabaseReference ref, String k, dynamic v) {
    reference = ref;
    exist = true;
    key = k;
    owner = v['owner'];
    code = v['code'];
    value = v['value'];
    cb = v['cb'];
  }

  int getPin8() {
    value ??= 0;
    return value >> shift;
  }

  setPin8(int pin) {
    value ??= 0;
    value = value & mask;
    value = (pin << shift | value);
  }

  int getValue24() {
    value ??= 0;
    return value & mask;
  }

  setValue24(int v) {
    value ??= 0;
    int port = value >> shift;
    value = ((port << shift) | (v & mask));
  }

  dynamic getValue() {
    return value;
  }

  setValue(dynamic v) {
    value = v;
  }

  setOwner(String _owner) {
    owner = _owner;
  }

  Map toJson() {
    exist = true;
    Map<String, dynamic> map = new Map<String, dynamic>();
    map['owner'] = owner;
    map['code'] = code;
    map['value'] = value;
    map['cb'] = cb;
    return map;
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
const String kOpCodeStringhalt = 'halt';
const String kOpCodeStringjmp = 'jmp';

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
  OpCode.halt: true,
  OpCode.jmp: true,
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
  OpCode.halt: kOpCodeStringhalt,
  OpCode.jmp: kOpCodeStringjmp,
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
  kOpCodeStringhalt: OpCode.halt,
  kOpCodeStringjmp: OpCode.jmp,
};

class InstrEntry {
  int i;
  String v;

  InstrEntry(this.i, this.v);
}

class ExecEntry {
  DatabaseReference reference;
  bool exist = false;
  String key;
  String owner;
  String cb;
  List<InstrEntry> p = new List<InstrEntry>();

  ExecEntry(DatabaseReference ref) : reference = ref;

  ExecEntry.fromMap(DatabaseReference ref, String k, dynamic v) {
    // print('ExecEntry.fromMap');
    reference = ref;
    exist = true;
    key = k;
    owner = v['owner'];
    if (v['p'] != null) {
      v['p'].forEach((e) => p.add(new InstrEntry(e['i'], e['v'].toString())));
    }
    cb = v['cb'];
  }

  setOwner(String _owner) {
    owner = _owner;
  }

  Map<String, dynamic> toJson() {
    print('ExecEntry.toJson');
    exist = true;
    Map<String, dynamic> map = new Map<String, dynamic>();
    map['owner'] = owner;
    List list = new List();
    if (p.length > 0) {
      p.forEach((e) {
        list.add({'i': e.i, 'v': e.v});
      });
      map['p'] = list;
    }
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

  Map toJson() {
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

  Map toJson() {
    return {
      't': t,
      'h': h,
      'time': time,
    };
  }
}
