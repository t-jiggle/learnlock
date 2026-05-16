import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnlock/core/theme/app_theme.dart';
import 'package:learnlock/features/parent/providers/parent_provider.dart';
import 'package:learnlock/models/app_settings.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _apiKeyCtrl;
  AiProvider? _selectedProvider;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(appSettingsProvider);
    _apiKeyCtrl = TextEditingController(text: settings.aiApiKey ?? '');
    _selectedProvider = settings.aiProvider;
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAiSettings() async {
    final key = _apiKeyCtrl.text.trim();
    await ref.read(appSettingsProvider.notifier).setAiProvider(
          key.isEmpty ? AiProvider.none : (_selectedProvider ?? AiProvider.none),
          key.isEmpty ? null : key,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI settings saved!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Sound settings
          _SettingsTile(
            icon: Icons.volume_up_outlined,
            iconColor: AppColors.primary,
            title: 'Sound Effects',
            subtitle: 'Play sounds during learning sessions',
            trailing: Switch(
              value: settings.soundEnabled,
              activeColor: AppColors.primary,
              onChanged: (v) => ref
                  .read(appSettingsProvider.notifier)
                  .update(settings.copyWith(soundEnabled: v)),
            ),
          ),

          _SettingsTile(
            icon: Icons.record_voice_over_outlined,
            iconColor: AppColors.secondary,
            title: 'Read Questions Aloud',
            subtitle: 'Text-to-speech for questions (helps early readers)',
            trailing: Switch(
              value: settings.ttsEnabled,
              activeColor: AppColors.secondary,
              onChanged: (v) => ref
                  .read(appSettingsProvider.notifier)
                  .update(settings.copyWith(ttsEnabled: v)),
            ),
          ),

          const Divider(height: 32),

          // AI Provider section
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(
                      'Premium AI Content',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Get smarter, more adaptive questions powered by AI. '
                  'You must provide your own API key.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),

          // Provider selection
          Row(
            children: [
              Expanded(
                child: _ProviderCard(
                  label: 'Gemini',
                  emoji: '🤖',
                  color: const Color(0xFF4285F4),
                  selected: _selectedProvider == AiProvider.gemini,
                  onTap: () =>
                      setState(() => _selectedProvider = AiProvider.gemini),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ProviderCard(
                  label: 'Claude',
                  emoji: '🧠',
                  color: AppColors.primary,
                  selected: _selectedProvider == AiProvider.claude,
                  onTap: () =>
                      setState(() => _selectedProvider = AiProvider.claude),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ProviderCard(
                  label: 'Free',
                  emoji: '📖',
                  color: AppColors.success,
                  selected: _selectedProvider == AiProvider.none,
                  onTap: () =>
                      setState(() => _selectedProvider = AiProvider.none),
                ),
              ),
            ],
          ),

          if (_selectedProvider != AiProvider.none) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyCtrl,
              decoration: InputDecoration(
                hintText: _selectedProvider == AiProvider.gemini
                    ? 'Enter Gemini API key...'
                    : 'Enter Claude API key...',
                prefixIcon: const Icon(Icons.key_outlined),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedProvider == AiProvider.gemini
                  ? 'Get your key from Google AI Studio (free tier available)'
                  : 'Get your key from console.anthropic.com',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],

          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveAiSettings,
            child: const Text('Save AI Settings'),
          ),

          const SizedBox(height: 40),

          // About
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About LearnLock',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Content aligned to the NSW NESA K-6 syllabus. '
                  'Version 1.0.0',
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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                Text(subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        )),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ProviderCard({
    required this.label,
    required this.emoji,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
