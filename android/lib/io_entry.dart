import 'package:firebase_database/firebase_database.dart';

class FunctionEntry {
  DatabaseReference reference;
  String key;
  String name;
  int id_action;
  String action_name;
  int delay;
  String next;
  int id_type;
  String type_name;

  FunctionEntry(DatabaseReference ref) : reference = ref;

  FunctionEntry.fromSnapshot(DatabaseReference ref, DataSnapshot snapshot)
      : reference = ref,
        key = snapshot.key,
        id_action = snapshot.value['action'] ?? 0,
        action_name = snapshot.value['action_name'] ?? '',
        delay = snapshot.value['delay'] ?? 0,
        name = snapshot.value['name'] ?? '',
        next = snapshot.value['next'] ?? '',
        id_type = snapshot.value['type'] ?? 0,
        type_name = snapshot.value['type_name'] ?? '';

  toJson() {
    return {
      'action': id_action,
      'action_name': action_name,
      'delay': delay,
      'name': name,
      'next': next,
      'type': id_type,
      'type_name': type_name,
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
