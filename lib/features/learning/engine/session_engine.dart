import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnlock/features/learning/content/content_provider.dart';
import 'package:learnlock/features/parent/providers/parent_provider.dart';
import 'package:learnlock/models/app_settings.dart';
import 'package:learnlock/models/child_profile.dart';
import 'package:learnlock/models/progress_record.dart';
import 'package:learnlock/models/question.dart';
import 'package:learnlock/features/auth/providers/auth_provider.dart';
import 'dart:async';

enum SessionPhase { loading, question, feedback, complete, error }

class SessionState {
  final SessionPhase phase;
  final List<Question> questions;
  final int currentIndex;
  final List<QuestionResult> results;
  final String? feedbackMessage;
  final bool? lastAnswerCorrect;
  final int elapsedSeconds;
  final String? error;

  const SessionState({
    this.phase = SessionPhase.loading,
    this.questions = const [],
    this.currentIndex = 0,
    this.results = const [],
    this.feedbackMessage,
    this.lastAnswerCorrect,
    this.elapsedSeconds = 0,
    this.error,
  });

  Question? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  int get correctCount => results.where((r) => r.correct).length;
  int get totalAnswered => results.length;
  double get accuracy => totalAnswered == 0 ? 0 : correctCount / totalAnswered;

  bool get isComplete =>
      phase == SessionPhase.complete ||
      (questions.isNotEmpty && currentIndex >= questions.length);

  SessionState copyWith({
    SessionPhase? phase,
    List<Question>? questions,
    int? currentIndex,
    List<QuestionResult>? results,
    String? feedbackMessage,
    bool? lastAnswerCorrect,
    int? elapsedSeconds,
    String? error,
    bool clearFeedback = false,
  }) =>
      SessionState(
        phase: phase ?? this.phase,
        questions: questions ?? this.questions,
        currentIndex: currentIndex ?? this.currentIndex,
        results: results ?? this.results,
        feedbackMessage: clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
        lastAnswerCorrect:
            clearFeedback ? null : (lastAnswerCorrect ?? this.lastAnswerCorrect),
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        error: error ?? this.error,
      );
}

class SessionEngine extends StateNotifier<SessionState> {
  final Ref _ref;
  final ChildProfile _child;
  final SubjectType _subject;
  ContentProvider? _provider;
  ProgressRecord? _progress;
  Timer? _timer;
  int _questionStartTime = 0;

  SessionEngine(this._ref, this._child, this._subject)
      : super(const SessionState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final settings = _ref.read(appSettingsProvider);
      _provider = settings.hasPremiumAi
          ? AiContentProvider(
              apiKey: settings.aiApiKey!,
              useGemini: settings.aiProvider == AiProvider.gemini,
            )
          : FreeContentProvider();

      _progress = await _ref.read(firebaseServiceProvider).getProgress(_child.id);
      await _loadQuestions();
      _startTimer();
    } catch (e) {
      state = state.copyWith(
          phase: SessionPhase.error, error: 'Could not load questions: $e');
    }
  }

  Future<void> _loadQuestions() async {
    final subjectProgress = _progress?.progressFor(_subject);
    final difficulty = subjectProgress?.currentDifficulty ?? DifficultyLevel.easy;

    final questions = await _provider!.getQuestions(
      subject: _subject,
      nswYear: _child.nswYear,
      difficulty: difficulty,
      progress: subjectProgress,
      count: 8,
    );

    _questionStartTime = DateTime.now().millisecondsSinceEpoch;
    state = state.copyWith(
      phase: SessionPhase.question,
      questions: questions,
      currentIndex: 0,
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      // End session after required learning time
      if (state.elapsedSeconds >=
          _child.learningMinutesRequired * 60) {
        _completeSession();
      }
    });
  }

  void submitAnswer(String answer) {
    final question = state.currentQuestion;
    if (question == null || state.phase != SessionPhase.question) return;

    final timeSpent =
        (DateTime.now().millisecondsSinceEpoch - _questionStartTime) ~/ 1000;
    final correct = question.checkAnswer(answer);

    final result = QuestionResult(
      question: question,
      givenAnswer: answer,
      correct: correct,
      timeSpentSeconds: timeSpent,
      answeredAt: DateTime.now(),
    );

    // Update progress in memory
    _progress = _progress?.withAnswer(_subject, question.subject.name, correct);

    final feedback = _buildFeedback(correct, question);

    state = state.copyWith(
      phase: SessionPhase.feedback,
      results: [...state.results, result],
      feedbackMessage: feedback,
      lastAnswerCorrect: correct,
    );
  }

  String _buildFeedback(bool correct, Question question) {
    if (correct) {
      const messages = [
        "Fantastic! You got it! 🌟",
        "Brilliant work! Keep it up! ⭐",
        "Yes! You're amazing! 🎉",
        "Correct! You're so clever! 🚀",
        "Woohoo! Great job! 🎊",
      ];
      return messages[DateTime.now().millisecond % messages.length];
    } else {
      return '${question.explanation}\n\n💡 ${question.encouragement}';
    }
  }

  void nextQuestion() {
    final nextIndex = state.currentIndex + 1;
    _questionStartTime = DateTime.now().millisecondsSinceEpoch;

    if (nextIndex >= state.questions.length) {
      // Load more questions to keep session going until timer expires
      state = state.copyWith(
        currentIndex: nextIndex,
        clearFeedback: true,
      );
      _loadMoreQuestions();
    } else {
      state = state.copyWith(
        phase: SessionPhase.question,
        currentIndex: nextIndex,
        clearFeedback: true,
      );
    }
  }

  Future<void> _loadMoreQuestions() async {
    final subjectProgress = _progress?.progressFor(_subject);
    final difficulty = subjectProgress?.currentDifficulty ?? DifficultyLevel.easy;
    final moreQuestions = await _provider!.getQuestions(
      subject: _subject,
      nswYear: _child.nswYear,
      difficulty: difficulty,
      progress: subjectProgress,
      count: 8,
    );
    _questionStartTime = DateTime.now().millisecondsSinceEpoch;
    state = state.copyWith(
      phase: SessionPhase.question,
      questions: [...state.questions, ...moreQuestions],
      clearFeedback: true,
    );
  }

  Future<void> _completeSession() async {
    _timer?.cancel();
    state = state.copyWith(phase: SessionPhase.complete);

    // Persist progress and award screen time
    if (_progress != null) {
      final updated = _progress!.withCompletedSession(
          _child.learningMinutesRequired);
      await _ref.read(firebaseServiceProvider).saveProgress(updated);
    }

    await _ref
        .read(firebaseServiceProvider)
        .addScreenTime(_child.id, _child.earnedScreenMinutes);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final sessionEngineProvider = StateNotifierProvider.autoDispose
    .family<SessionEngine, SessionState, (ChildProfile, SubjectType)>(
  (ref, args) => SessionEngine(ref, args.$1, args.$2),
);
