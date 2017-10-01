import 'package:firebase_database/firebase_database.dart';

class IoEntry {
  String key;
  int id;
  String name;

  IoEntry(this.id, this.name);

  IoEntry.fromSnapshot(DataSnapshot snapshot)
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
