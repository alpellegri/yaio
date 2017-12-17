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

Map _nodeConfigMap = new Map();
SharedPreferences _prefs;
String _nodeConfigJson;

String dRootRef;
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

Future<Map> loadPreferences() async {
  dRootRef = 'users/' + getFirebaseUser().uid + '/root';

  _prefs = await SharedPreferences.getInstance();
  _nodeConfigJson = _prefs.getString('node_config_json');

  if (_nodeConfigJson != null) {
    _nodeConfigMap = JSON.decode(_nodeConfigJson);
    print(_nodeConfigMap);
    String prefix = dRootRef +
        '/' +
        _nodeConfigMap['domain'] +
        '/' +
        _nodeConfigMap['nodename'] +
        '/';
    dControlRef = prefix + kControlRef;
    dStatusRef = prefix + kStatusRef;
    dStartupRef = prefix + kStartupRef;
    dTokenIDsRef = prefix + kTokenIDsRef;
    dFunctionsRef = prefix + kFunctionsRef;
    dGraphRef = prefix + kGraphRef;
    dLogsReportsRef = prefix + kLogsReportsRef;
    dTHRef = prefix + kTHRef;
    _nodeConfigMap['uid'] = getFirebaseUser().uid;
  }

  return _nodeConfigMap;
}

Map getPreferences() {
  return _nodeConfigMap;
}

void savePreferences(String domain, String ssid, String password, String node) {
  _nodeConfigMap['ssid'] = ssid;
  _nodeConfigMap['password'] = password;
  _nodeConfigMap['domain'] = domain;
  _nodeConfigMap['nodename'] = node;
  _nodeConfigMap['uid'] = getFirebaseUser().uid;

  _nodeConfigJson = JSON.encode(_nodeConfigMap);
  if (_nodeConfigJson != null) {
    _nodeConfigMap = JSON.decode(_nodeConfigJson);
    print(_nodeConfigMap);
    String prefix = dRootRef +
        '/' +
        _nodeConfigMap['domain'] +
        '/' +
        _nodeConfigMap['nodename'] +
        '/';
    dControlRef = prefix + kControlRef;
    dStatusRef = prefix + kStatusRef;
    dStartupRef = prefix + kStartupRef;
    dTokenIDsRef = prefix + kTokenIDsRef;
    dFunctionsRef = prefix + kFunctionsRef;
    dGraphRef = prefix + kGraphRef;
    dLogsReportsRef = prefix + kLogsReportsRef;
    dTHRef = prefix + kTHRef;
    _nodeConfigMap['uid'] = getFirebaseUser().uid;
  }
  _prefs.setString('node_config_json', _nodeConfigJson);
}

String _token;
String getFbToken() {
  return _token;
}
void setFbToken(String token) {
  _token = token;
}

String getRootRef() {
  print('getRootRef: $dRootRef');
  return dRootRef;
}

String getControlRef() {
  print('getControlRef: $dControlRef');
  return dControlRef;
}

String getStatusRef() {
  print('getStatusRef: $dStatusRef');
  return dStatusRef;
}

String getStartupRef() {
  print('getStartupRef: $dStartupRef');
  return dStartupRef;
}

String getTokenIDsRef() {
  print('getTokenIDsRef: $dTokenIDsRef');
  return dTokenIDsRef;
}

String getFunctionsRef() {
  print('getFunctionsRef: $dFunctionsRef');
  return dFunctionsRef;
}

String getGraphRef() {
  print('getGraphRef: $dLogsReportsRef');
  return dLogsReportsRef;
}

String getLogsReportsRef() {
  print('getLogsReportsRef: $dLogsReportsRef');
  return dLogsReportsRef;
}

String getTHRef() {
  print('getTHRef: $dTHRef');
  return dTHRef;
}

Map<String, Object> _controlDefault = {
  'alarm': false,
  'reboot': false,
  'time': -1,
};

Map<String, Object> _startupDefault = {
  'bootcnt': 0,
  'time': 0,
  'version': '',
};

Map<String, Object> _statusDefault = {
  'alarm': false,
  'heap': 0,
  'humidity': 0,
  'temperature': 0,
  'time': 0,
};

Map<String, Object> getControlDefault() {
  return _controlDefault;
}

Map<String, Object> getStartupDefault() {
  return _startupDefault;
}

Map<String, Object> getStatusDefault() {
  return _statusDefault;
}
