import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learnlock/core/theme/app_theme.dart';
import 'package:learnlock/features/parent/providers/parent_provider.dart';

class RewardScreen extends ConsumerStatefulWidget {
  const RewardScreen({super.key});

  @override
  ConsumerState<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends ConsumerState<RewardScreen> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 5));
    WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.play());
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  static const _messages = [
    "You're a superstar learner! 🌟",
    "Incredible work today! 🚀",
    "You smashed it! Keep it up! 💪",
    "Learning hero right here! 🦸",
    "Brilliant effort! You should be so proud! 🎓",
  ];

  @override
  Widget build(BuildContext context) {
    // Use the child's own self-profile stream — activeChildProvider queries by
    // parentUid which is wrong when the signed-in user IS the child.
    final selfProfile = ref.watch(childSelfProfileStreamProvider).valueOrNull;
    final message = _messages[
        (selfProfile?.name.hashCode ?? 0).abs() % _messages.length];

    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Confetti
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.2,
            colors: const [
              AppColors.primary,
              AppColors.secondary,
              AppColors.accent,
              AppColors.success,
              AppColors.spellingColor,
              AppColors.mathsColor,
            ],
          ),

          // Main content
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFF9E6),
                  AppColors.background,
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Trophy
                      const Text(
                        '🏆',
                        style: TextStyle(fontSize: 100),
                      )
                          .animate()
                          .scale(
                            begin: const Offset(0.3, 0.3),
                            duration: 700.ms,
                            curve: Curves.elasticOut,
                          )
                          .then()
                          .shake(
                            duration: 500.ms,
                            hz: 4,
                            offset: const Offset(0, 4),
                          ),

                      const SizedBox(height: 24),

                      Text(
                        'Amazing!',
                        style:
                            Theme.of(context).textTheme.displayLarge?.copyWith(
                                  color: AppColors.primary,
                                ),
                      )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 500.ms)
                          .slideY(begin: 0.3, end: 0),

                      const SizedBox(height: 16),

                      Text(
                        message,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 600.ms, duration: 500.ms),

                      const SizedBox(height: 32),

                      // Screen time earned
                      if (selfProfile != null)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.success, Color(0xFF00B87A)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text(
                                '🎮',
                                style: TextStyle(fontSize: 40),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'You earned',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${selfProfile.earnedScreenMinutes} minutes',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'of screen time!',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 900.ms, duration: 600.ms).scale(
                              begin: const Offset(0.8, 0.8),
                              delay: 900.ms,
                              duration: 600.ms,
                              curve: Curves.elasticOut,
                            ),

                      const SizedBox(height: 40),

                      // Stars row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          5,
                          (i) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: const Icon(
                              Icons.star,
                              color: AppColors.starGold,
                              size: 36,
                            )
                                .animate(delay: Duration(milliseconds: 1000 + i * 120))
                                .scale(
                                  begin: const Offset(0.0, 0.0),
                                  duration: 400.ms,
                                  curve: Curves.elasticOut,
                                ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Done button
                      ElevatedButton(
                        onPressed: () => context.go('/child'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 48, vertical: 20),
                        ),
                        child: const Text(
                          'Let\'s Play! 🎉',
                          style: TextStyle(fontSize: 22),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 1500.ms, duration: 500.ms)
                          .slideY(begin: 0.3, end: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
