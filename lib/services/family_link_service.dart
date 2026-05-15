import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:learnlock/models/supervised_account.dart';
import 'package:learnlock/models/user_role.dart';
import 'package:learnlock/services/google_sign_in_provider.dart';

class FamilyLinkService {
  final GoogleSignIn _googleSignIn;
  final FirebaseAuth _auth;

  FamilyLinkService({
    required GoogleSignIn googleSignIn,
    FirebaseAuth? auth,
  })  : _googleSignIn = googleSignIn,
        _auth = auth ?? FirebaseAuth.instance;

  static const _familyApi =
      'https://familysharing.googleapis.com/v1/families/myFamily';

  static const _familySharingScope =
      'https://www.googleapis.com/auth/familysharing';

  /// Requests the familysharing scope incrementally (does not affect sign-in)
  /// then returns a valid access token, or null if the scope was denied or the
  /// user is not signed in.
  Future<String?> _getAccessToken() async {
    final account = _googleSignIn.currentUser;
    if (account == null) return null;

    // Request the scope incrementally; returns false if the user denies it
    // or if the scope is not configured in the Google Cloud Console.
    final granted = await _googleSignIn.requestScopes([_familySharingScope]);
    if (!granted) {
      debugPrint(
          'FamilyLinkService: familysharing scope not granted — Family Link features unavailable');
      return null;
    }

    final auth = await account.authentication;
    return auth.accessToken;
  }

  /// Fetches the raw Family Link members list once and returns it.
  Future<List<Map<String, dynamic>>> _fetchMembers(String accessToken) async {
    final response = await http
        .get(
          Uri.parse(_familyApi),
          headers: {'Authorization': 'Bearer $accessToken'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      debugPrint(
          'FamilyLinkService: API returned ${response.statusCode} — ${response.body}');
      return [];
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final members = data['members'] as List<dynamic>? ?? [];
    return members.whereType<Map<String, dynamic>>().toList();
  }

  /// Determines the user's role in a single API call.
  Future<UserRole> getUserRole(User? user) async {
    if (user == null) return UserRole.independent;

    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        debugPrint('FamilyLinkService: no access token, returning independent');
        return UserRole.independent;
      }

      final members = await _fetchMembers(accessToken);
      if (members.isEmpty) return UserRole.independent;

      final currentEmail = _auth.currentUser?.email;
      for (final m in members) {
        if (m['email'] == currentEmail) {
          final role = m['role'] as String?;
          if (role == 'PARENT') return UserRole.parent;
          if (role == 'MEMBER') return UserRole.child;
        }
      }

      return UserRole.independent;
    } catch (e) {
      debugPrint('FamilyLinkService.getUserRole error: $e');
      return UserRole.independent;
    }
  }

  /// Fetches all supervised children (MEMBER role) for the signed-in parent.
  Future<List<SupervisedAccount>> fetchSupervisedAccounts() async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        debugPrint('FamilyLinkService: no access token for fetchSupervisedAccounts');
        return [];
      }

      final members = await _fetchMembers(accessToken);
      final accounts = members
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

      debugPrint(
          'FamilyLinkService: found ${accounts.length} supervised accounts');
      return accounts;
    } catch (e) {
      debugPrint('FamilyLinkService.fetchSupervisedAccounts error: $e');
      return [];
    }
  }

  String? getCurrentUserEmail() => _auth.currentUser?.email;
}

final familyLinkServiceProvider = Provider<FamilyLinkService>((ref) {
  return FamilyLinkService(
    googleSignIn: ref.read(googleSignInProvider),
  );
});
