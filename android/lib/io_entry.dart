import 'package:firebase_database/firebase_database.dart';

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
        idAction = snapshot.value['action'] ?? 0,
        actionName = snapshot.value['actionName'] ?? '',
        delay = snapshot.value['delay'] ?? 0,
        name = snapshot.value['name'] ?? '',
        next = snapshot.value['next'] ?? '',
        idType = snapshot.value['type'] ?? 0,
        typeName = snapshot.value['typeName'] ?? '';

  toJson() {
    return {
      'action': idAction,
      'action_name': actionName,
      'delay': delay,
      'name': name,
      'next': next,
      'type': idType,
      'typeName': typeName,
    };
  }
}

class RadioCodeEntry {
  DatabaseReference reference;
  String key;
  String name;
  int id;
  String func;

  RadioCodeEntry(DatabaseReference ref) : reference = ref;

  RadioCodeEntry.fromSnapshot(DatabaseReference ref, DataSnapshot snapshot) {
    reference = ref;
    key = snapshot.key;
    func = snapshot.value['func'] ?? '';
    id = snapshot.value['id'] ?? 0;
    name = snapshot.value['name'] ?? '';
  }

  toJson() {
    return {
      'name': name,
      'id': id,
      'func': func,
    };
  }
}

class IoEntry {
  DatabaseReference reference;
  String key;
  String name;
  int _id;

  IoEntry(DatabaseReference ref) : reference = ref;

  IoEntry.fromSnapshot(DatabaseReference ref, DataSnapshot snapshot)
      : reference = ref,
        key = snapshot.key,
        _id = snapshot.value['id'],
        name = snapshot.value['name'];

  int getPort() {
    return _id >> 1;
  }

  setPort(int port) {
    int _value = _id & 0x01;
    _id = port << 1 | _value;
  }

  int getValue() {
    return _id & 0x01;
  }

  setValue(int value) {
    int _port = _id >> 1;
    _id = (_port << 1) | (value & 0x01);
  }

  toJson() {
    return {
      'id': _id,
      'name': name,
    };
  }
}
