import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth.dart';

// this provider will be overridden. See ProviderScope(overrides: […]) in main.dart
final sharedPreferencesProvider =
    Provider<SharedPreferences>((ref) => throw UnimplementedError());

final pocketBaseProvider = Provider<PocketBase>(
  (_) => PocketBase('http://localhost:8090'),
);

final authStoreProvider = Provider<AuthStore>((ref) {
  return ref.watch(pocketBaseProvider).authStore;
});

final authStoreChangesProvider = StreamProvider<AuthStoreEvent>((ref) {
  return ref.watch(authStoreProvider).onChange;
});

/// Provides the logged in users id
final userIdProvider = Provider<String>((ref) {
  return ref.read(authProvider.notifier).authStore.model.id;
});

final userServiceProvider = Provider<RecordService>((ref) {
  return ref.watch(pocketBaseProvider).collection("users");
});
