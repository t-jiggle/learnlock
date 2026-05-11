import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnlock/features/auth/providers/auth_provider.dart';
import 'package:learnlock/models/user_role.dart';
import 'package:learnlock/services/family_link_service.dart';

final userRoleProvider = FutureProvider<UserRole>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  final familyLinkService = ref.watch(familyLinkServiceProvider);

  final role = await familyLinkService.getUserRole(user);
  return role;
});
