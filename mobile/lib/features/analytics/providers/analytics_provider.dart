import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/analytics_model.dart';

class AnalyticsState {
  final AnalyticsModel analytics;
  final CostModel costData;
  final bool isLoading;
  final String? errorMessage;

  AnalyticsState({
    required this.analytics,
    required this.costData,
    this.isLoading = false,
    this.errorMessage,
  });

  AnalyticsState copyWith({
    AnalyticsModel? analytics,
    CostModel? costData,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AnalyticsState(
      analytics: analytics ?? this.analytics,
      costData: costData ?? this.costData,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final ApiClient _apiClient;

  AnalyticsNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(AnalyticsState(
          analytics: AnalyticsModel(),
          costData: CostModel(),
        ));

  Future<void> fetchAnalyticsData({String? accountId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final queryParams = accountId != null ? {'account': accountId} : null;
      final analyticsResp = await _apiClient.get(
        ApiConstants.analytics,
        queryParameters: queryParams,
      );
      final costResp = await _apiClient.get(
        ApiConstants.costs,
        queryParameters: queryParams,
      );

      final analytics = AnalyticsModel.fromJson(analyticsResp);
      final costs = CostModel.fromJson(costResp);

      state = state.copyWith(
        analytics: analytics,
        costData: costs,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AnalyticsNotifier(apiClient: apiClient);
});
