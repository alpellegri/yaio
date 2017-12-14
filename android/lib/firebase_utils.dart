import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'const.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = new GoogleSignIn();

FirebaseUser _user;

Map _nodeConfigMap;
SharedPreferences _prefs;
String _nodeConfigJson;

String dControlRef;
String dStatusRef;
String dStartupRef;
String dTokenIDsRef;
String dFunctionsRef;
String dGraphRef;
String dLogsReportsRef;
String dTHRef;

FirebaseUser getFirebaseUser() {
  return _user;
}

Future<Map> configFirefase() async {
  final String fbConfig =
      await rootBundle.loadString('android/app/google-services.json');
  Map parsedMap = JSON.decode(fbConfig);
  return parsedMap;
}

Future<String> signInWithGoogle() async {
  final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
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

Future<Null> initSharedPreferences() async {
  _prefs = await SharedPreferences.getInstance();
  _nodeConfigJson = _prefs.getString('node_config_json');

  if (_nodeConfigJson != null) {
    _nodeConfigMap = JSON.decode(_nodeConfigJson);
  }
  _nodeConfigMap['uid'] = getFirebaseUser().uid;
  _nodeConfigJson = JSON.encode(_nodeConfigMap);
  String prefix = 'users/' +
      _nodeConfigMap['uid'] +
      '/' +
      _nodeConfigMap['domain'] +
      '/' +
      _nodeConfigMap['nodename'] + '/';
  dControlRef = prefix + kControlRef;
  dStatusRef = prefix + kStatusRef;
  dStartupRef = prefix + kStartupRef;
  dTokenIDsRef = prefix + kTokenIDsRef;
  dFunctionsRef = prefix + kFunctionsRef;
  dGraphRef = prefix + kGraphRef;
  dLogsReportsRef = prefix + kLogsReportsRef;
  dTHRef = prefix + kTHRef;
}

String getControlRef() {
  print(dControlRef);
  return dControlRef;
}
String getStatusRef() {
  print(dStatusRef);
  return dStatusRef;
}
String getStartupRef() {
  print(dStartupRef);
  return dStartupRef;
}
String getTokenIDsRef() {
  print(dTokenIDsRef);
  return dTokenIDsRef;
}
String getFunctionsRef() {
  print(dFunctionsRef);
  return dFunctionsRef;
}
String getGraphRef() {
  print(dGraphRef);
  return dGraphRef;
}
String getLogsReportsRef() {
  print(dLogsReportsRef);
  return dLogsReportsRef;
}
String getTHRef() {
  print(dTHRef);
  return dTHRef;
}
