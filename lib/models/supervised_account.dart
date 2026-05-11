import 'package:cloud_firestore/cloud_firestore.dart';

class SupervisedAccount {
  final String email;
  final String familyLinkId;
  final String displayName;
  final String? photoUrl;
  final int ageYears;
  final DateTime createdAt;

  SupervisedAccount({
    required this.email,
    required this.familyLinkId,
    required this.displayName,
    this.photoUrl,
    required this.ageYears,
    required this.createdAt,
  });

  factory SupervisedAccount.fromFamilyLinkApi(Map<String, dynamic> json) {
    return SupervisedAccount(
      email: json['email'] as String? ?? '',
      familyLinkId: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Unknown',
      photoUrl: json['photoUrl'] as String?,
      ageYears: json['ageYears'] as int? ?? 5,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'familyLinkId': familyLinkId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'ageYears': ageYears,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  String toString() => 'SupervisedAccount($displayName, $email)';
}
