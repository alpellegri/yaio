import 'package:firebase_database/firebase_database.dart';

const String kStringPhyIn = 'PhyIn';
const String kStringPhyOut = 'PhyOut';
const String kDhtTemperature = 'Temperature';
const String kDhtHumidity = 'Humidity';
const String kStringRadioRx = 'RadioRx';
const String kStringRadioMach = 'RadioIn';
const String kStringRadioTx = 'RadioTx';
const String kStringTimer = 'Timer';
const String kStringBool = 'Bool';
const String kStringInt = 'Int';
const String kStringFloat = 'Float';
const String kStringMessaging = 'Messaging';

enum DataCode {
  PhyIn,
  PhyOut,
  DhtTemperature,
  DhtHumidity,
  RadioRx,
  RadioMach,
  RadioTx,
  Timer,
  Bool,
  Int,
  Float,
  Messaging,
}

const Map<DataCode, String> kEntryId2Name = const {
  DataCode.PhyIn: kStringPhyIn,
  DataCode.PhyOut: kStringPhyOut,
  DataCode.DhtTemperature: kDhtTemperature,
  DataCode.DhtHumidity: kDhtHumidity,
  DataCode.RadioRx: kStringRadioRx,
  DataCode.RadioMach: kStringRadioMach,
  DataCode.RadioTx: kStringRadioTx,
  DataCode.Timer: kStringTimer,
  DataCode.Bool: kStringBool,
  DataCode.Int: kStringInt,
  DataCode.Float: kStringFloat,
  DataCode.Messaging: kStringMessaging,
};

const Map<String, DataCode> kEntryName2Id = const {
  kStringPhyIn: DataCode.PhyIn,
  kStringPhyOut: DataCode.PhyOut,
  kDhtTemperature: DataCode.DhtTemperature,
  kDhtHumidity: DataCode.DhtHumidity,
  kStringRadioRx: DataCode.RadioRx,
  kStringRadioMach: DataCode.RadioMach,
  kStringRadioTx: DataCode.RadioTx,
  kStringTimer: DataCode.Timer,
  kStringBool: DataCode.Bool,
  kStringInt: DataCode.Int,
  kStringFloat: DataCode.Float,
  kStringMessaging: DataCode.Messaging,
};

int getBits(int value, int pos, int len) {
  pos++;
  if (pos < len) {
    pos = len;
  }
  int sh = pos - len;
  int m = ((1 << len) - 1) << sh;
  int v = (value & m) >> sh;
  return v;
}

int setBits(int pos, int len, int v) {
  int value = 0;
  pos++;
  if (pos < len) {
    pos = len;
  }
  int sh = pos - len;
  int m = ((1 << len) - 1) << sh;
  value &= ~m;
  value |= v << sh;
  return value;
}

int clearBits(int v, int pos, int len) {
  pos++;
  if (pos < len) {
    pos = len;
  }
  int sh = pos - len;
  int m = ((1 << len) - 1) << sh;
  v &= ~m;
  return v;
}

dynamic getValueCtrl1(code, value) {
  dynamic v;
  switch (DataCode.values[code]) {
    case DataCode.PhyIn:
    case DataCode.PhyOut:
    case DataCode.RadioRx:
    case DataCode.RadioTx:
    case DataCode.DhtTemperature:
    case DataCode.DhtHumidity:
      v = getBits(value, 31, 8);
      break;
    case DataCode.Timer:
      v = getBits(value, 15, 8);
      break;
    default:
  }
  return v;
}

dynamic getValueCtrl2(int code, dynamic value) {
  dynamic v;
  switch (DataCode.values[code]) {
    case DataCode.PhyIn:
    case DataCode.PhyOut:
    case DataCode.RadioRx:
    case DataCode.RadioTx:
      v = getBits(value, 23, 24);
      break;
    case DataCode.DhtTemperature:
    case DataCode.DhtHumidity:
      v = getBits(value, 23, 8);
      break;
    case DataCode.RadioMach:
    case DataCode.Int:
    case DataCode.Float:
    case DataCode.Messaging:
      v = value;
      break;
    case DataCode.Bool:
      if (value == false) {
        v = '0';
      } else if (value == true) {
        v = '1';
      } else {
        print('_controller_2.text error');
        v = '0';
      }
      break;
    case DataCode.Timer:
      v = getBits(value, 7, 8);
      break;
    default:
  }
  return v;
}

dynamic setValueCtrl1(dynamic value, int code, dynamic v) {
  print(value);
  switch (DataCode.values[code]) {
    case DataCode.PhyIn:
    case DataCode.PhyOut:
    case DataCode.RadioRx:
    case DataCode.RadioTx:
    case DataCode.DhtTemperature:
    case DataCode.DhtHumidity:
      value = clearBits(value, 31, 8);
      value |= setBits(31, 8, int.parse(v));
      break;
    case DataCode.Timer:
      value = clearBits(value, 15, 8);
      value |= setBits(15, 8, int.parse(v));
      break;
    default:
  }
  print(value);
  return value;
}

dynamic setValueCtrl2(dynamic value, int code, dynamic v) {
  print(value);
  switch (DataCode.values[code]) {
    case DataCode.PhyIn:
    case DataCode.PhyOut:
    case DataCode.RadioRx:
    case DataCode.RadioTx:
      value = clearBits(value, 23, 24);
      value |= setBits(23, 24, int.parse(v));
      break;
    case DataCode.RadioMach:
    case DataCode.Int:
    case DataCode.Float:
    case DataCode.Messaging:
      value = v;
      break;
    case DataCode.Bool:
      if (v == '0') {
        value = false;
      } else if (v == '1') {
        value = true;
      } else {
        print('ctrl_2.text error');
      }
      break;
    case DataCode.DhtTemperature:
    case DataCode.DhtHumidity:
      value = clearBits(value, 23, 8);
      value |= setBits(23, 8, int.parse(v));
      break;
    case DataCode.Timer:
      value = clearBits(value, 7, 8);
      value |= setBits(7, 8, int.parse(v));
      break;
  }
  print(value);
  return value;
}

class IoEntry {
  static const int shift = 24;
  static const int mask = (1 << shift) - 1;
  DatabaseReference reference;
  bool exist = false;
  bool drawWr = false;
  bool drawRd = false;
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
    if (v['drawWr'] != null) {
      drawWr = v['drawWr'];
    }
    if (v['drawRd'] != null) {
      drawRd = v['drawRd'];
    }
  }

  dynamic getValue() {
    dynamic v;
    switch (DataCode.values[code]) {
      case DataCode.PhyIn:
      case DataCode.PhyOut:
      case DataCode.RadioRx:
      case DataCode.RadioMach:
      case DataCode.RadioTx:
        v = getBits(value, 23, 24);
        break;
      case DataCode.DhtTemperature:
      case DataCode.DhtHumidity:
        v = getBits(value, 15, 16) / 10;
        break;
      case DataCode.Timer:
        v = (getBits(value, 15, 8) * 60) + getBits(value, 7, 8);
        break;
      case DataCode.Bool:
      case DataCode.Int:
      case DataCode.Float:
      case DataCode.Messaging:
        v = value;
        break;
    }
    return v;
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
    if (drawWr != false) {
      map['drawWr'] = drawWr;
    }
    if (drawRd != false) {
      map['drawRd'] = drawRd;
    }
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
    // print('ExecEntry.toJson');
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
