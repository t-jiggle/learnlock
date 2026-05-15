import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:learnlock/core/constants/app_constants.dart';

// Shared GoogleSignIn instance used across the app.
// serverClientId is the Web OAuth 2.0 client ID — required on Android so the
// SDK requests an idToken that Firebase Auth can verify.
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(serverClientId: AppConstants.googleWebClientId);
});
