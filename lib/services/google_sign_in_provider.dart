import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Single shared GoogleSignIn instance used by both FirebaseService and
// FamilyLinkService so they share the same authenticated session.
// The familysharing scope is required for the Family Link API.
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/familysharing'],
  );
});
