import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learnlock/core/theme/app_theme.dart';
import 'package:learnlock/features/auth/providers/auth_provider.dart';
import 'package:learnlock/features/parent/providers/parent_provider.dart';
import 'package:learnlock/models/child_profile.dart';
import 'package:uuid/uuid.dart';

class ChildSetupScreen extends ConsumerStatefulWidget {
  final ChildProfile? existing;
  const ChildSetupScreen({super.key, this.existing});

  @override
  ConsumerState<ChildSetupScreen> createState() => _ChildSetupScreenState();
}

class _ChildSetupScreenState extends ConsumerState<ChildSetupScreen> {
  late final TextEditingController _nameCtrl;
  late int _age;
  late int _learningMinutes;
  late int _earnedMinutes;
  late Set<SubjectType> _enabledSubjects;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _age = e?.ageYears ?? 7;
    _learningMinutes = e?.learningMinutesRequired ?? 5;
    _earnedMinutes = e?.earnedScreenMinutes ?? 30;
    _enabledSubjects = e != null
        ? Set<SubjectType>.from(e.enabledSubjects)
        : Set<SubjectType>.from(SubjectType.values);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  int get _nswYear => (_age - 5).clamp(0, 12);

  String get _gradeBand {
    if (_nswYear <= 2) return 'K-2';
    if (_nswYear <= 4) return '3-4';
    if (_nswYear <= 6) return '5-6';
    return 'Year 7+';
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }
    if (_enabledSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable at least one subject')),
      );
      return;
    }

    setState(() => _saving = true);
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      setState(() => _saving = false);
      return;
    }

    final profile = widget.existing?.copyWith(
          name: _nameCtrl.text.trim(),
          ageYears: _age,
          enabledSubjects: _enabledSubjects.toList(),
          learningMinutesRequired: _learningMinutes,
          earnedScreenMinutes: _earnedMinutes,
        ) ??
        ChildProfile(
          id: const Uuid().v4(),
          name: _nameCtrl.text.trim(),
          ageYears: _age,
          parentUid: user.uid,
          enabledSubjects: _enabledSubjects.toList(),
          learningMinutesRequired: _learningMinutes,
          earnedScreenMinutes: _earnedMinutes,
          createdAt: DateTime.now(),
        );

    final notifier = ref.read(childProfileNotifierProvider.notifier);
    if (_isEditing) {
      await notifier.updateChild(profile);
      if (mounted) context.go('/parent');
    } else {
      await notifier.createChild(profile);
      if (mounted) context.go('/parent/child-qr', extra: profile);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Remove ${widget.existing!.name}?'),
        content: const Text('This will delete all learning progress. Are you sure?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    await ref
        .read(childProfileNotifierProvider.notifier)
        .deleteChild(widget.existing!.id);
    if (mounted) context.go('/parent');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Child' : 'Add Child'),
        actions: _isEditing
            ? [
                IconButton(
                  icon: const Icon(Icons.qr_code_outlined),
                  tooltip: 'Show QR Code',
                  onPressed: () => context.go('/parent/child-qr', extra: widget.existing),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: _delete,
                ),
              ]
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Name
          _Section(
            title: 'Child\'s Name',
            child: TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                hintText: 'Enter name...',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ),

          // Age
          _Section(
            title: 'Age · $_age years old (NSW $_gradeBand)',
            child: Slider(
              value: _age.toDouble(),
              min: 5,
              max: 14,
              divisions: 9,
              label: '$_age years',
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _age = v.round()),
            ),
          ),

          // Subjects
          _Section(
            title: 'Learning Subjects',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: SubjectType.values.map((s) {
                final selected = _enabledSubjects.contains(s);
                return _SubjectChip(
                  subject: s,
                  selected: selected,
                  onToggle: () => setState(() {
                    if (selected) {
                      _enabledSubjects.remove(s);
                    } else {
                      _enabledSubjects.add(s);
                    }
                  }),
                );
              }).toList(),
            ),
          ),

          // Learning time
          _Section(
            title: 'Learning time required: $_learningMinutes minutes',
            child: Slider(
              value: _learningMinutes.toDouble(),
              min: 3,
              max: 20,
              divisions: 17,
              label: '$_learningMinutes min',
              activeColor: AppColors.secondary,
              onChanged: (v) => setState(() => _learningMinutes = v.round()),
            ),
          ),

          // Earned screen time
          _Section(
            title: 'Earned screen time: $_earnedMinutes minutes',
            child: Slider(
              value: _earnedMinutes.toDouble(),
              min: 15,
              max: 120,
              divisions: 21,
              label: '$_earnedMinutes min',
              activeColor: AppColors.success,
              onChanged: (v) => setState(() => _earnedMinutes = v.round()),
            ),
          ),

          // Summary chip
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('📋', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$_learningMinutes minutes of learning earns $_earnedMinutes minutes of screen time',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(_isEditing ? 'Save Changes' : 'Add Child'),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  final SubjectType subject;
  final bool selected;
  final VoidCallback onToggle;

  const _SubjectChip({
    required this.subject,
    required this.selected,
    required this.onToggle,
  });

  static const _emojis = {
    SubjectType.spelling: '📚',
    SubjectType.grammar: '✏️',
    SubjectType.maths: '🔢',
    SubjectType.geometry: '📐',
  };

  static const _colors = {
    SubjectType.spelling: AppColors.spellingColor,
    SubjectType.grammar: AppColors.grammarColor,
    SubjectType.maths: AppColors.mathsColor,
    SubjectType.geometry: AppColors.geometryColor,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[subject]!;
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_emojis[subject]!, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              subject.name[0].toUpperCase() + subject.name.substring(1),
              style: TextStyle(
                color: selected ? Colors.white : color,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
