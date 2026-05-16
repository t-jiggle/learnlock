import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learnlock/core/theme/app_theme.dart';
import 'package:learnlock/features/learning/engine/session_engine.dart';
import 'package:learnlock/features/parent/providers/parent_provider.dart';
import 'package:learnlock/models/child_profile.dart';

class LearningSessionScreen extends ConsumerWidget {
  final SubjectType subject;
  const LearningSessionScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the child's own self-profile stream (looked up by their Google email)
    // so the session screen works when the child is the signed-in user.
    final selfProfile = ref.watch(childSelfProfileStreamProvider);
    return selfProfile.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (child) {
        if (child == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('😕', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  const Text('Profile not found'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/child'),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }
        return _Session(child: child, subject: subject);
      },
    );
  }
}

class _Session extends ConsumerStatefulWidget {
  final ChildProfile child;
  final SubjectType subject;

  const _Session({required this.child, required this.subject});

  @override
  ConsumerState<_Session> createState() => _SessionState();
}

class _SessionState extends ConsumerState<_Session> {
  static const _subjectColors = {
    SubjectType.spelling: AppColors.spellingColor,
    SubjectType.grammar: AppColors.grammarColor,
    SubjectType.maths: AppColors.mathsColor,
    SubjectType.geometry: AppColors.geometryColor,
  };

  static const _subjectEmoji = {
    SubjectType.spelling: '📚',
    SubjectType.grammar: '✏️',
    SubjectType.maths: '🔢',
    SubjectType.geometry: '📐',
  };

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    final subject = widget.subject;

    // Listen fires once per state transition, not on every rebuild.
    ref.listen(sessionEngineProvider((child, subject)), (_, next) {
      if (next.phase == SessionPhase.complete && mounted) {
        context.go('/child/reward');
      }
    });

    final session = ref.watch(sessionEngineProvider((child, subject)));
    final color = _subjectColors[subject]!;
    final emoji = _subjectEmoji[subject]!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.15), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar: back + timer + progress
              _TopBar(
                session: session,
                color: color,
                emoji: emoji,
                child: child,
                subject: subject,
                onBack: () => context.go('/child'),
              ),

              const SizedBox(height: 16),

              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: switch (session.phase) {
                    SessionPhase.loading => _LoadingView(color: color),
                    SessionPhase.question => _QuestionView(
                        session: session,
                        color: color,
                        child: child,
                        subject: subject,
                      ),
                    SessionPhase.feedback => _FeedbackView(
                        session: session,
                        color: color,
                        child: child,
                        subject: subject,
                      ),
                    SessionPhase.complete => _LoadingView(color: color),
                    SessionPhase.error => _ErrorView(session: session),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  final SessionState session;
  final Color color;
  final String emoji;
  final ChildProfile child;
  final SubjectType subject;
  final VoidCallback onBack;

  const _TopBar({
    required this.session,
    required this.color,
    required this.emoji,
    required this.child,
    required this.subject,
    required this.onBack,
  });

  String _formatTime(int seconds) {
    final remaining = (child.learningMinutesRequired * 60) - seconds;
    if (remaining <= 0) return '🎉 Done!';
    final m = remaining ~/ 60;
    final s = remaining % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress =
        session.elapsedSeconds / (child.learningMinutesRequired * 60);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onBack,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$emoji ${subject.name[0].toUpperCase()}${subject.name.substring(1)}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${session.correctCount} correct · ${session.totalAnswered} answered',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              // Timer
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  _formatTime(session.elapsedSeconds),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  final Color color;
  const _LoadingView({required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: color),
          const SizedBox(height: 24),
          Text(
            'Getting your questions ready! ✨',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final SessionState session;
  const _ErrorView({required this.session});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😅', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(session.error ?? 'Something went wrong',
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/child'),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}

class _QuestionView extends ConsumerWidget {
  final SessionState session;
  final Color color;
  final ChildProfile child;
  final SubjectType subject;

  const _QuestionView({
    required this.session,
    required this.color,
    required this.child,
    required this.subject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final question = session.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Question card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Difficulty stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < question.difficulty.index + 1
                            ? Icons.star
                            : Icons.star_outline,
                        color: AppColors.starGold,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _QuestionPrompt(prompt: question.prompt),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 300.ms).scale(
                begin: const Offset(0.95, 0.95),
                curve: Curves.easeOut,
              ),

          const SizedBox(height: 24),

          // Choices
          ...question.choices.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ChoiceButton(
                label: entry.value,
                color: color,
                onTap: () => ref
                    .read(sessionEngineProvider((child, subject)).notifier)
                    .submitAnswer(entry.value),
                delay: entry.key * 60,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Renders a question prompt. If the prompt's first line is a short emoji
// (picture questions), it displays that line at 80sp and the rest at normal size.
class _QuestionPrompt extends StatelessWidget {
  final String prompt;
  const _QuestionPrompt({required this.prompt});

  @override
  Widget build(BuildContext context) {
    final lines = prompt.split('\n');
    final firstLine = lines.first;
    final isPicture = firstLine.length <= 8 && lines.length > 1;

    if (isPicture) {
      return Column(
        children: [
          Text(firstLine, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 12),
          Text(
            lines.skip(1).join('\n'),
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    return Text(
      prompt,
      style: Theme.of(context).textTheme.headlineSmall,
      textAlign: TextAlign.center,
    );
  }
}

class _ChoiceButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int delay;

  const _ChoiceButton({
    required this.label,
    required this.color,
    required this.onTap,
    required this.delay,
  });

  @override
  State<_ChoiceButton> createState() => _ChoiceButtonState();
}

class _ChoiceButtonState extends State<_ChoiceButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: widget.color.withValues(alpha: 0.4), width: 2),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
            delay: Duration(milliseconds: widget.delay), duration: 300.ms)
        .slideX(
            begin: 0.05,
            end: 0,
            delay: Duration(milliseconds: widget.delay),
            duration: 300.ms);
  }
}

class _FeedbackView extends ConsumerWidget {
  final SessionState session;
  final Color color;
  final ChildProfile child;
  final SubjectType subject;

  const _FeedbackView({
    required this.session,
    required this.color,
    required this.child,
    required this.subject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final correct = session.lastAnswerCorrect ?? false;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Big emoji feedback
          Text(
            correct ? '🌟' : '🤗',
            style: const TextStyle(fontSize: 80),
          )
              .animate()
              .scale(
                begin: const Offset(0.5, 0.5),
                duration: 400.ms,
                curve: Curves.elasticOut,
              ),

          const SizedBox(height: 24),

          // Message
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                session.feedbackMessage ?? '',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: correct ? AppColors.success : AppColors.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 32),

          // Next button
          ElevatedButton(
            onPressed: () => ref
                .read(sessionEngineProvider((child, subject)).notifier)
                .nextQuestion(),
            style: ElevatedButton.styleFrom(
              backgroundColor: correct ? AppColors.success : color,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
            ),
            child: Text(
              correct ? 'Keep going! →' : 'Try another one →',
              style: const TextStyle(fontSize: 20),
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
        ],
      ),
    );
  }
}
