import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/alert_model.dart';

class AlertsFilter {
  final String severity;
  final String status;
  final String service;
  final String? accountId;

  AlertsFilter({
    this.severity = 'ALL',
    this.status = 'ACTIVE',
    this.service = 'ALL',
    this.accountId,
  });

  AlertsFilter copyWith({
    String? severity,
    String? status,
    String? service,
    String? accountId,
  }) {
    return AlertsFilter(
      severity: severity ?? this.severity,
      status: status ?? this.status,
      service: service ?? this.service,
      accountId: accountId ?? this.accountId,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (severity != 'ALL') params['severity'] = severity;
    if (status != 'ALL') params['status'] = status;
    if (service != 'ALL') params['service'] = service;
    if (accountId != null) params['account'] = accountId;
    return params;
  }
}

class AlertsState {
  final List<AlertModel> alerts;
  final AlertsFilter filter;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;

  AlertsState({
    this.alerts = const [],
    required this.filter,
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
  });

  AlertsState copyWith({
    List<AlertModel>? alerts,
    AlertsFilter? filter,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
  }) {
    return AlertsState(
      alerts: alerts ?? this.alerts,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: errorMessage,
    );
  }
}

class AlertsNotifier extends StateNotifier<AlertsState> {
  final ApiClient _apiClient;

  AlertsNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(AlertsState(filter: AlertsFilter()));

  Future<void> fetchAlerts({bool forceReload = false}) async {
    final hasExistingData = state.alerts.isNotEmpty && !forceReload;
    if (hasExistingData) {
      state = state.copyWith(isRefreshing: true, errorMessage: null);
    } else {
      state = state.copyWith(isLoading: true, isRefreshing: false, errorMessage: null);
    }

    try {
      final response = await _apiClient.get(
        ApiConstants.alerts,
        queryParameters: state.filter.toQueryParams(),
      );

      List<dynamic> list = [];
      if (response is List) {
        list = response;
      } else if (response is Map && response['results'] is List) {
        list = response['results'] as List;
      }

      final alerts = list
          .map((e) => AlertModel.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        alerts: alerts,
        isLoading: false,
        isRefreshing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: e.toString(),
      );
    }
  }

  void setFilter(AlertsFilter filter) {
    state = state.copyWith(filter: filter);
    fetchAlerts();
  }

  void updateSeverity(String severity) {
    state = state.copyWith(filter: state.filter.copyWith(severity: severity));
    fetchAlerts();
  }

  void updateStatus(String status) {
    state = state.copyWith(filter: state.filter.copyWith(status: status));
    fetchAlerts();
  }

  Future<bool> acknowledgeAlert(String alertId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.alerts}$alertId/acknowledge/',
      );
      if (response['success'] == true) {
        await fetchAlerts();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> resolveAlert(String alertId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.alerts}$alertId/resolve/',
      );
      if (response['success'] == true) {
        state = state.copyWith(
          alerts: state.alerts.where((a) => a.id != alertId).toList(),
        );
        await fetchAlerts(forceReload: true);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final alertsProvider = StateNotifierProvider<AlertsNotifier, AlertsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AlertsNotifier(apiClient: apiClient);
});
