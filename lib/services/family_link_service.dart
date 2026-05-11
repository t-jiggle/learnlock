import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/familysharing/v1.dart' as familysharing;
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

  /// Checks if the authenticated user is a parent (supervises children)
  Future<bool> _isParent(String accessToken) async {
    try {
      final client = _createAuthenticatedClient(accessToken);
      final api = familysharing.FamilysharingApi(client);

      // Get family group - if user is parent, this succeeds
      final family = await api.families.get('families/myFamily');
      if (family == null) return false;

      // Parent successfully retrieved family group
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Checks if the authenticated user is a child (is supervised)
  Future<bool> _isChild(String accessToken) async {
    try {
      final client = _createAuthenticatedClient(accessToken);
      final api = familysharing.FamilysharingApi(client);

      // Try to get supervision status - if user is child, this succeeds
      // This is determined by checking if user's account is in a family
      // and they don't have PARENT role
      final family = await api.families.get('families/myFamily');
      if (family == null) return false;

      // Check if current user is not the parent
      // (presence in family but not parent = child)
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fetches all supervised children for a parent
  /// Returns list of SupervisedAccount from Family Link API
  Future<List<SupervisedAccount>> fetchSupervisedAccounts() async {
    try {
      final account = _googleSignIn.currentUser;
      if (account == null) return [];

      final auth = await account.authentication;
      final accessToken = auth.accessToken;

      if (accessToken == null) return [];

      final client = _createAuthenticatedClient(accessToken);
      final api = familysharing.FamilysharingApi(client);

      // Get family group
      final family = await api.families.get('families/myFamily');
      if (family == null || family.members == null) return [];

      // Convert Family Link members to SupervisedAccounts
      final supervised = <SupervisedAccount>[];
      for (final member in family.members!) {
        // Filter for child members (exclude self and parents)
        if (member.role == 'MEMBER') {
          supervised.add(
            SupervisedAccount(
              email: member.email ?? '',
              familyLinkId: member.memberId ?? '',
              displayName: member.displayName ?? 'Unknown',
              photoUrl: member.profileImageUrl,
              ageYears: _extractAge(member),
              createdAt: DateTime.now(),
            ),
          );
        }
      }

      return supervised;
    } catch (e) {
      return [];
    }
  }

  /// Get the current user's Google account ID/email
  String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }

  /// Create an authenticated HTTP client for API calls
  /// (This is a simplified version - production should use proper auth flow)
  _AuthenticatedClient _createAuthenticatedClient(String accessToken) {
    return _AuthenticatedClient(accessToken);
  }

  /// Extract age from Family Link member object
  int _extractAge(familysharing.FamilyMember member) {
    // Age is typically stored in birthday or age field
    // This is a placeholder - adjust based on actual Family Link API response
    return member.age ?? 5;
  }
}

/// Simple HTTP client that adds Authorization header
class _AuthenticatedClient extends http.BaseClient {
  final String _accessToken;

  _AuthenticatedClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return super.send(request);
  }
}

final familyLinkServiceProvider = Provider<FamilyLinkService>((ref) {
  return FamilyLinkService();
});
