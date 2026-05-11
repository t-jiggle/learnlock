import 'package:learnlock/models/question.dart';
import 'package:learnlock/models/child_profile.dart';
import 'package:learnlock/models/progress_record.dart';
import 'package:learnlock/features/learning/content/subjects/maths_content.dart';
import 'package:learnlock/features/learning/content/subjects/spelling_content.dart';
import 'package:learnlock/features/learning/content/subjects/grammar_content.dart';
import 'package:learnlock/features/learning/content/subjects/geometry_content.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

abstract class ContentProvider {
  Future<List<Question>> getQuestions({
    required SubjectType subject,
    required int nswYear,
    required DifficultyLevel difficulty,
    required SubjectProgress? progress,
    int count = 5,
  });
}

/// Free tier: procedurally generated questions from local content
class FreeContentProvider implements ContentProvider {
  @override
  Future<List<Question>> getQuestions({
    required SubjectType subject,
    required int nswYear,
    required DifficultyLevel difficulty,
    required SubjectProgress? progress,
    int count = 5,
  }) async {
    switch (subject) {
      case SubjectType.maths:
        return MathsContent.generate(
            nswYear: nswYear, difficulty: difficulty, count: count);
      case SubjectType.spelling:
        return SpellingContent.generate(
            nswYear: nswYear, difficulty: difficulty, count: count);
      case SubjectType.grammar:
        return GrammarContent.generate(
            nswYear: nswYear, difficulty: difficulty, count: count);
      case SubjectType.geometry:
        return GeometryContent.generate(
            nswYear: nswYear, difficulty: difficulty, count: count);
    }
  }
}

/// Premium AI tier: uses Gemini or Claude to generate adaptive questions
class AiContentProvider implements ContentProvider {
  final String apiKey;
  final bool useGemini; // true = Gemini, false = Claude

  const AiContentProvider({required this.apiKey, required this.useGemini});

  @override
  Future<List<Question>> getQuestions({
    required SubjectType subject,
    required int nswYear,
    required DifficultyLevel difficulty,
    required SubjectProgress? progress,
    int count = 5,
  }) async {
    try {
      final prompt = _buildPrompt(subject, nswYear, difficulty, progress, count);
      final raw = useGemini
          ? await _callGemini(prompt)
          : await _callClaude(prompt);
      final questions = _parseQuestions(raw, subject, difficulty, nswYear);
      if (questions.isEmpty) throw Exception('No questions parsed');
      return questions;
    } catch (e) {
      // Graceful fallback to free tier on any failure
      return FreeContentProvider().getQuestions(
        subject: subject,
        nswYear: nswYear,
        difficulty: difficulty,
        progress: progress,
        count: count,
      );
    }
  }

  String _buildPrompt(SubjectType subject, int year, DifficultyLevel difficulty,
      SubjectProgress? progress, int count) {
    final diffName = difficulty.name;
    final weakTopics = progress?.topicAttempts.entries
        .where((e) {
          final correct = progress.topicCorrect[e.key] ?? 0;
          return e.value > 0 && correct / e.value < 0.6;
        })
        .map((e) => e.key)
        .take(3)
        .join(', ') ?? '';

    return '''You are an educational content creator for Australian NSW school children.
Generate $count multiple-choice questions for:
- Subject: ${subject.name}
- NSW Year: $year (age ~${year + 5})
- Difficulty: $diffName
${weakTopics.isNotEmpty ? '- Focus on these weak areas: $weakTopics' : ''}
- Align to NSW NESA ${subject.name} curriculum

Rules:
1. Each question must be age-appropriate, friendly and encouraging
2. Return ONLY valid JSON array, no markdown or extra text
3. Questions must be clear and unambiguous
4. Correct answer must be one of the choices

Format each question exactly like:
[
  {
    "prompt": "question text here",
    "choices": ["choice1", "choice2", "choice3", "choice4"],
    "correct": "choice1",
    "explanation": "brief friendly explanation",
    "encouragement": "short encouraging hint"
  }
]''';
  }

  Future<String> _callGemini(String prompt) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [{'parts': [{'text': prompt}]}],
        'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 2048},
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) throw Exception('Gemini error: ${response.statusCode}');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['candidates'][0]['content']['parts'][0]['text'] as String;
  }

  Future<String> _callClaude(String prompt) async {
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-haiku-4-5-20251001',
        'max_tokens': 2048,
        'messages': [{'role': 'user', 'content': prompt}],
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) throw Exception('Claude error: ${response.statusCode}');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['content'][0]['text'] as String;
  }

  List<Question> _parseQuestions(
      String raw, SubjectType subject, DifficultyLevel difficulty, int year) {
    // Extract JSON array from response
    final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(raw);
    if (jsonMatch == null) return [];

    final list = jsonDecode(jsonMatch.group(0)!) as List<dynamic>;
    return list.asMap().entries.map((entry) {
      final q = entry.value as Map<String, dynamic>;
      return Question(
        id: 'ai_${subject.name}_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
        subject: subject,
        type: QuestionType.multipleChoice,
        difficulty: difficulty,
        prompt: q['prompt'] as String,
        choices: List<String>.from(q['choices'] as List),
        correctAnswer: q['correct'] as String,
        explanation: q['explanation'] as String? ?? '',
        encouragement: q['encouragement'] as String? ?? 'Great job trying!',
        nswYear: year,
      );
    }).toList();
  }
}
