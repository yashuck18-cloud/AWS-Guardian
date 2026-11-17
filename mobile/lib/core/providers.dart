import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage/secure_storage_service.dart';
import 'storage/local_preferences.dart';
import 'network/api_client.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize sharedPreferences in main()');
});

final localPreferencesProvider = Provider<LocalPreferences>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalPreferences(prefs);
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final localPreferences = ref.watch(localPreferencesProvider);
  return ApiClient(
    secureStorage: secureStorage,
    localPreferences: localPreferences,
  );
});
