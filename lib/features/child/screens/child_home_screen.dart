import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learnlock/core/theme/app_theme.dart';
import 'package:learnlock/features/auth/providers/auth_provider.dart';
import 'package:learnlock/features/parent/providers/parent_provider.dart';
import 'package:learnlock/models/child_profile.dart';

class ChildHomeScreen extends ConsumerWidget {
  const ChildHomeScreen({super.key});

  static const _subjectData = {
    SubjectType.spelling: (
      emoji: '📚',
      label: 'Spelling',
      color: AppColors.spellingColor,
      description: 'Learn new words!',
    ),
    SubjectType.grammar: (
      emoji: '✏️',
      label: 'Grammar',
      color: AppColors.grammarColor,
      description: 'Master sentences!',
    ),
    SubjectType.maths: (
      emoji: '🔢',
      label: 'Maths',
      color: AppColors.mathsColor,
      description: 'Numbers are fun!',
    ),
    SubjectType.geometry: (
      emoji: '📐',
      label: 'Geometry',
      color: AppColors.geometryColor,
      description: 'Shapes and space!',
    ),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the cross-collection self-profile stream so child users find their
    // profile without needing their parent's UID.
    final selfProfile = ref.watch(childSelfProfileStreamProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    return selfProfile.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (child) {
        if (child == null) {
          return _WaitingForParentScreen(
            childEmail: user?.email,
            onRefresh: () => ref.invalidate(childSelfProfileStreamProvider),
          );
        }
        return _ChildHome(child: child);
      },
    );
  }
}

class _WaitingForParentScreen extends StatelessWidget {
  final String? childEmail;
  final VoidCallback onRefresh;

  const _WaitingForParentScreen({
    required this.childEmail,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('⏳', style: TextStyle(fontSize: 72)),
                const SizedBox(height: 24),
                Text(
                  'Waiting for parent setup',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Ask your parent to open LearnLock on their phone and import your profile from Family Link.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (childEmail != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      childEmail!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your parent needs to import this account',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
                const SizedBox(height: 36),
                ElevatedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Check again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChildHome extends ConsumerWidget {
  final ChildProfile child;
  const _ChildHome({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(childProgressStreamProvider(child.id));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0EEFF), Color(0xFFFAF9FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, ${child.name}! 👋',
                          style:
                              Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          'Ready to learn something amazing?',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Streak badge
                    progress.when(
                      data: (p) => _StreakBadge(streak: p.currentStreak),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

              const SizedBox(height: 16),

              // Screen time banner
              if (child.hasScreenTimeAvailable)
                _ScreenTimeBanner(child: child)
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .slideX(begin: -0.1, end: 0),

              // "Time to learn" prompt
              if (!child.hasScreenTimeAvailable)
                _LearningPrompt(child: child)
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .scale(begin: const Offset(0.95, 0.95)),

              const SizedBox(height: 24),

              // Subject grid heading
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose a subject to start!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Subject grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: child.enabledSubjects
                        .asMap()
                        .entries
                        .map((entry) {
                      final data = ChildHomeScreen._subjectData[entry.value]!;
                      return _SubjectCard(
                        subject: entry.value,
                        emoji: data.emoji,
                        label: data.label,
                        description: data.description,
                        color: data.color,
                        delay: entry.key * 80,
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    if (streak == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.warning, Color(0xFFFF8C42)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department,
              color: Colors.white, size: 18),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreenTimeBanner extends StatelessWidget {
  final ChildProfile child;
  const _ScreenTimeBanner({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.success, Color(0xFF00B87A)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('🎮', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Screen time unlocked!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                ),
                Text(
                  '${child.remainingScreenMinutes} minutes remaining',
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LearningPrompt extends StatelessWidget {
  final ChildProfile child;
  const _LearningPrompt({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF9B8FFF)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('🚀', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learn for ${child.learningMinutesRequired} minutes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  Text(
                    'Earn ${child.earnedScreenMinutes} minutes of screen time!',
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final SubjectType subject;
  final String emoji;
  final String label;
  final String description;
  final Color color;
  final int delay;

  const _SubjectCard({
    required this.subject,
    required this.emoji,
    required this.label,
    required this.description,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/child/learn/${subject.name}'),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.go('/child/learn/${subject.name}'),
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          delay: Duration(milliseconds: delay),
          duration: 400.ms,
          curve: Curves.elasticOut,
        );
  }
}
