import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/audit_model.dart';

class ActivityState {
  final List<AuditEventModel> logs;
  final bool isLoading;
  final String? errorMessage;

  ActivityState({
    this.logs = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ActivityState copyWith({
    List<AuditEventModel>? logs,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ActivityState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ActivityNotifier extends StateNotifier<ActivityState> {
  final ApiClient _apiClient;

  ActivityNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(ActivityState());

  Future<void> fetchAuditLogs({String? action}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final queryParams = action != null && action != 'ALL' ? {'action': action} : null;
      final response = await _apiClient.get(
        ApiConstants.auditLogs,
        queryParameters: queryParams,
      );

      List<dynamic> list = [];
      if (response is List) {
        list = response;
      } else if (response is Map && response['results'] is List) {
        list = response['results'] as List;
      }

      final logs = list
          .map((e) => AuditEventModel.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(logs: logs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final activityProvider =
    StateNotifierProvider<ActivityNotifier, ActivityState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ActivityNotifier(apiClient: apiClient);
});
