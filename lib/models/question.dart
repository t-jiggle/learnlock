import 'package:learnlock/models/child_profile.dart';

enum QuestionType { multipleChoice, fillBlank, trueFalse, ordering }
enum DifficultyLevel { veryEasy, easy, medium, hard, veryHard }

class Question {
  final String id;
  final SubjectType subject;
  final QuestionType type;
  final DifficultyLevel difficulty;
  final String prompt;
  final String? imageAsset;
  final List<String> choices;
  final String correctAnswer;
  final String explanation;
  final String encouragement;
  final int nswYear;

  const Question({
    required this.id,
    required this.subject,
    required this.type,
    required this.difficulty,
    required this.prompt,
    this.imageAsset,
    this.choices = const [],
    required this.correctAnswer,
    required this.explanation,
    required this.encouragement,
    required this.nswYear,
  });

  bool checkAnswer(String answer) =>
      answer.trim().toLowerCase() == correctAnswer.trim().toLowerCase();
}

class QuestionResult {
  final Question question;
  final String givenAnswer;
  final bool correct;
  final int timeSpentSeconds;
  final DateTime answeredAt;

  const QuestionResult({
    required this.question,
    required this.givenAnswer,
    required this.correct,
    required this.timeSpentSeconds,
    required this.answeredAt,
  });
}
