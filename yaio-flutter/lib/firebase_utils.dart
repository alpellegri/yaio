import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'const.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

UserCredential? _userCredential;

Map _nodeConfigMap = {};
SharedPreferences? _prefs;
String? _nodeConfigJson;

String? dUserRef;
String? dRootRef;
String? dObjRef;
String? dNodeSubPath;
String? dControlRef;
String? dStatusRef;
String? dStartupRef;
String? dFcmTokenRef;
String? dMessagesRef;
String? dLogRef;
String? dTHRef;
String? dDomain;
String? dNodeName;

UserCredential? getFirebaseUser() {
  return _userCredential;
}

Future<UserCredential> signInWithGoogle() async {
  UserCredential? userCredential;
  final googleUser = await GoogleSignIn().signIn();

  // Obtain the auth details from the request
  final googleAuth = await googleUser?.authentication;

  if (googleAuth != null) {
    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    userCredential = await _auth.signInWithCredential(credential);
  }

  _userCredential = userCredential;
  // print(user);
  return userCredential!;
}

void updateUserRef() {
  print('updateUserRef');
  dUserRef = 'users/${getFirebaseUser()?.user?.uid}';
  dRootRef = '$dUserRef/root';
  dObjRef = '$dUserRef/obj';
  dFcmTokenRef = '$dUserRef/$kFcmTokenRef';
  print('dUserRef: $dUserRef');
  print('dRootRef: $dRootRef');
  print('dObjRef: $dObjRef');
  print('dFcmTokenRef: $dFcmTokenRef');
}

void updateNodeRef(Map config) {
  print('updateNodeRef: $config');
  dNodeSubPath = '${config['domain']}/${config['nodename']}';
  String prefixNode = '$dRootRef/$dNodeSubPath';
  String prefixData = '$dObjRef';

  dControlRef = '$prefixNode/$kControlRef';
  dStatusRef = '$prefixNode/$kStatusRef';
  dStartupRef = '$prefixNode/$kStartupRef';
  dMessagesRef = '$prefixData/$kMessagesRef';
  dLogRef = '$prefixData/$kLogRef';
  dTHRef = '$prefixData/$kTHRef';
  dDomain = config['domain'];
  dNodeName = config['nodename'];
}

String? getOwner() {
  return dNodeName;
}

String? getDomain() {
  return dDomain;
}

String? getNode() {
  return dNodeName;
}

Future<Map> loadPreferences() async {
  _prefs = await SharedPreferences.getInstance();
  _nodeConfigJson = _prefs?.getString('node_config_json');
  print('loadPreferences: $_nodeConfigJson');

  updateUserRef();
  if (_nodeConfigJson != null) {
    print(_nodeConfigJson);
    _nodeConfigMap = json.decode(_nodeConfigJson!);
    // override
    _nodeConfigMap['uid'] = getFirebaseUser()?.user?.uid;
    updateNodeRef(_nodeConfigMap);
  }

  return _nodeConfigMap;
}

Map getPreferences() {
  return _nodeConfigMap;
}

void savePreferencesDN(String domain, String node) {
  // override previous
  _nodeConfigMap['domain'] = domain;
  _nodeConfigMap['nodename'] = node;
  _nodeConfigMap['uid'] = getFirebaseUser()?.user?.uid;

  // update firebase references
  updateNodeRef(_nodeConfigMap);

  _nodeConfigJson = json.encode(_nodeConfigMap);
  _prefs?.setString('node_config_json', _nodeConfigJson!);
}

void savePreferencesD(String domain) {
  // override previous
  _nodeConfigMap['domain'] = domain;
  _nodeConfigMap['uid'] = getFirebaseUser()?.user?.uid;

  // update firebase references
  updateNodeRef(_nodeConfigMap);

  _nodeConfigJson = json.encode(_nodeConfigMap);
  _prefs?.setString('node_config_json', _nodeConfigJson!);
}

void savePreferencesSP(String ssid, String password) {
  // override previous
  _nodeConfigMap['ssid'] = ssid;
  _nodeConfigMap['password'] = password;
  _nodeConfigMap['uid'] = getFirebaseUser()?.user?.uid;

  // update firebase references
  updateNodeRef(_nodeConfigMap);

  _nodeConfigJson = json.encode(_nodeConfigMap);
  _prefs?.setString('node_config_json', _nodeConfigJson!);
}

String? getUserRef() {
  return dUserRef;
}

String? getRootRef() {
  return dRootRef;
}

String? getControlRef() {
  return dControlRef;
}

String? getStatusRef() {
  return dStatusRef;
}

String? getStartupRef() {
  return dStartupRef;
}

String? getFcmTokenRef() {
  return dFcmTokenRef;
}

String? getMessagesRef() {
  return dMessagesRef;
}

String? getLogRef() {
  return dLogRef;
}

Map<String, Object> _controlDefault = {
  'reboot': 0,
  'time': -1,
};

Map<String, Object> _startupDefault = {
  'bootcnt': 0,
  'time': 0,
  'version': '',
};

Map<String, Object> _statusDefault = {
  'time': 0,
};

Map<String, Object> getControlDefault() {
  return _controlDefault;
}

Map<String, Object> getStatusDefault() {
  return _statusDefault;
}

Map<String, Object> getStartupDefault() {
  return _startupDefault;
}

void nodeRefresh(String domain, String node) {
  print('nodeRefresh: $domain/$node');
  DatabaseReference rootRef =
      FirebaseDatabase.instance.ref().child(getRootRef()!);
  DateTime now = DateTime.now();
  int time = now.millisecondsSinceEpoch ~/ 1000;
  rootRef.child('$domain/$node/control/time').set(time);
}
