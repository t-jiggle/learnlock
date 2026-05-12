import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learnlock/core/theme/app_theme.dart';
import 'package:learnlock/features/auth/providers/auth_provider.dart';
import 'package:learnlock/features/auth/providers/family_link_provider.dart';
import 'package:learnlock/features/parent/providers/parent_provider.dart';
import 'package:learnlock/models/child_profile.dart';

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
          // Sync from Family Link
          IconButton(
            icon: const Icon(Icons.family_restroom_outlined),
            onPressed: () => context.go('/parent/family-link-import'),
            tooltip: 'Sync from Family Link',
          ),
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
            ? _SmartEmptyState(onAddManually: () => context.go('/parent/setup'))
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

/// Shows a Family Link import CTA when supervised accounts are available,
/// or falls back to a plain "Add manually" empty state.
class _SmartEmptyState extends ConsumerWidget {
  final VoidCallback onAddManually;
  const _SmartEmptyState({required this.onAddManually});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyLinkAccounts = ref.watch(familyLinkSupervisedProvider);

    return familyLinkAccounts.when(
      loading: () => _ManualEmptyState(onAdd: onAddManually),
      error: (_, __) => _ManualEmptyState(onAdd: onAddManually),
      data: (accounts) => accounts.isNotEmpty
          ? _FamilyLinkEmptyState(
              accountCount: accounts.length,
              onImport: () => context.go('/parent/family-link-import'),
              onManual: onAddManually,
            )
          : _ManualEmptyState(onAdd: onAddManually),
    );
  }
}

class _FamilyLinkEmptyState extends StatelessWidget {
  final int accountCount;
  final VoidCallback onImport;
  final VoidCallback onManual;

  const _FamilyLinkEmptyState({
    required this.accountCount,
    required this.onImport,
    required this.onManual,
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.family_restroom,
                  size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'Family Link children found!',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We found $accountCount ${accountCount == 1 ? 'child' : 'children'} in your Family Link account. Import them to get started quickly.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onImport,
                icon: const Icon(Icons.family_restroom),
                label: Text(
                    'Import $accountCount ${accountCount == 1 ? 'child' : 'children'} from Family Link'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onManual,
              child: Text(
                'Add child manually instead',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
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
              // Avatar with optional Family Link badge
              Stack(
                clipBehavior: Clip.none,
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
                  if (child.linkedType == LinkedAccountType.familyLink)
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.link,
                            size: 12, color: Colors.white),
                      ),
                    ),
                ],
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

              // Screen time badge
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

class _ScreenTimeBadge extends StatelessWidget {
  final ChildProfile child;
  const _ScreenTimeBadge({required this.child});

  @override
  Widget build(BuildContext context) {
    if (child.hasScreenTimeAvailable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.15),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.12),
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
    );
  }
}
