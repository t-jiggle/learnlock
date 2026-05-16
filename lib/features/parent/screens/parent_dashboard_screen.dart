import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learnlock/core/theme/app_theme.dart';
import 'package:learnlock/features/auth/providers/auth_provider.dart';
import 'package:learnlock/features/parent/providers/parent_provider.dart';
import 'package:learnlock/models/child_profile.dart';
import 'package:intl/intl.dart';

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(childProfilesProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/parent/settings'),
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.security_outlined),
            onPressed: () => context.go('/parent/permissions'),
            tooltip: 'Permissions',
          ),
          IconButton(
            icon: CircleAvatar(
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              radius: 16,
              child: user?.photoURL == null
                  ? const Icon(Icons.person, size: 16)
                  : null,
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Sign Out?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sign Out')),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(firebaseServiceProvider).signOut();
              }
            },
          ),
        ],
      ),
      body: children.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) => list.isEmpty
            ? _ManualEmptyState(onAdd: () => context.go('/parent/setup'))
            : _ChildGrid(children: list),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/parent/setup'),
        icon: const Icon(Icons.add),
        label: const Text('Add Child'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _ManualEmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _ManualEmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👨‍👩‍👧‍👦', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 24),
          Text(
            'No children set up yet',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add a child profile to get started!',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Child'),
          ),
        ],
      ),
    );
  }
}

class _ChildGrid extends ConsumerWidget {
  final List<ChildProfile> children;
  const _ChildGrid({required this.children});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.82,
      ),
      itemCount: children.length,
      itemBuilder: (_, i) => _ChildCard(child: children[i]),
    );
  }
}

class _ChildCard extends ConsumerWidget {
  final ChildProfile child;
  const _ChildCard({required this.child});

  static const _avatarEmojis = ['🧒', '👦', '👧', '🧑', '🐸', '🐱', '🦊', '🐼'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(childProgressStreamProvider(child.id));
    final emojiIndex = child.name.codeUnitAt(0) % _avatarEmojis.length;

    return Card(
      child: InkWell(
        onTap: () => context.go('/parent/setup', extra: child),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _avatarEmojis[emojiIndex],
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),

              // Name
              Text(
                child.name,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Year info
              Text(
                'Year ${child.nswYear} · Age ${child.ageYears}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),

              // Device info
              _DeviceInfoRow(child: child),

              // Screen time badge + unlock button
              _ScreenTimeBadge(child: child),

              // Progress streak
              progress.when(
                data: (p) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department,
                        size: 16, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text(
                      '${p.currentStreak} day streak',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScreenTimeBadge extends ConsumerWidget {
  final ChildProfile child;
  const _ScreenTimeBadge({required this.child});

  Future<void> _unlock(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unlock screen time?'),
        content: Text(
          'This will grant ${child.name} ${child.earnedScreenMinutes} minutes '
          'of screen time now, without completing learning.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref
          .read(firebaseServiceProvider)
          .addScreenTime(child.id, child.earnedScreenMinutes);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (child.hasScreenTimeAvailable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer, size: 14, color: AppColors.success),
            const SizedBox(width: 4),
            Text(
              '${child.remainingScreenMinutes}m left',
              style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
          ],
        ),
      );
    }
    // Use Wrap so the two pills stack vertically on narrow grid cards instead
    // of overflowing horizontally.
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 14, color: AppColors.error),
              SizedBox(width: 4),
              Text(
                'Locked',
                style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => _unlock(context, ref),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_open, size: 14, color: AppColors.primary),
                SizedBox(width: 4),
                Text(
                  'Unlock',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DeviceInfoRow extends StatelessWidget {
  final ChildProfile child;
  const _DeviceInfoRow({required this.child});

  String _lastSeenText(DateTime? lastSeen) {
    if (lastSeen == null) return 'Never connected';
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 2) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('d MMM').format(lastSeen);
  }

  @override
  Widget build(BuildContext context) {
    final isLinked = child.googleAccountId != null &&
        child.googleAccountId!.isNotEmpty;
    final platform = child.devicePlatform;
    final platformLabel = platform == 'android'
        ? 'Android'
        : platform == 'ios'
            ? 'iOS'
            : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isLinked ? Icons.smartphone : Icons.phone_android_outlined,
          size: 13,
          color: isLinked
              ? AppColors.textSecondary
              : AppColors.error.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            isLinked
                ? '${platformLabel != null ? '$platformLabel · ' : ''}${_lastSeenText(child.lastSeenAt)}'
                : 'Not linked',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isLinked
                      ? AppColors.textSecondary
                      : AppColors.error.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
