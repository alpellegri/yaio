import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'const.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = new GoogleSignIn();

FirebaseUser _user;

Map _nodeConfigMap = new Map();
SharedPreferences _prefs;
String _nodeConfigJson;

String dUserRef;
String dRootRef;
String dObjRef;
String dNodeSubPath;
String dControlRef;
String dStatusRef;
String dStartupRef;
String dFcmTokenRef;
String dDataRef;
String dExecRef;
String dMessagesRef;
String dTHRef;
String dDomain;
String dNodeName;

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

void updateUserRef() {
  print('updateUserRef');
  dUserRef = 'users/${getFirebaseUser().uid}';
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
  dDataRef = '$prefixData/$kDataRef/${config['domain']}';
  dExecRef = '$prefixData/$kExecRef/$dNodeSubPath';
  dMessagesRef = '$prefixData/$kMessagesRef/${config['domain']}';
  dTHRef = '$prefixData/$kTHRef';
  dDomain = config['domain'];
  dNodeName = config['nodename'];
  print('dControlRef: $dControlRef');
  print('dStatusRef: $dStatusRef');
  print('dStartupRef: $dStartupRef');
  print('dDataRef: $dDataRef');
  print('dExecRef: $dExecRef');
  print('dMessagesRef: $dMessagesRef');
  print('dTHRef: $dTHRef');
}

String getOwner() {
  return dNodeName;
}

String getDomain() {
  return dDomain;
}

Future<Map> loadPreferences() async {
  _prefs = await SharedPreferences.getInstance();
  _nodeConfigJson = _prefs.getString('node_config_json');
  print('loadPreferences: $_nodeConfigJson');

  updateUserRef();
  if (_nodeConfigJson != null) {
    print(_nodeConfigJson);
    _nodeConfigMap = json.decode(_nodeConfigJson);
    // override
    _nodeConfigMap['uid'] = getFirebaseUser().uid;
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
  _nodeConfigMap['uid'] = getFirebaseUser().uid;

  // update firebase references
  updateNodeRef(_nodeConfigMap);

  _nodeConfigJson = json.encode(_nodeConfigMap);
  _prefs.setString('node_config_json', _nodeConfigJson);
}

void savePreferencesSP(String ssid, String password) {
  // override previous
  _nodeConfigMap['ssid'] = ssid;
  _nodeConfigMap['password'] = password;
  _nodeConfigMap['uid'] = getFirebaseUser().uid;

  // update firebase references
  updateNodeRef(_nodeConfigMap);

  _nodeConfigJson = json.encode(_nodeConfigMap);
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
  return dRootRef;
}

String getControlRef() {
  return dControlRef;
}

String getStatusRef() {
  return dStatusRef;
}

String getStartupRef() {
  return dStartupRef;
}

String getFcmTokenRef() {
  return dFcmTokenRef;
}

String getExecRef() {
  return dExecRef;
}

String getDataRef() {
  return dDataRef;
}

String getMessagesRef() {
  return dMessagesRef;
}

String getTHRef() {
  return dTHRef;
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
  'heap': 0,
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
