import 'package:cloud_firestore/cloud_firestore.dart';

enum SubjectType { spelling, grammar, maths, geometry }

enum LinkedAccountType { manual, familyLink }

class ChildProfile {
  final String id;
  final String name;
  final int ageYears;
  final String parentUid;
  final List<SubjectType> enabledSubjects;
  final int learningMinutesRequired;
  final int earnedScreenMinutes;
  final int currentEarnedMinutes;
  final DateTime? screenTimeExpiresAt;
  final bool isActive;
  final DateTime createdAt;
  final String? googleAccountId;
  final String? familyLinkId;
  final LinkedAccountType linkedType;
  final DateTime? lastSeenAt;
  final String? devicePlatform;

  const ChildProfile({
    required this.id,
    required this.name,
    required this.ageYears,
    required this.parentUid,
    required this.enabledSubjects,
    this.learningMinutesRequired = 5,
    this.earnedScreenMinutes = 30,
    this.currentEarnedMinutes = 0,
    this.screenTimeExpiresAt,
    this.isActive = true,
    required this.createdAt,
    this.googleAccountId,
    this.familyLinkId,
    this.linkedType = LinkedAccountType.manual,
    this.lastSeenAt,
    this.devicePlatform,
  });

  int get nswYear {
    if (ageYears <= 5) return 0;
    final year = ageYears - 5;
    return year.clamp(1, 12);
  }

  String get gradeBand {
    if (nswYear <= 2) return 'K-2';
    if (nswYear <= 4) return '3-4';
    if (nswYear <= 6) return '5-6';
    return '7+';
  }

  bool get hasScreenTimeAvailable {
    if (screenTimeExpiresAt == null) return false;
    return DateTime.now().isBefore(screenTimeExpiresAt!);
  }

  int get remainingScreenMinutes {
    if (!hasScreenTimeAvailable) return 0;
    return screenTimeExpiresAt!.difference(DateTime.now()).inMinutes;
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'ageYears': ageYears,
        'parentUid': parentUid,
        'enabledSubjects': enabledSubjects.map((s) => s.name).toList(),
        'learningMinutesRequired': learningMinutesRequired,
        'earnedScreenMinutes': earnedScreenMinutes,
        'currentEarnedMinutes': currentEarnedMinutes,
        'screenTimeExpiresAt': screenTimeExpiresAt != null
            ? Timestamp.fromDate(screenTimeExpiresAt!)
            : null,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
        'googleAccountId': googleAccountId,
        'familyLinkId': familyLinkId,
        'linkedType': linkedType.name,
        'lastSeenAt': lastSeenAt != null ? Timestamp.fromDate(lastSeenAt!) : null,
        'devicePlatform': devicePlatform,
      };

  factory ChildProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChildProfile(
      id: doc.id,
      name: data['name'] as String,
      ageYears: data['ageYears'] as int,
      parentUid: data['parentUid'] as String,
      enabledSubjects: (data['enabledSubjects'] as List<dynamic>)
          .map((s) => SubjectType.values.byName(s as String))
          .toList(),
      learningMinutesRequired: data['learningMinutesRequired'] as int? ?? 5,
      earnedScreenMinutes: data['earnedScreenMinutes'] as int? ?? 30,
      currentEarnedMinutes: data['currentEarnedMinutes'] as int? ?? 0,
      screenTimeExpiresAt:
          (data['screenTimeExpiresAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      googleAccountId: data['googleAccountId'] as String?,
      familyLinkId: data['familyLinkId'] as String?,
      linkedType: data['linkedType'] != null
          ? LinkedAccountType.values.byName(data['linkedType'] as String)
          : LinkedAccountType.manual,
      lastSeenAt: (data['lastSeenAt'] as Timestamp?)?.toDate(),
      devicePlatform: data['devicePlatform'] as String?,
    );
  }

  ChildProfile copyWith({
    String? name,
    int? ageYears,
    List<SubjectType>? enabledSubjects,
    int? learningMinutesRequired,
    int? earnedScreenMinutes,
    int? currentEarnedMinutes,
    DateTime? screenTimeExpiresAt,
    bool? isActive,
    String? googleAccountId,
    String? familyLinkId,
    LinkedAccountType? linkedType,
    bool clearScreenTime = false,
    DateTime? lastSeenAt,
    String? devicePlatform,
  }) =>
      ChildProfile(
        id: id,
        name: name ?? this.name,
        ageYears: ageYears ?? this.ageYears,
        parentUid: parentUid,
        enabledSubjects: enabledSubjects ?? this.enabledSubjects,
        learningMinutesRequired:
            learningMinutesRequired ?? this.learningMinutesRequired,
        earnedScreenMinutes: earnedScreenMinutes ?? this.earnedScreenMinutes,
        currentEarnedMinutes:
            currentEarnedMinutes ?? this.currentEarnedMinutes,
        screenTimeExpiresAt:
            clearScreenTime ? null : (screenTimeExpiresAt ?? this.screenTimeExpiresAt),
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
        googleAccountId: googleAccountId ?? this.googleAccountId,
        familyLinkId: familyLinkId ?? this.familyLinkId,
        linkedType: linkedType ?? this.linkedType,
        lastSeenAt: lastSeenAt ?? this.lastSeenAt,
        devicePlatform: devicePlatform ?? this.devicePlatform,
      );
}
