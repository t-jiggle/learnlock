enum AiProvider { none, gemini, claude }

class AppSettings {
  final AiProvider aiProvider;
  final String? aiApiKey;
  final bool soundEnabled;
  final bool ttsEnabled;
  final bool parentPinEnabled;
  final String? parentPin;
  final String activeChildId;

  const AppSettings({
    this.aiProvider = AiProvider.none,
    this.aiApiKey,
    this.soundEnabled = true,
    this.ttsEnabled = true,
    this.parentPinEnabled = false,
    this.parentPin,
    this.activeChildId = '',
  });

  bool get hasPremiumAi => aiProvider != AiProvider.none && aiApiKey != null;

  AppSettings copyWith({
    AiProvider? aiProvider,
    String? aiApiKey,
    bool? soundEnabled,
    bool? ttsEnabled,
    bool? parentPinEnabled,
    String? parentPin,
    String? activeChildId,
  }) =>
      AppSettings(
        aiProvider: aiProvider ?? this.aiProvider,
        aiApiKey: aiApiKey ?? this.aiApiKey,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        ttsEnabled: ttsEnabled ?? this.ttsEnabled,
        parentPinEnabled: parentPinEnabled ?? this.parentPinEnabled,
        parentPin: parentPin ?? this.parentPin,
        activeChildId: activeChildId ?? this.activeChildId,
      );

  Map<String, dynamic> toJson() => {
        'aiProvider': aiProvider.name,
        'aiApiKey': aiApiKey,
        'soundEnabled': soundEnabled,
        'ttsEnabled': ttsEnabled,
        'parentPinEnabled': parentPinEnabled,
        'parentPin': parentPin,
        'activeChildId': activeChildId,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        aiProvider: AiProvider.values
            .byName(json['aiProvider'] as String? ?? 'none'),
        aiApiKey: json['aiApiKey'] as String?,
        soundEnabled: json['soundEnabled'] as bool? ?? true,
        ttsEnabled: json['ttsEnabled'] as bool? ?? true,
        parentPinEnabled: json['parentPinEnabled'] as bool? ?? false,
        parentPin: json['parentPin'] as String?,
        activeChildId: json['activeChildId'] as String? ?? '',
      );
}
