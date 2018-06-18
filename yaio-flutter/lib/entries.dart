import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

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

// ......XXXXXX.........
//             ^--------| pos
//      ^------| len
int getBits(int value, int pos, int len) {
  if ((pos + len) > 32) {
    len = 32 - pos;
  }
  int m = ((1 << len) - 1) << pos;
  int v = (value & m) >> pos;
  return v;
}

int setBits(int pos, int len, int v) {
  int value = 0;
  if ((pos + len) > 32) {
    len = 32 - pos;
  }
  int m = ((1 << len) - 1) << pos;
  value &= ~m;
  value |= v << pos;
  return value;
}

int clearBits(int v, int pos, int len) {
  if ((pos + len) > 32) {
    len = 32 - pos;
  }
  int m = ((1 << len) - 1) << pos;
  v &= ~m;
  return v;
}

String getValueCtrl1(IoEntryControl data) {
  String v;
  switch (DataCode.values[data.code]) {
    case DataCode.PhyIn:
    case DataCode.PhyOut:
    case DataCode.RadioRx:
    case DataCode.RadioTx:
      v = (data.ioctl).toString();
      break;
    case DataCode.DhtTemperature:
    case DataCode.DhtHumidity:
      v = getBits(data.ioctl, 0, 8).toString();
      break;
    case DataCode.Timer:
      DateTime now = new DateTime.now();
      // compensate timezone
      v = ((24 + (int.parse(data.value) ~/ 60) + now.timeZoneOffset.inHours) %
              24)
          .toString();
      break;
    default:
  }

  return v;
}

String getValueCtrl2(IoEntryControl data) {
  String v;
  switch (DataCode.values[data.code]) {
    case DataCode.PhyIn:
    case DataCode.PhyOut:
    case DataCode.RadioRx:
    case DataCode.RadioTx:
    case DataCode.RadioMach:
    case DataCode.Int:
    case DataCode.Float:
    case DataCode.Messaging:
      v = data.value.toString();
      break;
    case DataCode.DhtTemperature:
    case DataCode.DhtHumidity:
      v = getBits(data.ioctl, 8, 8).toString();
      break;
    case DataCode.Bool:
      if (data.value == 'false') {
        v = '0';
      } else if (data.value == 'true') {
        v = '1';
      } else {
        print('_controller_2.text error');
        v = '0';
      }
      break;
    case DataCode.Timer:
      v = (int.parse(data.value) % 60).toString();
      break;
    default:
  }
  return v;
}

int getValueCtrl3(IoEntryControl data) {
  int v;
  switch (DataCode.values[data.code]) {
    case DataCode.Timer:
      v = getBits(data.ioctl, 16, 9);
      break;
    default:
  }
  return v;
}

IoEntryControl setValueCtrl1(IoEntryControl data, String v) {
  IoEntryControl local = data;
  switch (DataCode.values[data.code]) {
    case DataCode.PhyIn:
    case DataCode.PhyOut:
    case DataCode.RadioRx:
    case DataCode.RadioTx:
      local.ioctl = int.parse(v);
      break;
    case DataCode.DhtTemperature:
    case DataCode.DhtHumidity:
      // pin
      local.ioctl = clearBits(local.ioctl, 0, 8);
      local.ioctl |= setBits(0, 8, int.parse(v));
      break;
    case DataCode.Timer:
      // binary values
      DateTime now = new DateTime.now();
      int h = (24 + int.parse(v) - now.timeZoneOffset.inHours) % 24;
      local.value = (60 * h) + (local.value % 60);
      break;
    default:
  }
  return local;
}

IoEntryControl setValueCtrl2(IoEntryControl data, String v) {
  IoEntryControl local = data;
  switch (DataCode.values[data.code]) {
    case DataCode.PhyIn:
    case DataCode.PhyOut:
    case DataCode.RadioRx:
    case DataCode.RadioTx:
    case DataCode.RadioMach:
    case DataCode.Int:
    case DataCode.Float:
      // binary values
      local.value = v;
      break;
    case DataCode.DhtTemperature:
    case DataCode.DhtHumidity:
      // binary values
      // period
      local.ioctl = clearBits(local.ioctl, 8, 8);
      local.ioctl |= setBits(8, 8, int.parse(v));
      break;
    case DataCode.Messaging:
      // string values
      local.value = v;
      break;
    case DataCode.Bool:
      local.value = v;
      break;
    case DataCode.Timer:
      // binary values
      int value = int.parse(local.value);
      local.value = (value - (value % 60)) + int.parse(v);
      break;
    default:
  }
  return local;
}

IoEntryControl setValueCtrl3(IoEntryControl data, String v) {
  IoEntryControl local = data;
  switch (DataCode.values[data.code]) {
    case DataCode.Timer:
      local.ioctl = clearBits(local.ioctl, 16, 9);
      local.ioctl |= setBits(16, 9, int.parse(v));
      break;
    default:
  }
  return local;
}

class IoEntryControl {
  int code;
  dynamic value;
  int ioctl;

  IoEntryControl(this.code, this.value, this.ioctl);
}

class IoEntry {
  static const int shift = 24;
  static const int mask = (1 << shift) - 1;
  DatabaseReference reference;
  bool exist = false;
  bool drawWr = false;
  bool drawRd = false;
  bool enLog = false;
  String key;
  String owner;
  int code;
  dynamic value;
  int ioctl;
  String cb;

  IoEntry(DatabaseReference ref) : reference = ref;

  IoEntry.fromMap(DatabaseReference ref, String k, dynamic v) {
    reference = ref;
    exist = true;
    key = k;
    owner = v['owner'];
    code = v['code'];
    value = v['value'];
    ioctl = v['ioctl'];
    cb = v['cb'];
    if (v['drawWr'] != null) {
      drawWr = v['drawWr'];
    }
    if (v['drawRd'] != null) {
      drawRd = v['drawRd'];
    }
    enLog = v['enLog'];
  }

  dynamic getValue() {
    dynamic v;
    switch (DataCode.values[code]) {
      case DataCode.PhyIn:
      case DataCode.PhyOut:
      case DataCode.RadioRx:
      case DataCode.RadioTx:
      case DataCode.RadioMach:
      case DataCode.Bool:
      case DataCode.Int:
      case DataCode.Float:
      case DataCode.Messaging:
        v = value;
        break;
      case DataCode.DhtTemperature:
      case DataCode.DhtHumidity:
        v = value / 10;
        break;
      case DataCode.Timer:
        // binary values
        DateTime now = new DateTime.now();
        int h = ((24 + (value ~/ 60)) + now.timeZoneOffset.inHours) % 24;
        int m = value % 60;
        DateTime dtset = new DateTime(0, 0, 0, h, m);
        v = new DateFormat('Hm').format(dtset);
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
    map['ioctl'] = ioctl;
    map['cb'] = cb;
    if (drawWr != false) {
      map['drawWr'] = drawWr;
    }
    if (drawRd != false) {
      map['drawRd'] = drawRd;
    }
    map['enLog'] = enLog;
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

class MessageEntry {
  String key;
  DateTime dateTime;
  String source;
  String message;

  MessageEntry(this.dateTime, this.message);

  MessageEntry.fromSnapshot(DataSnapshot snapshot)
      : key = snapshot.key,
        dateTime = new DateTime.fromMillisecondsSinceEpoch(
            snapshot.value["time"] * 1000),
        source = snapshot.value["source"],
        message = snapshot.value["msg"];

  Map toJson() {
    return {
      'source': message,
      'message': message,
      'date': dateTime.millisecondsSinceEpoch,
    };
  }
}

class LogEntry {
  double x;
  double y;

  LogEntry(this.x, this.y);
}
