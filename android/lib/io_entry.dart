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

  int getPort() {
    id ??= 0;
    return id >> 8;
  }

  setPort(int port) {
    id ??= 0;
    int value = id & 0xFF;
    id = port << 8 | value;
  }

  int getValue() {
    id ??= 0;
    return id & 0xFF;
  }

  setValue(int value) {
    id ??= 0;
    int port = id >> 8;
    id = (port << 8) | (value & 0xFF);
  }

  toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
