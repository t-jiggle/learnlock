import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learnlock/core/theme/app_theme.dart';
import 'package:learnlock/features/auth/providers/auth_provider.dart';
import 'package:learnlock/features/auth/providers/family_link_provider.dart';
import 'package:learnlock/features/parent/providers/parent_provider.dart';
import 'package:learnlock/models/child_profile.dart';
import 'package:learnlock/models/supervised_account.dart';
import 'package:uuid/uuid.dart';

class FamilyLinkImportScreen extends ConsumerStatefulWidget {
  const FamilyLinkImportScreen({super.key});

  @override
  ConsumerState<FamilyLinkImportScreen> createState() =>
      _FamilyLinkImportScreenState();
}

class _FamilyLinkImportScreenState
    extends ConsumerState<FamilyLinkImportScreen> {
  // Per-account selections & settings, keyed by email.
  final Map<String, bool> _selected = {};
  final Map<String, bool> _expanded = {};
  final Map<String, int> _learningMinutes = {};
  final Map<String, int> _earnedMinutes = {};
  final Map<String, Set<SubjectType>> _subjects = {};

  bool _importing = false;

  void _init(List<SupervisedAccount> accounts,
      List<ChildProfile> alreadyImported) {
    for (final a in accounts) {
      if (_selected.containsKey(a.email)) continue;
      final alreadyDone =
          alreadyImported.any((c) => c.googleAccountId == a.email);
      _selected[a.email] = !alreadyDone;
      _expanded[a.email] = false;
      _learningMinutes[a.email] = 5;
      _earnedMinutes[a.email] = 30;
      _subjects[a.email] = Set<SubjectType>.from(SubjectType.values);
    }
  }

  int get _selectedCount =>
      _selected.values.where((v) => v).length;

  Future<void> _import(
      List<SupervisedAccount> accounts, String parentUid) async {
    setState(() => _importing = true);

    final notifier = ref.read(childProfileNotifierProvider.notifier);
    final toImport =
        accounts.where((a) => _selected[a.email] == true).toList();

    for (final account in toImport) {
      final profile = ChildProfile(
        id: const Uuid().v4(),
        name: account.displayName,
        ageYears: account.ageYears,
        parentUid: parentUid,
        enabledSubjects: _subjects[account.email]!.toList(),
        learningMinutesRequired: _learningMinutes[account.email]!,
        earnedScreenMinutes: _earnedMinutes[account.email]!,
        googleAccountId: account.email,
        familyLinkId: account.familyLinkId,
        linkedType: LinkedAccountType.familyLink,
        createdAt: DateTime.now(),
      );
      await notifier.linkFamilyLinkAccount(
        account.email,
        account.familyLinkId,
        parentUid,
        profile,
      );
    }

    if (mounted) context.go('/parent');
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(familyLinkSupervisedProvider);
    final existingChildren = ref.watch(childProfilesProvider).valueOrNull ?? [];
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import from Family Link'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/parent'),
        ),
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(onRetry: () => ref.invalidate(familyLinkSupervisedProvider)),
        data: (accounts) {
          if (accounts.isEmpty) {
            return _NoAccountsState(
              onAddManually: () => context.go('/parent/setup'),
            );
          }
          _init(accounts, existingChildren);

          return Column(
            children: [
              _Header(accountCount: accounts.length),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  itemCount: accounts.length,
                  itemBuilder: (_, i) {
                    final account = accounts[i];
                    final alreadyImported = existingChildren
                        .any((c) => c.googleAccountId == account.email);
                    return _AccountCard(
                      account: account,
                      alreadyImported: alreadyImported,
                      selected: _selected[account.email] ?? false,
                      expanded: _expanded[account.email] ?? false,
                      learningMinutes: _learningMinutes[account.email] ?? 5,
                      earnedMinutes: _earnedMinutes[account.email] ?? 30,
                      subjects: _subjects[account.email] ??
                          Set<SubjectType>.from(SubjectType.values),
                      onToggleSelect: alreadyImported
                          ? null
                          : () => setState(() {
                                _selected[account.email] =
                                    !(_selected[account.email] ?? false);
                              }),
                      onToggleExpand: () => setState(
                          () => _expanded[account.email] =
                              !(_expanded[account.email] ?? false)),
                      onLearningMinutesChanged: (v) => setState(
                          () => _learningMinutes[account.email] = v),
                      onEarnedMinutesChanged: (v) =>
                          setState(() => _earnedMinutes[account.email] = v),
                      onSubjectToggle: (s) => setState(() {
                        final set = _subjects[account.email]!;
                        if (set.contains(s)) {
                          set.remove(s);
                        } else {
                          set.add(s);
                        }
                      }),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: accountsAsync.valueOrNull?.isNotEmpty == true
          ? _ImportBar(
              selectedCount: _selectedCount,
              importing: _importing,
              onImport: _selectedCount == 0 || user == null
                  ? null
                  : () => _import(
                      accountsAsync.value!, user.uid),
              onSkip: () => context.go('/parent/setup'),
            )
          : null,
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int accountCount;
  const _Header({required this.accountCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      color: AppColors.primary.withOpacity(0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.family_restroom,
                    color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Found $accountCount ${accountCount == 1 ? 'child' : 'children'} in Family Link',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Select the children to set up in LearnLock',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final SupervisedAccount account;
  final bool alreadyImported;
  final bool selected;
  final bool expanded;
  final int learningMinutes;
  final int earnedMinutes;
  final Set<SubjectType> subjects;
  final VoidCallback? onToggleSelect;
  final VoidCallback onToggleExpand;
  final ValueChanged<int> onLearningMinutesChanged;
  final ValueChanged<int> onEarnedMinutesChanged;
  final ValueChanged<SubjectType> onSubjectToggle;

  const _AccountCard({
    required this.account,
    required this.alreadyImported,
    required this.selected,
    required this.expanded,
    required this.learningMinutes,
    required this.earnedMinutes,
    required this.subjects,
    required this.onToggleSelect,
    required this.onToggleExpand,
    required this.onLearningMinutesChanged,
    required this.onEarnedMinutesChanged,
    required this.onSubjectToggle,
  });

  static const _avatarEmojis = ['🧒', '👦', '👧', '🧑', '🐸', '🐱', '🦊', '🐼'];

  String get _avatarEmoji {
    if (account.displayName.isEmpty) return '🧒';
    return _avatarEmojis[account.displayName.codeUnitAt(0) % _avatarEmojis.length];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Main row
          InkWell(
            onTap: alreadyImported ? null : onToggleSelect,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Checkbox or done icon
                  if (alreadyImported)
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          color: AppColors.success, size: 18),
                    )
                  else
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: Checkbox(
                        value: selected,
                        onChanged: (_) => onToggleSelect?.call(),
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                    ),

                  const SizedBox(width: 12),

                  // Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: account.photoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              account.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(_avatarEmoji,
                                    style: const TextStyle(fontSize: 26)),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(_avatarEmoji,
                                style: const TextStyle(fontSize: 26)),
                          ),
                  ),

                  const SizedBox(width: 12),

                  // Name / info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.displayName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          alreadyImported
                              ? 'Already set up'
                              : 'Age ${account.ageYears}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: alreadyImported
                                        ? AppColors.success
                                        : AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),

                  // Settings expand toggle (only for selected, non-imported)
                  if (selected && !alreadyImported)
                    IconButton(
                      icon: Icon(
                        expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.tune_outlined,
                        color: AppColors.primary,
                      ),
                      tooltip: 'Learning settings',
                      onPressed: onToggleExpand,
                    ),
                ],
              ),
            ),
          ),

          // Expandable settings panel
          if (selected && !alreadyImported && expanded)
            _SettingsPanel(
              learningMinutes: learningMinutes,
              earnedMinutes: earnedMinutes,
              subjects: subjects,
              onLearningMinutesChanged: onLearningMinutesChanged,
              onEarnedMinutesChanged: onEarnedMinutesChanged,
              onSubjectToggle: onSubjectToggle,
            ),
        ],
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  final int learningMinutes;
  final int earnedMinutes;
  final Set<SubjectType> subjects;
  final ValueChanged<int> onLearningMinutesChanged;
  final ValueChanged<int> onEarnedMinutesChanged;
  final ValueChanged<SubjectType> onSubjectToggle;

  const _SettingsPanel({
    required this.learningMinutes,
    required this.earnedMinutes,
    required this.subjects,
    required this.onLearningMinutesChanged,
    required this.onEarnedMinutesChanged,
    required this.onSubjectToggle,
  });

  static const _subjectEmojis = {
    SubjectType.spelling: '📚',
    SubjectType.grammar: '✏️',
    SubjectType.maths: '🔢',
    SubjectType.geometry: '📐',
  };

  static const _subjectColors = {
    SubjectType.spelling: AppColors.spellingColor,
    SubjectType.grammar: AppColors.grammarColor,
    SubjectType.maths: AppColors.mathsColor,
    SubjectType.geometry: AppColors.geometryColor,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 4),

          // Subjects
          Text('Subjects', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SubjectType.values.map((s) {
              final sel = subjects.contains(s);
              final color = _subjectColors[s]!;
              return GestureDetector(
                onTap: () => onSubjectToggle(s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? color : Colors.transparent,
                    border: Border.all(color: color, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_subjectEmojis[s]!,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        s.name[0].toUpperCase() + s.name.substring(1),
                        style: TextStyle(
                          color: sel ? Colors.white : color,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Learning time
          Text(
            'Learn for $learningMinutes minutes to earn screen time',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Slider(
            value: learningMinutes.toDouble(),
            min: 3,
            max: 20,
            divisions: 17,
            label: '$learningMinutes min',
            activeColor: AppColors.secondary,
            onChanged: (v) => onLearningMinutesChanged(v.round()),
          ),

          // Earned screen time
          Text(
            'Earns $earnedMinutes minutes of screen time',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Slider(
            value: earnedMinutes.toDouble(),
            min: 15,
            max: 120,
            divisions: 21,
            label: '$earnedMinutes min',
            activeColor: AppColors.success,
            onChanged: (v) => onEarnedMinutesChanged(v.round()),
          ),
        ],
      ),
    );
  }
}

class _ImportBar extends StatelessWidget {
  final int selectedCount;
  final bool importing;
  final VoidCallback? onImport;
  final VoidCallback onSkip;

  const _ImportBar({
    required this.selectedCount,
    required this.importing,
    required this.onImport,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: importing ? null : onImport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: importing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        selectedCount == 0
                            ? 'Select children to import'
                            : 'Import $selectedCount ${selectedCount == 1 ? 'child' : 'children'}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            TextButton(
              onPressed: onSkip,
              child: Text(
                'Add manually instead',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoAccountsState extends StatelessWidget {
  final VoidCallback onAddManually;
  const _NoAccountsState({required this.onAddManually});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔗', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            Text(
              'No Family Link children found',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This Google account has no supervised children in Family Link. You can still add children manually.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAddManually,
              icon: const Icon(Icons.add),
              label: const Text('Add Child Manually'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            Text(
              'Could not reach Family Link',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your internet connection and make sure Family Link is enabled for your Google account.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
