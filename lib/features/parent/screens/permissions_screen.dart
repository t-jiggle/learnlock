import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnlock/core/theme/app_theme.dart';
import 'package:learnlock/features/app_control/services/screen_time_service.dart';

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen>
    with WidgetsBindingObserver {
  bool _usageStatsGranted = false;
  bool _overlayGranted = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _checking = true);
    final perms = await ScreenTimeService.checkAllPermissions();
    setState(() {
      _usageStatsGranted = perms['usageStats'] ?? false;
      _overlayGranted = perms['overlay'] ?? false;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allGranted = _usageStatsGranted && _overlayGranted;

    return Scaffold(
      appBar: AppBar(title: const Text('App Permissions')),
      body: _checking
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Status banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: allGranted
                        ? AppColors.success.withOpacity(0.12)
                        : AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: allGranted ? AppColors.success : AppColors.warning,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        allGranted ? '✅' : '⚠️',
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          allGranted
                              ? 'All permissions granted! LearnLock can protect screen time.'
                              : 'Some permissions are needed for LearnLock to work properly.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _PermissionCard(
                  icon: Icons.bar_chart_outlined,
                  color: AppColors.primary,
                  title: 'Usage Access',
                  description:
                      'Allows LearnLock to see which apps your child is using, so it can show the learning screen when needed.',
                  granted: _usageStatsGranted,
                  onRequest: () async {
                    await ScreenTimeService.requestUsageStatsPermission();
                    await _checkPermissions();
                  },
                ),

                const SizedBox(height: 16),

                _PermissionCard(
                  icon: Icons.picture_in_picture_alt,
                  color: AppColors.secondary,
                  title: 'Display Over Other Apps',
                  description:
                      'Allows LearnLock to show the learning screen on top of other apps when screen time has expired.',
                  granted: _overlayGranted,
                  onRequest: () async {
                    await ScreenTimeService.requestOverlayPermission();
                    await _checkPermissions();
                  },
                ),

                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Privacy Note',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        'LearnLock only uses these permissions to enforce '
                        'learning time on this device. App usage data is never '
                        'sent to external servers.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final bool granted;
  final VoidCallback onRequest;

  const _PermissionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.granted,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                Icon(
                  granted ? Icons.check_circle : Icons.cancel,
                  color: granted ? AppColors.success : AppColors.error,
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (!granted) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                  ),
                  child: const Text('Grant Permission'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
