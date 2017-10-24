import 'package:firebase_database/firebase_database.dart';

class FunctionEntry {
  DatabaseReference reference;
  String key;
  String name;
  int id;
  int action;
  String action_name;
  int delay;
  String next;
  int type;
  String type_name;

  FunctionEntry(DatabaseReference ref) : reference = ref;

  FunctionEntry.fromSnapshot(DatabaseReference ref, DataSnapshot snapshot)
      : reference = ref,
        key = snapshot.key,
        action = snapshot.value['action'] ?? 0,
        action_name = snapshot.value['action_name'] ?? '',
        delay = snapshot.value['delay'] ?? 0,
        id = snapshot.value['id'] ?? 0,
        name = snapshot.value['name'] ?? '',
        next = snapshot.value['next'] ?? '',
        type = snapshot.value['type'] ?? 0,
        type_name = snapshot.value['type_name'] ?? '';

  toJson() {
    return {
      'action': action,
      'action_name': action_name,
      'delay': delay,
      'id': id,
      'name': name,
      'next': next,
      'type': type,
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
  int id;

  IoEntry(DatabaseReference ref) : reference = ref;

  IoEntry.fromSnapshot(DatabaseReference ref, DataSnapshot snapshot)
      : reference = ref,
        key = snapshot.key,
        id = snapshot.value['id'],
        name = snapshot.value['name'];

  setName(String name) {
    this.name = name;
  }

  getName() {
    return name;
  }

  setPort(int port) {
    int _value = id & 0x01;
    id = port << 1 | _value;
  }

  setValue(int value) {
    int _port = id >> 1;
    id = (_port << 1) | (value & 0x01);
  }

  int getPort() {
    return id >> 1;
  }

  int getValue() {
    return id & 0x01;
  }

  toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
