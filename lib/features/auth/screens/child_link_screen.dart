import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:learnlock/core/theme/app_theme.dart';
import 'package:learnlock/features/auth/providers/auth_provider.dart';
import 'package:learnlock/models/child_profile.dart';

enum _Step { scanning, confirming, linking }

class ChildLinkScreen extends ConsumerStatefulWidget {
  const ChildLinkScreen({super.key});

  @override
  ConsumerState<ChildLinkScreen> createState() => _ChildLinkScreenState();
}

class _ChildLinkScreenState extends ConsumerState<ChildLinkScreen> {
  final _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  _Step _step = _Step.scanning;
  ChildProfile? _profile;
  String? _error;

  static String? _parseProfileId(String raw) {
    const prefix = 'll://child/';
    if (raw.startsWith(prefix)) {
      final id = raw.substring(prefix.length);
      return id.isNotEmpty ? id : null;
    }
    return null;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_step != _Step.scanning) return;
    final raw = capture.barcodes.isNotEmpty
        ? capture.barcodes.first.rawValue
        : null;
    if (raw == null) return;

    final profileId = _parseProfileId(raw);
    if (profileId == null) return;

    await _scanner.stop();

    final firebase = ref.read(firebaseServiceProvider);
    final profile = await firebase.getChildProfileById(profileId);

    if (!mounted) return;

    if (profile == null) {
      setState(() {
        _error = 'QR code not recognised. Ask the parent to show the code again.';
        _step = _Step.scanning;
      });
      await _scanner.start();
      return;
    }

    setState(() {
      _profile = profile;
      _step = _Step.confirming;
      _error = null;
    });
  }

  Future<void> _signIn() async {
    setState(() {
      _step = _Step.linking;
      _error = null;
    });

    try {
      final firebase = ref.read(firebaseServiceProvider);
      final result = await firebase.signInWithGoogle();

      if (result == null) {
        // User cancelled the Google picker
        setState(() => _step = _Step.confirming);
        return;
      }

      final email = result.user?.email;
      if (email == null) {
        setState(() {
          _step = _Step.confirming;
          _error = 'Could not read account details. Please try again.';
        });
        return;
      }

      await firebase.linkChildAccount(_profile!.id, email);
      // Router redirect handles navigation once userRoleProvider resolves to child.
    } catch (e) {
      if (mounted) {
        setState(() {
          _step = _Step.confirming;
          _error = 'Sign in failed. Please try again.';
        });
      }
    }
  }

  void _rescan() {
    setState(() {
      _step = _Step.scanning;
      _profile = null;
      _error = null;
    });
    _scanner.start();
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Child Device Setup'),
        backgroundColor: Colors.transparent,
        foregroundColor: _step == _Step.scanning ? Colors.white : null,
        elevation: 0,
      ),
      extendBodyBehindAppBar: _step == _Step.scanning,
      body: switch (_step) {
        _Step.scanning => _ScannerView(
            scanner: _scanner,
            onDetect: _onDetect,
            error: _error,
          ),
        _Step.confirming => _ConfirmView(
            profile: _profile!,
            error: _error,
            onSignIn: _signIn,
            onRescan: _rescan,
          ),
        _Step.linking => const _LinkingView(),
      },
    );
  }
}

// ── Scanner view ─────────────────────────────────────────────────────────────

class _ScannerView extends StatelessWidget {
  final MobileScannerController scanner;
  final void Function(BarcodeCapture) onDetect;
  final String? error;

  const _ScannerView({
    required this.scanner,
    required this.onDetect,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: scanner,
          onDetect: onDetect,
          errorBuilder: (context, error, child) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_outlined, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'Camera permission required.\nPlease enable it in Settings.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Viewfinder overlay
        Center(
          child: Container(
            width: 256,
            height: 256,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        // Instruction / error text
        Positioned(
          bottom: 60,
          left: 32,
          right: 32,
          child: Column(
            children: [
              if (error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              Text(
                'Point the camera at the QR code on the parent\'s device',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Confirm view ─────────────────────────────────────────────────────────────

class _ConfirmView extends StatelessWidget {
  final ChildProfile profile;
  final String? error;
  final VoidCallback onSignIn;
  final VoidCallback onRescan;

  const _ConfirmView({
    required this.profile,
    required this.error,
    required this.onSignIn,
    required this.onRescan,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🎓', style: TextStyle(fontSize: 52)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Hi, ${profile.name}!',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in with your Google account to start learning.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              Text(
                error!,
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onSignIn,
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRescan,
              child: Text(
                'Scan a different code',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Linking in progress ───────────────────────────────────────────────────────

class _LinkingView extends StatelessWidget {
  const _LinkingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Linking account…'),
        ],
      ),
    );
  }
}
