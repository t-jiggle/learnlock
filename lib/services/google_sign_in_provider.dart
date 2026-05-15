import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Single shared GoogleSignIn instance used by both FirebaseService and
// FamilyLinkService so they share the same authenticated session.
// No extra scopes here — the familysharing scope is requested incrementally
// inside FamilyLinkService only when needed, so basic sign-in is never blocked
// by a scope that may not be enabled in the Google Cloud Console.
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn();
});
