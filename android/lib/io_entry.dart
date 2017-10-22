import 'package:firebase_database/firebase_database.dart';

class FunctionEntry {
  DatabaseReference reference;
  String key;
  int action;
  String action_name;
  int delay;
  int id;
  String name;
  String next;
  int type;
  String type_name;

  FunctionEntry(this.id, this.name);

  FunctionEntry.fromSnapshot(DatabaseReference ref, DataSnapshot snapshot)
      : key = snapshot.key,
        action = snapshot.value['action'],
        action_name = snapshot.value['action_name'],
        delay = snapshot.value['delay'],
        id = snapshot.value['id'],
        name = snapshot.value['name'],
        next = snapshot.value['next'],
        type = snapshot.value['type'],
        type_name = snapshot.value['type_name'];

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
  String func;
  int id;
  String name;

  RadioCodeEntry(this.id, this.name);

  RadioCodeEntry.fromSnapshot(DatabaseReference ref, DataSnapshot snapshot) {
    reference = ref;
    key = snapshot.key;
    func = snapshot.value['func'] ?? '';
    id = snapshot.value['id'] ?? 0;
    name = snapshot.value['name'] ?? '';
  }

  toJson() {
    return {
      'func': func,
      'id': id,
      'name': name,
    };
  }
}

class IoEntry {
  DatabaseReference reference;
  String key;
  int id;
  String name;

  IoEntry(this.id, this.name);

  IoEntry.fromSnapshot(DatabaseReference ref, DataSnapshot snapshot)
      : key = snapshot.key,
        id = snapshot.value['id'],
        name = snapshot.value['name'];

  toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
