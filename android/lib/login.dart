import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart' show rootBundle;

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = new GoogleSignIn();

Future<Map> configFirefase() async {
  final String fbConfig = await rootBundle.loadString('android/app/google-services.json');
  Map parsedMap = JSON.decode(fbConfig);
  return parsedMap;
}

Future<String> signInAnonymously() async {
  final FirebaseUser user = await _auth.signInAnonymously();
  assert(user != null);
  assert(user.isAnonymous);
  assert(!user.isEmailVerified);
  assert(await user.getToken() != null);
  if (Platform.isIOS) {
    // Anonymous _auth doesn't show up as a provider on iOS
    assert(user.providerData.isEmpty);
  } else if (Platform.isAndroid) {
    // Anonymous _auth does show up as a provider on Android
    assert(user.providerData.length == 1);
    assert(user.providerData[0].providerId == 'firebase');
    assert(user.providerData[0].uid != null);
    assert(user.providerData[0].displayName == null);
    assert(user.providerData[0].photoUrl == null);
    assert(user.providerData[0].email == null);
  }

  final FirebaseUser currentUser = await _auth.currentUser();
  assert(user.uid == currentUser.uid);

  print('user $user');
  return 'signInAnonymously succeeded: $user';
}

Future<String> signInWithEmailAndPassword() async {
  final FirebaseUser user = await _auth.signInWithEmailAndPassword(
      email: 'xxxxxxxxx.yyyyyyyyy@gmail.com',
      password: '********'
  );

  final FirebaseUser currentUser = await _auth.currentUser();
  assert(user.uid == currentUser.uid);

  print('user $user');
  return 'signInWithEmailAndPassword succeeded: $user';
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
  assert(await user.getToken() != null);

  final FirebaseUser currentUser = await _auth.currentUser();
  assert(user.uid == currentUser.uid);

  print('user $user');
  return 'signInWithGoogle succeeded: $user';
}
