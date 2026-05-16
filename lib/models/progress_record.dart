import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnlock/models/child_profile.dart';
import 'package:learnlock/models/question.dart';

class SubjectProgress {
  final SubjectType subject;
  final int totalAttempts;
  final int correctAnswers;
  final DifficultyLevel currentDifficulty;
  final double rollingAccuracy;
  final Map<String, int> topicAttempts;
  final Map<String, int> topicCorrect;
  final DateTime lastPracticed;

  const SubjectProgress({
    required this.subject,
    this.totalAttempts = 0,
    this.correctAnswers = 0,
    this.currentDifficulty = DifficultyLevel.easy,
    this.rollingAccuracy = 0.5,
    this.topicAttempts = const {},
    this.topicCorrect = const {},
    required this.lastPracticed,
  });

  double get overallAccuracy =>
      totalAttempts == 0 ? 0 : correctAnswers / totalAttempts;

  SubjectProgress withAnswer(String topic, bool correct) {
    final newAttempts = Map<String, int>.from(topicAttempts);
    final newCorrect = Map<String, int>.from(topicCorrect);
    newAttempts[topic] = (newAttempts[topic] ?? 0) + 1;
    if (correct) newCorrect[topic] = (newCorrect[topic] ?? 0) + 1;

    final newTotal = totalAttempts + 1;
    final newCorrectTotal = correctAnswers + (correct ? 1 : 0);
    // Exponential moving average for rolling accuracy (recent answers weighted more)
    final newRolling = rollingAccuracy * 0.8 + (correct ? 1.0 : 0.0) * 0.2;

    final newDifficulty = _computeDifficulty(newRolling);

    return SubjectProgress(
      subject: subject,
      totalAttempts: newTotal,
      correctAnswers: newCorrectTotal,
      currentDifficulty: newDifficulty,
      rollingAccuracy: newRolling,
      topicAttempts: newAttempts,
      topicCorrect: newCorrect,
      lastPracticed: DateTime.now(),
    );
  }

  DifficultyLevel _computeDifficulty(double accuracy) {
    // Aim for ~75% accuracy (zone of proximal development)
    if (accuracy > 0.90) return _increment(currentDifficulty);
    if (accuracy < 0.55) return _decrement(currentDifficulty);
    return currentDifficulty;
  }

  DifficultyLevel _increment(DifficultyLevel d) {
    final idx = DifficultyLevel.values.indexOf(d);
    if (idx >= DifficultyLevel.values.length - 1) return d;
    return DifficultyLevel.values[idx + 1];
  }

  DifficultyLevel _decrement(DifficultyLevel d) {
    final idx = DifficultyLevel.values.indexOf(d);
    if (idx <= 0) return d;
    return DifficultyLevel.values[idx - 1];
  }

  Map<String, dynamic> toMap() => {
        'subject': subject.name,
        'totalAttempts': totalAttempts,
        'correctAnswers': correctAnswers,
        'currentDifficulty': currentDifficulty.name,
        'rollingAccuracy': rollingAccuracy,
        'topicAttempts': topicAttempts,
        'topicCorrect': topicCorrect,
        'lastPracticed': Timestamp.fromDate(lastPracticed),
      };

  factory SubjectProgress.fromMap(Map<String, dynamic> map) => SubjectProgress(
        subject: SubjectType.values.byName(map['subject'] as String),
        totalAttempts: map['totalAttempts'] as int? ?? 0,
        correctAnswers: map['correctAnswers'] as int? ?? 0,
        currentDifficulty: DifficultyLevel.values
            .byName(map['currentDifficulty'] as String? ?? 'easy'),
        rollingAccuracy: (map['rollingAccuracy'] as num?)?.toDouble() ?? 0.5,
        topicAttempts: Map<String, int>.from(
            (map['topicAttempts'] as Map<String, dynamic>? ?? {})
                .map((k, v) => MapEntry(k, v as int))),
        topicCorrect: Map<String, int>.from(
            (map['topicCorrect'] as Map<String, dynamic>? ?? {})
                .map((k, v) => MapEntry(k, v as int))),
        lastPracticed:
            (map['lastPracticed'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  factory SubjectProgress.initial(SubjectType subject) => SubjectProgress(
        subject: subject,
        lastPracticed: DateTime.now(),
      );
}

class ProgressRecord {
  final String childId;
  final Map<SubjectType, SubjectProgress> subjects;
  final int totalSessionsCompleted;
  final int totalMinutesLearned;
  final int currentStreak;
  final DateTime? lastSessionDate;

  const ProgressRecord({
    required this.childId,
    required this.subjects,
    this.totalSessionsCompleted = 0,
    this.totalMinutesLearned = 0,
    this.currentStreak = 0,
    this.lastSessionDate,
  });

  SubjectProgress progressFor(SubjectType subject) =>
      subjects[subject] ?? SubjectProgress.initial(subject);

  ProgressRecord withAnswer(SubjectType subject, String topic, bool correct) {
    final updated = Map<SubjectType, SubjectProgress>.from(subjects);
    updated[subject] = progressFor(subject).withAnswer(topic, correct);
    return ProgressRecord(
      childId: childId,
      subjects: updated,
      totalSessionsCompleted: totalSessionsCompleted,
      totalMinutesLearned: totalMinutesLearned,
      currentStreak: currentStreak,
      lastSessionDate: lastSessionDate,
    );
  }

  ProgressRecord withCompletedSession(int durationMinutes) {
    final today = DateTime.now();
    final lastDate = lastSessionDate;
    int newStreak = currentStreak;
    if (lastDate != null) {
      // Compare calendar dates (year/month/day), not raw 24-hour duration.
      // Using inDays on a Duration would report 0 for e.g. 11 PM → midnight,
      // failing to increment the streak on back-to-back calendar days.
      final todayDate = DateTime(today.year, today.month, today.day);
      final lastDateOnly = DateTime(lastDate.year, lastDate.month, lastDate.day);
      final daysDiff = todayDate.difference(lastDateOnly).inDays;
      if (daysDiff == 1) {
        newStreak++;
      } else if (daysDiff > 1) {
        newStreak = 1;
      }
      // daysDiff == 0 means same calendar day — keep streak unchanged.
    } else {
      newStreak = 1;
    }
    return ProgressRecord(
      childId: childId,
      subjects: subjects,
      totalSessionsCompleted: totalSessionsCompleted + 1,
      totalMinutesLearned: totalMinutesLearned + durationMinutes,
      currentStreak: newStreak,
      lastSessionDate: today,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'childId': childId,
        'subjects': subjects.map((k, v) => MapEntry(k.name, v.toMap())),
        'totalSessionsCompleted': totalSessionsCompleted,
        'totalMinutesLearned': totalMinutesLearned,
        'currentStreak': currentStreak,
        'lastSessionDate': lastSessionDate != null
            ? Timestamp.fromDate(lastSessionDate!)
            : null,
      };

  factory ProgressRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final subjectsRaw = data['subjects'] as Map<String, dynamic>? ?? {};
    return ProgressRecord(
      childId: data['childId'] as String,
      subjects: subjectsRaw.map((k, v) => MapEntry(
            SubjectType.values.byName(k),
            SubjectProgress.fromMap(v as Map<String, dynamic>),
          )),
      totalSessionsCompleted: data['totalSessionsCompleted'] as int? ?? 0,
      totalMinutesLearned: data['totalMinutesLearned'] as int? ?? 0,
      currentStreak: data['currentStreak'] as int? ?? 0,
      lastSessionDate: (data['lastSessionDate'] as Timestamp?)?.toDate(),
    );
  }

  factory ProgressRecord.initial(String childId) => ProgressRecord(
        childId: childId,
        subjects: {},
      );
}
