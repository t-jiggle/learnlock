import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:learnlock/core/theme/app_theme.dart';
import 'package:learnlock/features/auth/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      final result = await ref.read(firebaseServiceProvider).signInWithGoogle();
      // null means the user dismissed the account picker — not an error.
      if (result == null && mounted) {
        setState(() => _loading = false);
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.secondary,
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
                  // Logo / mascot
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🎓', style: TextStyle(fontSize: 60)),
                    ),
                  )
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 32),

                  Text(
                    'LearnLock',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 42,
                        ),
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 500.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 8),

                  Text(
                    'Learn first, play later!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 500.ms),

                  const SizedBox(height: 64),

                  // Google Sign-In button
                  _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : _GoogleSignInButton(onTap: _signIn)
                          .animate()
                          .fadeIn(delay: 600.ms, duration: 500.ms)
                          .slideY(begin: 0.4, end: 0),

                  const SizedBox(height: 24),

                  Text(
                    'Parents & Children sign in with their Google account',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 800.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleSignInButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Google G logo (simplified coloured squares)
            SizedBox(
              width: 24,
              height: 24,
              child: CustomPaint(painter: _GoogleLogoPainter()),
            ),
            const SizedBox(width: 16),
            Text(
              'Continue with Google',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final r = size.width / 2;

    // Draw a simple coloured G — 4 quadrant dots
    final colors = [
      const Color(0xFF4285F4),
      const Color(0xFF34A853),
      const Color(0xFFFBBC05),
      const Color(0xFFEA4335),
    ];
    final offsets = [
      Offset(r * 0.4, r * 0.4),
      Offset(r * 1.6, r * 0.4),
      Offset(r * 1.6, r * 1.6),
      Offset(r * 0.4, r * 1.6),
    ];
    for (int i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawCircle(offsets[i], r * 0.45, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
