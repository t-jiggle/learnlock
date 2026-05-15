import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnlock/features/auth/providers/auth_provider.dart';
import 'package:learnlock/models/user_role.dart';

// Determines role from Firestore: if a child profile exists for this Google
// account the user is a child, otherwise a parent.
final userRoleProvider = StreamProvider<UserRole>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(UserRole.independent);

  final email = user.email;
  if (email == null) return Stream.value(UserRole.parent);

  final firebaseService = ref.read(firebaseServiceProvider);
  return firebaseService
      .watchChildByGoogleAccountId(email)
      .map((child) => child != null ? UserRole.child : UserRole.parent);
});
