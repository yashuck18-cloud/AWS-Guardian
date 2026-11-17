import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/providers.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/storage/local_preferences.dart';
import '../../../shared/models/user_model.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final bool isLoading;

  AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.isLoading = false,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;
  final LocalPreferences _localPreferences;
  StreamSubscription<String>? _tokenRefreshSubscription;

  AuthNotifier({
    required ApiClient apiClient,
    required SecureStorageService secureStorage,
    required LocalPreferences localPreferences,
  })  : _apiClient = apiClient,
        _secureStorage = secureStorage,
        _localPreferences = localPreferences,
        super(AuthState());

  @override
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    super.dispose();
  }

  Future<void> _syncFCMDeviceToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        String platform = 'android';
        if (kIsWeb) {
          platform = 'web';
        } else if (Platform.isIOS) {
          platform = 'ios';
        }

        await _apiClient.post(
          ApiConstants.registerDevice,
          data: {
            'fcm_token': fcmToken,
            'platform': platform,
            'device_name': kIsWeb ? 'Web Client' : (Platform.isAndroid ? 'Android Device' : 'iOS Device'),
            'app_version': '1.0.0',
          },
        );
        debugPrint('FCM Token successfully synced with backend for authenticated user.');
      }

      // Listen for future token refreshes while authenticated
      _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        debugPrint('FCM Token refreshed by Firebase. Syncing new token with backend...');
        try {
          String platform = 'android';
          if (kIsWeb) {
            platform = 'web';
          } else if (Platform.isIOS) {
            platform = 'ios';
          }

          await _apiClient.post(
            ApiConstants.registerDevice,
            data: {
              'fcm_token': newToken,
              'platform': platform,
              'device_name': kIsWeb ? 'Web Client' : (Platform.isAndroid ? 'Android Device' : 'iOS Device'),
              'app_version': '1.0.0',
            },
          );
        } catch (e) {
          debugPrint('Failed to sync refreshed FCM token: $e');
        }
      });
    } catch (e) {
      debugPrint('Error syncing FCM token with backend: $e');
    }
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    final token = await _secureStorage.getAuthToken();
    if (token == null || token.isEmpty) {
      state = state.copyWith(status: AuthStatus.unauthenticated, isLoading: false);
      return;
    }

    // Restore cached user profile first for instant offline/reopen access
    final cachedUserDataStr = await _secureStorage.getUserData();
    UserModel? cachedUser;
    if (cachedUserDataStr != null && cachedUserDataStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedUserDataStr) as Map<String, dynamic>;
        cachedUser = UserModel.fromJson(decoded);
      } catch (_) {
        // Ignore JSON parse error
      }
    }

    // Set authenticated state immediately so user is not prompted again
    state = state.copyWith(
      status: AuthStatus.authenticated,
      user: cachedUser,
      isLoading: false,
    );

    // Sync device FCM token in background
    _syncFCMDeviceToken();

    // Refresh profile in background to get updated user state
    try {
      final response = await _apiClient.get(ApiConstants.profile);
      if (response != null && response['user'] != null) {
        final freshUser = UserModel.fromJson(response['user'] as Map<String, dynamic>);
        await _secureStorage.saveUserData(jsonEncode(response['user']));
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: freshUser,
          isLoading: false,
        );
      }
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      // Only log out if the backend explicitly rejected the token (401 / expired)
      if (errStr.contains('401') || errStr.contains('unauthorized') || errStr.contains('expired')) {
        await _secureStorage.clearAll();
        state = state.copyWith(status: AuthStatus.unauthenticated, isLoading: false);
      }
      // On network timeout or connection error, KEEP authenticated state
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final cleanEmail = email.trim().toLowerCase();
      final response = await _apiClient.post(
        ApiConstants.login,
        data: {'email': cleanEmail, 'password': password},
      );

      if (response['success'] == true && response['token'] != null) {
        final token = response['token'].toString();
        await _secureStorage.saveAuthToken(token);
        await _secureStorage.saveUserEmail(cleanEmail);

        if (response['user'] != null) {
          await _secureStorage.saveUserData(jsonEncode(response['user']));
          final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            isLoading: false,
          );
        } else {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            isLoading: false,
          );
        }

        await _localPreferences.setOnboardingCompleted(true);
        // Automatically register FCM token on successful login
        _syncFCMDeviceToken();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response['message'] ?? 'Login failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final cleanEmail = email.trim().toLowerCase();
      final cleanName = name.trim();

      final response = await _apiClient.post(
        ApiConstants.register,
        data: {
          'name': cleanName,
          'email': cleanEmail,
          'password': password,
          'confirm_password': confirmPassword,
        },
      );

      if (response['success'] == true) {
        // Save the registered email so it auto-fills on the login screen
        await _secureStorage.saveUserEmail(cleanEmail);
        await _localPreferences.setOnboardingCompleted(true);

        // Do not auto-login: user must log in from the login screen
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response['message'] ?? 'Registration failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      await _apiClient.post(
        ApiConstants.forgotPassword,
        data: {'email': email.trim().toLowerCase()},
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.changePassword,
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );
      if (response['token'] != null) {
        await _secureStorage.saveAuthToken(response['token'].toString());
      }
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch(ApiConstants.profile, data: data);
      if (response['success'] == true && response['user'] != null) {
        await _secureStorage.saveUserData(jsonEncode(response['user']));
        state = state.copyWith(user: UserModel.fromJson(response['user'] as Map<String, dynamic>));
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _apiClient.post(
          ApiConstants.deactivateDevice,
          data: {'fcm_token': fcmToken},
        );
      }
    } catch (_) {
      // Ignore network errors during logout
    }
    _tokenRefreshSubscription?.cancel();
    await _secureStorage.clearAll();
    await _localPreferences.clearCachedAccounts();
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> deleteAccount() async {
    try {
      await _apiClient.delete(ApiConstants.deleteAccount);
      await logout();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final localPreferences = ref.watch(localPreferencesProvider);

  return AuthNotifier(
    apiClient: apiClient,
    secureStorage: secureStorage,
    localPreferences: localPreferences,
  );
});
