import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:learnlock/core/constants/app_constants.dart';

// Single shared GoogleSignIn instance used by both FirebaseService and
// FamilyLinkService so they share the same authenticated session.
// serverClientId is the Web OAuth 2.0 client ID — required on Android so the
// SDK requests an idToken that Firebase Auth can verify.
// No extra scopes here — the familysharing scope is requested incrementally
// inside FamilyLinkService only when needed.
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(serverClientId: AppConstants.googleWebClientId);
});
