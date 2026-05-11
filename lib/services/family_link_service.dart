import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:learnlock/models/supervised_account.dart';
import 'package:learnlock/models/user_role.dart';

class FamilyLinkService {
  final GoogleSignIn _googleSignIn;
  final FirebaseAuth _auth;

  FamilyLinkService({
    GoogleSignIn? googleSignIn,
    FirebaseAuth? auth,
  })  : _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _auth = auth ?? FirebaseAuth.instance;

  /// Determines the user's role: parent, child, or independent
  /// Requires Family Link API enabled in Google Cloud Project
  Future<UserRole> getUserRole(User? user) async {
    if (user == null) return UserRole.independent;

    try {
      final account = _googleSignIn.currentUser;
      if (account == null) return UserRole.independent;

      final auth = await account.authentication;
      final accessToken = auth.accessToken;

      if (accessToken == null) return UserRole.independent;

      // Query Family Link API to check supervision status
      final isParent = await _isParent(accessToken);
      if (isParent) return UserRole.parent;

      final isChild = await _isChild(accessToken);
      if (isChild) return UserRole.child;

      return UserRole.independent;
    } catch (e) {
      // If API calls fail, default to independent
      // (user might not have Family Link set up)
      return UserRole.independent;
    }
  }

  static const _familyApi =
      'https://familysharing.googleapis.com/v1/families/myFamily';

  /// Checks if the authenticated user is a parent (supervises children)
  Future<bool> _isParent(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse(_familyApi),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (response.statusCode != 200) return false;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      // User is parent if they have the PARENT role in the family
      final members = data['members'] as List<dynamic>? ?? [];
      final currentEmail = getCurrentUserEmail();
      return members.any((m) =>
          m is Map && m['role'] == 'PARENT' && m['email'] == currentEmail);
    } catch (e) {
      return false;
    }
  }

  /// Checks if the authenticated user is a child (is supervised)
  Future<bool> _isChild(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse(_familyApi),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (response.statusCode != 200) return false;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final members = data['members'] as List<dynamic>? ?? [];
      final currentEmail = getCurrentUserEmail();
      // Child is in the family with MEMBER role (not PARENT)
      return members.any((m) =>
          m is Map && m['role'] == 'MEMBER' && m['email'] == currentEmail);
    } catch (e) {
      return false;
    }
  }

  /// Fetches all supervised children for a parent
  Future<List<SupervisedAccount>> fetchSupervisedAccounts() async {
    try {
      final account = _googleSignIn.currentUser;
      if (account == null) return [];

      final auth = await account.authentication;
      final accessToken = auth.accessToken;
      if (accessToken == null) return [];

      final response = await http.get(
        Uri.parse(_familyApi),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final members = data['members'] as List<dynamic>? ?? [];

      return members
          .whereType<Map<String, dynamic>>()
          .where((m) => m['role'] == 'MEMBER')
          .map((m) => SupervisedAccount(
                email: m['email'] as String? ?? '',
                familyLinkId: m['memberId'] as String? ?? '',
                displayName: m['displayName'] as String? ?? 'Unknown',
                photoUrl: m['profileImageUrl'] as String?,
                ageYears: m['age'] as int? ?? 5,
                createdAt: DateTime.now(),
              ))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get the current user's Google account ID/email
  String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }

}

final familyLinkServiceProvider = Provider<FamilyLinkService>((ref) {
  return FamilyLinkService();
});
