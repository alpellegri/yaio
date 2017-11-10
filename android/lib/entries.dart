import 'package:firebase_database/firebase_database.dart';

const int kDOut = 0;
const int kRadioIn = 1;
const int kLOut = 2;
const int kDIn = 3;
const int kRadioOut = 4;
List<String> kEntryId2Name = ['DOut', 'RadioIn', 'LOut', 'DIn', 'RadioOut'];

class IoEntry {
  static const int shift = 24;
  static const int mask = (1 << shift) - 1;
  DatabaseReference reference;
  String key;
  int type;
  String name;
  int id;
  String func;

  IoEntry(DatabaseReference ref) : reference = ref;

  IoEntry.fromSnapshot(DatabaseReference ref, DataSnapshot snapshot) {
    reference = ref;
    key = snapshot.key;
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

  String getName(int type) {
    return kEntryId2Name[type];
  }

  toJson() {
    return {
      'type': type,
      'id': id,
      'name': name,
      'func': func,
    };
  }
}

class FunctionEntry {
  DatabaseReference reference;
  String key;
  String name;
  int idAction;
  String actionName;
  int delay;
  String next;
  int idType;
  String typeName;

  FunctionEntry(DatabaseReference ref) : reference = ref;

  FunctionEntry.fromSnapshot(DatabaseReference ref, DataSnapshot snapshot)
      : reference = ref,
        key = snapshot.key,
        idAction = snapshot.value['action'],
        actionName = snapshot.value['action_name'],
        delay = snapshot.value['delay'],
        name = snapshot.value['name'],
        next = snapshot.value['next'],
        idType = snapshot.value['type'],
        typeName = snapshot.value['type_name'];

  toJson() {
    return {
      'action': idAction,
      'action_name': actionName,
      'delay': delay,
      'name': name,
      'next': next,
      'type': idType,
      'type_name': typeName,
    };
  }
}
