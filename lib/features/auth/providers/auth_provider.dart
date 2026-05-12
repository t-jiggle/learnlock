import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnlock/services/firebase_service.dart';
import 'package:learnlock/services/google_sign_in_provider.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService(googleSignIn: ref.read(googleSignInProvider));
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseServiceProvider).authStateChanges;
});

final signInProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    await ref.read(firebaseServiceProvider).signInWithGoogle();
  };
});

final signOutProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    await ref.read(firebaseServiceProvider).signOut();
  };
});
