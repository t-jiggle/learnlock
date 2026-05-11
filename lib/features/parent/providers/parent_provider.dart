import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnlock/features/auth/providers/auth_provider.dart';
import 'package:learnlock/models/app_settings.dart';
import 'package:learnlock/models/child_profile.dart';
import 'package:learnlock/models/progress_record.dart';
import 'package:learnlock/services/firebase_service.dart';
import 'package:learnlock/services/storage_service.dart';

final storageServiceProvider = FutureProvider<StorageService>((ref) async {
  return StorageService.create();
});

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier(ref);
});

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final Ref _ref;

  AppSettingsNotifier(this._ref) : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final storage = await _ref.read(storageServiceProvider.future);
    state = storage.loadSettings();
  }

  Future<void> update(AppSettings updated) async {
    state = updated;
    final storage = await _ref.read(storageServiceProvider.future);
    await storage.saveSettings(updated);
  }

  Future<void> setActiveChild(String childId) async {
    await update(state.copyWith(activeChildId: childId));
  }

  Future<void> setAiProvider(AiProvider provider, String? apiKey) async {
    await update(state.copyWith(aiProvider: provider, aiApiKey: apiKey));
  }
}

final childProfilesProvider =
    StreamProvider<List<ChildProfile>>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      return ref.read(firebaseServiceProvider).watchChildProfiles(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

final activeChildProvider = Provider<AsyncValue<ChildProfile?>>((ref) {
  final settings = ref.watch(appSettingsProvider);
  final auth = ref.watch(authStateProvider);
  final children = ref.watch(childProfilesProvider);

  return children.when(
    data: (list) {
      // If activeChildId is set, find and return that child
      if (settings.activeChildId.isNotEmpty) {
        final match = list.where((c) => c.id == settings.activeChildId);
        if (match.isNotEmpty) {
          return AsyncData(match.first);
        }
      }

      // For children, try to find their profile by their Google account ID
      final user = auth.valueOrNull;
      if (user != null) {
        try {
          final childProfile = list
              .where((c) => c.googleAccountId == user.email)
              .first;
          return AsyncData(childProfile);
        } catch (e) {
          // No matching profile found
        }
      }

      return const AsyncData(null);
    },
    loading: () => const AsyncLoading(),
    error: (e, s) => AsyncError(e, s),
  );
});

final childProgressProvider =
    FutureProvider.family<ProgressRecord, String>((ref, childId) async {
  return ref.read(firebaseServiceProvider).getProgress(childId);
});

final childProgressStreamProvider =
    StreamProvider.family<ProgressRecord, String>((ref, childId) {
  return ref.read(firebaseServiceProvider).watchProgress(childId);
});

class ChildProfileNotifier extends StateNotifier<AsyncValue<void>> {
  final FirebaseService _firebase;

  ChildProfileNotifier(this._firebase)
      : super(const AsyncData(null));

  Future<void> createChild(ChildProfile profile) async {
    state = const AsyncLoading();
    try {
      await _firebase.createChild(profile);
      state = const AsyncData(null);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> updateChild(ChildProfile profile) async {
    state = const AsyncLoading();
    try {
      await _firebase.updateChild(profile);
      state = const AsyncData(null);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> deleteChild(String childId) async {
    state = const AsyncLoading();
    try {
      await _firebase.deleteChild(childId);
      state = const AsyncData(null);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> addScreenTime(String childId, int minutes) =>
      _firebase.addScreenTime(childId, minutes);

  Future<void> linkFamilyLinkAccount(
    String childGoogleAccountId,
    String childFamilyLinkId,
    String parentUid,
    ChildProfile baseProfile,
  ) async {
    state = const AsyncLoading();
    try {
      await _firebase.linkSupervizedAccount(
        childGoogleAccountId,
        childFamilyLinkId,
        parentUid,
        baseProfile,
      );
      state = const AsyncData(null);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }
}

final childProfileNotifierProvider =
    StateNotifierProvider<ChildProfileNotifier, AsyncValue<void>>((ref) {
  return ChildProfileNotifier(ref.read(firebaseServiceProvider));
});

final childProfileByGoogleIdProvider =
    FutureProvider.family<ChildProfile?, String>((ref, googleAccountId) async {
  return ref.read(firebaseServiceProvider).getChildByGoogleAccountId(googleAccountId);
});
