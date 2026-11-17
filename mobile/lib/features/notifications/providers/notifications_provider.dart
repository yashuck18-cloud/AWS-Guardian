import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/notification_model.dart';

class NotificationsState {
  final NotificationSettingsModel settings;
  final List<NotificationHistoryModel> history;
  final bool isLoading;
  final String? errorMessage;

  NotificationsState({
    required this.settings,
    this.history = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  NotificationsState copyWith({
    NotificationSettingsModel? settings,
    List<NotificationHistoryModel>? history,
    bool? isLoading,
    String? errorMessage,
  }) {
    return NotificationsState(
      settings: settings ?? this.settings,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final ApiClient _apiClient;

  NotificationsNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(NotificationsState(settings: NotificationSettingsModel()));

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final settingsResp = await _apiClient.get(ApiConstants.notificationSettings);
      final historyResp = await _apiClient.get(ApiConstants.notificationHistory);

      final settings = NotificationSettingsModel.fromJson(settingsResp);
      List<dynamic> list = [];
      if (historyResp is List) {
        list = historyResp;
      } else if (historyResp is Map && historyResp['results'] is List) {
        list = historyResp['results'] as List;
      }
      final history = list.map((e) => NotificationHistoryModel.fromJson(e)).toList();

      state = state.copyWith(
        settings: settings,
        history: history,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> registerFCMToken(String fcmToken, {String? deviceName}) async {
    if (fcmToken.isEmpty) return false;
    try {
      String platform = 'android';
      if (kIsWeb) {
        platform = 'web';
      } else if (Platform.isIOS) {
        platform = 'ios';
      }

      final response = await _apiClient.post(
        ApiConstants.registerDevice,
        data: {
          'fcm_token': fcmToken,
          'platform': platform,
          'device_name': deviceName ?? (kIsWeb ? 'Web Browser' : (Platform.isAndroid ? 'Android Device' : 'iOS Device')),
          'app_version': '1.0.0',
        },
      );
      debugPrint('FCM Token registered with backend: ${response['success']}');
      return response['success'] == true;
    } catch (e) {
      debugPrint('Failed to register FCM token with backend: $e');
      return false;
    }
  }

  Future<bool> deactivateFCMToken(String fcmToken) async {
    if (fcmToken.isEmpty) return false;
    try {
      final response = await _apiClient.post(
        ApiConstants.deactivateDevice,
        data: {'fcm_token': fcmToken},
      );
      return response['success'] == true;
    } catch (e) {
      debugPrint('Failed to deactivate FCM token: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> testFCM() async {
    try {
      final response = await _apiClient.post(ApiConstants.testFCM);
      await fetchNotifications();
      return {
        'success': response['success'] == true,
        'message': response['message'] ?? 'Test notification triggered successfully.'
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<bool> updateSettings(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch(
        ApiConstants.notificationSettings,
        data: data,
      );
      if (response['success'] == true) {
        await fetchNotifications();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>> testTelegram(String chatId) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.testTelegram,
        data: {'chat_id': chatId},
      );
      await fetchNotifications();
      return {'success': response['success'] == true, 'message': response['message']};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<bool> triggerManualSummary() async {
    try {
      final response = await _apiClient.post(
        ApiConstants.sendSummary,
        data: {'type': 'Manual'},
      );
      await fetchNotifications();
      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationsNotifier(apiClient: apiClient);
});
