import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/dashboard_stats_model.dart';
import '../../../shared/models/scan_model.dart';

class DashboardState {
  final DashboardStatsModel stats;
  final List<ScanModel> scanHistory;
  final bool isLoading;
  final bool isScanning;
  final String? errorMessage;
  final ScanModel? latestScanResult;

  DashboardState({
    required this.stats,
    this.scanHistory = const [],
    this.isLoading = false,
    this.isScanning = false,
    this.errorMessage,
    this.latestScanResult,
  });

  DashboardState copyWith({
    DashboardStatsModel? stats,
    List<ScanModel>? scanHistory,
    bool? isLoading,
    bool? isScanning,
    String? errorMessage,
    ScanModel? latestScanResult,
  }) {
    return DashboardState(
      stats: stats ?? this.stats,
      scanHistory: scanHistory ?? this.scanHistory,
      isLoading: isLoading ?? this.isLoading,
      isScanning: isScanning ?? this.isScanning,
      errorMessage: errorMessage,
      latestScanResult: latestScanResult ?? this.latestScanResult,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final ApiClient _apiClient;

  DashboardNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(DashboardState(stats: DashboardStatsModel.empty()));

  Future<void> fetchDashboardStats({String? accountId, String? region, String? month}) async {
    // Only show full skeleton loader if we have no existing cached stats
    if (state.stats.totalResources == 0 && state.scanHistory.isEmpty) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }
    try {
      final queryParams = <String, dynamic>{};
      if (accountId != null) queryParams['account'] = accountId;
      if (region != null && region.toLowerCase() != 'all') {
        queryParams['region'] = region.toLowerCase();
      }
      if (month != null && month.isNotEmpty) {
        queryParams['month'] = month;
      }
      final response = await _apiClient.get(
        ApiConstants.dashboard,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final stats = DashboardStatsModel.fromJson(response);
      state = state.copyWith(stats: stats, isLoading: false);
      await fetchScanHistory(accountId: accountId);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> fetchScanHistory({String? accountId}) async {
    try {
      final queryParams = accountId != null ? {'account': accountId} : null;
      final response = await _apiClient.get(
        ApiConstants.scanHistory,
        queryParameters: queryParams,
      );
      List<dynamic> list = [];
      if (response is List) {
        list = response;
      } else if (response is Map && response['results'] is List) {
        list = response['results'] as List;
      }
      final history = list.map((e) => ScanModel.fromJson(e)).toList();
      state = state.copyWith(scanHistory: history);
    } catch (_) {}
  }

  Future<ScanModel?> triggerScan({String? accountId}) async {
    state = state.copyWith(isScanning: true, errorMessage: null);
    try {
      final payload = <String, dynamic>{'sync': true};
      if (accountId != null) {
        payload['account_id'] = accountId;
      }

      final response = await _apiClient.post(
        ApiConstants.triggerScan,
        data: payload,
      );

      ScanModel? scanResult;
      if (response['scans'] != null && (response['scans'] as List).isNotEmpty) {
        scanResult = ScanModel.fromJson(response['scans'][0]);
      }

      await fetchDashboardStats(accountId: accountId);
      state = state.copyWith(
        isScanning: false,
        latestScanResult: scanResult,
      );
      return scanResult;
    } catch (e) {
      state = state.copyWith(isScanning: false, errorMessage: e.toString());
      return null;
    }
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardNotifier(apiClient: apiClient);
});
