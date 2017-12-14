import 'dart:convert';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = new GoogleSignIn();

FirebaseUser _user;

FirebaseUser getFirebaseUser() {
  return _user;
}

Future<Map> configFirefase() async {
  final String fbConfig = await rootBundle.loadString('android/app/google-services.json');
  Map parsedMap = JSON.decode(fbConfig);
  return parsedMap;
}

Future<String> signInWithGoogle() async {
  final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
  final GoogleSignInAuthentication googleAuth =
  await googleUser.authentication;
  final FirebaseUser user = await _auth.signInWithGoogle(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );
  assert(user.email != null);
  assert(user.displayName != null);
  assert(!user.isAnonymous);
  assert(await user.getIdToken() != null);

  final FirebaseUser currentUser = await _auth.currentUser();
  assert(user.uid == currentUser.uid);
  print(user);
  _user = user;
  return 'signInWithGoogle succeeded: $user';
}

Map _nodeConfigMap;
SharedPreferences _prefs;
String _nodeConfigJson;

Future<Map> initSharedPreferences() async {
  _prefs = await SharedPreferences.getInstance();
  _nodeConfigJson = _prefs.getString('node_config_json');

  if (_nodeConfigJson != null) {
    _nodeConfigMap = JSON.decode(_nodeConfigJson);
  }
  _nodeConfigMap['uid'] = getFirebaseUser().uid;
  _nodeConfigJson = JSON.encode(_nodeConfigMap);

  return _nodeConfigMap;
}
