import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learnlock/core/theme/app_theme.dart';
import 'package:learnlock/features/app_control/services/screen_time_service.dart';
import 'package:learnlock/features/auth/providers/auth_provider.dart';
import 'package:learnlock/features/parent/providers/parent_provider.dart';
import 'package:learnlock/models/child_profile.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

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
                  'Ask your parent to open LearnLock on their phone and link your profile.',
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
                    'Your parent needs to link this account',
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

// ---------------------------------------------------------------------------
// Main child home — handles both locked and unlocked states
// ---------------------------------------------------------------------------

class _ChildHome extends ConsumerStatefulWidget {
  final ChildProfile child;
  const _ChildHome({required this.child});

  @override
  ConsumerState<_ChildHome> createState() => _ChildHomeState();
}

class _ChildHomeState extends ConsumerState<_ChildHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startNativeMonitor(widget.child);
      _reportDeviceInfo(widget.child.id);
    });
  }

  @override
  void didUpdateWidget(_ChildHome old) {
    super.didUpdateWidget(old);
    // Profile stream emitted a new value — keep native monitor in sync.
    final prev = old.child;
    final next = widget.child;
    if (prev.hasScreenTimeAvailable != next.hasScreenTimeAvailable ||
        prev.screenTimeExpiresAt != next.screenTimeExpiresAt) {
      ScreenTimeService.updateScreenTime(
        hasScreenTime: next.hasScreenTimeAvailable,
        expiresAt: next.screenTimeExpiresAt,
      ).catchError((_) {});
    }
  }

  void _startNativeMonitor(ChildProfile child) {
    ScreenTimeService.startMonitor(
      childId: child.id,
      hasScreenTime: child.hasScreenTimeAvailable,
      expiresAt: child.screenTimeExpiresAt,
    ).catchError((_) {
      // Permissions not granted yet — monitor won't run until granted from
      // the parent permissions screen, which is a valid state.
    });
  }

  void _reportDeviceInfo(String childId) {
    final platform = Platform.isAndroid
        ? 'android'
        : Platform.isIOS
            ? 'ios'
            : 'other';
    ref
        .read(firebaseServiceProvider)
        .updateDeviceInfo(childId, platform)
        .catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    final isLocked = !child.hasScreenTimeAvailable;

    if (isLocked) return _LockedView(child: child);
    return _UnlockedView(child: child);
  }
}

// ---------------------------------------------------------------------------
// LOCKED view — full screen, PopScope blocks back button
// ---------------------------------------------------------------------------

class _LockedView extends ConsumerWidget {
  final ChildProfile child;
  const _LockedView({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(childProgressStreamProvider(child.id));

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A0533), Color(0xFF2D0B55)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi, ${child.name}!',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(color: Colors.white),
                          ),
                          const Text(
                            'Complete your learning to unlock',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                      const Spacer(),
                      progress.when(
                        data: (p) => _StreakBadge(streak: p.currentStreak),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 20),

                // ── Learning time ring ───────────────────────────────────
                CircularPercentIndicator(
                  radius: 72.0,
                  lineWidth: 10.0,
                  percent: 0.0,
                  animation: true,
                  animationDuration: 600,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  progressColor: const Color(0xFFFF6B6B),
                  circularStrokeCap: CircularStrokeCap.round,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🔒', style: TextStyle(fontSize: 22)),
                      Text(
                        '${child.learningMinutesRequired}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'min',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 150.ms).scale(
                      begin: const Offset(0.8, 0.8),
                      curve: Curves.elasticOut,
                    ),

                const SizedBox(height: 10),

                Text(
                  'minutes of learning required',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ).animate().fadeIn(delay: 250.ms),

                const SizedBox(height: 4),

                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '🎮  Earn ${child.earnedScreenMinutes} minutes of screen time!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 20),

                // ── Subject grid heading ─────────────────────────────────
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Pick a subject to start learning:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 350.ms),

                const SizedBox(height: 10),

                // ── Subject grid ─────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _SubjectGrid(child: child),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// UNLOCKED view — normal home screen
// ---------------------------------------------------------------------------

class _UnlockedView extends ConsumerWidget {
  final ChildProfile child;
  const _UnlockedView({required this.child});

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
                          style: Theme.of(context).textTheme.headlineMedium,
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
                    progress.when(
                      data: (p) => _StreakBadge(streak: p.currentStreak),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

              const SizedBox(height: 16),

              _ScreenTimeBanner(child: child)
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .slideX(begin: -0.1, end: 0),

              const SizedBox(height: 24),

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

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _SubjectGrid(child: child),
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

// ---------------------------------------------------------------------------
// Shared subject grid
// ---------------------------------------------------------------------------

class _SubjectGrid extends StatelessWidget {
  final ChildProfile child;
  const _SubjectGrid({required this.child});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: child.enabledSubjects.asMap().entries.map((entry) {
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
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

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
            color: AppColors.warning.withValues(alpha: 0.4),
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
              color: AppColors.success.withValues(alpha: 0.4),
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
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
