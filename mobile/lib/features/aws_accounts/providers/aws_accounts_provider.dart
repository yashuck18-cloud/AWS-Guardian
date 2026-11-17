import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_preferences.dart';
import '../../../shared/models/aws_account_model.dart';

class AWSAccountsState {
  final List<AWSAccountModel> accounts;
  final AWSAccountModel? selectedAccount;
  final bool isLoading;
  final String? errorMessage;

  AWSAccountsState({
    this.accounts = const [],
    this.selectedAccount,
    this.isLoading = false,
    this.errorMessage,
  });

  AWSAccountsState copyWith({
    List<AWSAccountModel>? accounts,
    AWSAccountModel? selectedAccount,
    bool clearSelectedAccount = false,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AWSAccountsState(
      accounts: accounts ?? this.accounts,
      selectedAccount: clearSelectedAccount ? null : (selectedAccount ?? this.selectedAccount),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AWSAccountsNotifier extends StateNotifier<AWSAccountsState> {
  final ApiClient _apiClient;
  final LocalPreferences _localPreferences;

  AWSAccountsNotifier({
    required ApiClient apiClient,
    required LocalPreferences localPreferences,
  })  : _apiClient = apiClient,
        _localPreferences = localPreferences,
        super(_initialStateFromCache(localPreferences));

  static AWSAccountsState _initialStateFromCache(LocalPreferences prefs) {
    try {
      final raw = prefs.cachedAccountsJson;
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final cached = decoded
              .map((e) => AWSAccountModel.fromJson(e as Map<String, dynamic>))
              .toList();
          if (cached.isNotEmpty) {
            return AWSAccountsState(
              accounts: cached,
              selectedAccount: cached.first,
            );
          }
        }
      }
    } catch (_) {}
    return AWSAccountsState();
  }

  Future<void> fetchAccounts() async {
    if (state.accounts.isEmpty) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }
    try {
      final response = await _apiClient.get(ApiConstants.awsAccounts);
      List<dynamic> list = [];
      if (response is List) {
        list = response;
      } else if (response is Map && response['results'] is List) {
        list = response['results'] as List;
      }

      final accounts = list
          .map((e) => AWSAccountModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (accounts.isNotEmpty) {
        AWSAccountModel? selected = state.selectedAccount;
        if (selected == null || !accounts.any((a) => a.id == selected?.id)) {
          selected = accounts.first;
        } else {
          selected = accounts.firstWhere((a) => a.id == selected?.id);
        }
        state = state.copyWith(
          accounts: accounts,
          selectedAccount: selected,
          clearSelectedAccount: false,
          isLoading: false,
        );
        // Persist to local cache so opening the app never flashes "No AWS Accounts Connected"
        try {
          final jsonList = accounts.map((a) => a.toJson()).toList();
          _localPreferences.setCachedAccountsJson(jsonEncode(jsonList));
        } catch (_) {}
      } else {
        state = state.copyWith(
          accounts: [],
          clearSelectedAccount: true,
          isLoading: false,
        );
        _localPreferences.clearCachedAccounts();
      }
    } catch (e) {
      // In case of network error, retain existing cached accounts so the user is never kicked out
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void clearCache() {
    _localPreferences.clearCachedAccounts();
    state = AWSAccountsState();
  }

  void selectAccount(AWSAccountModel? account) {
    state = state.copyWith(
      selectedAccount: account,
      clearSelectedAccount: account == null,
    );
  }

  Future<String?> generateExternalId() async {
    try {
      final response = await _apiClient.get(ApiConstants.generateExternalId);
      return response['external_id']?.toString();
    } catch (e) {
      return null;
    }
  }

  Future<bool> connectAccount({
    required String name,
    required String accountId,
    required String roleArn,
    String? externalId,
    List<String>? enabledRegions,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final payload = <String, dynamic>{
        'name': name,
        'account_id': accountId,
        'role_arn': roleArn,
        'enabled_regions': enabledRegions ?? ['all'],
      };
      if (externalId != null && externalId.isNotEmpty) {
        payload['external_id'] = externalId;
      }

      final response = await _apiClient.post(
        ApiConstants.awsAccounts,
        data: payload,
      );

      if (response != null && response['id'] != null) {
        final newAccount = AWSAccountModel.fromJson(response);
        final verifyResult = await verifyAccount(newAccount.id);
        if (verifyResult['success'] == true) {
          await fetchAccounts();
          final updated = state.accounts.firstWhere(
            (a) => a.id == newAccount.id,
            orElse: () => newAccount,
          );
          selectAccount(updated);
          return true;
        } else {
          state = state.copyWith(
            isLoading: false,
            errorMessage: verifyResult['message']?.toString() ??
                'Failed to verify IAM Role connection. Please check IAM Role trust policy.',
          );
          return false;
        }
      }
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>> verifyAccount(String accountId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.awsAccounts}$accountId/verify/',
      );
      await fetchAccounts();
      return {'success': response['success'] == true, 'message': response['message']};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<bool> deleteAccount(String accountId) async {
    try {
      await _apiClient.delete('${ApiConstants.awsAccounts}$accountId/');
      await fetchAccounts();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateAccountRegion(String accountId, String regionCode) async {
    try {
      final regions = (regionCode.toLowerCase() == 'all')
          ? ['ap-south-1', 'us-east-1', 'us-west-2', 'eu-west-1', 'ap-southeast-1']
          : [regionCode.toLowerCase()];

      final response = await _apiClient.patch(
        '${ApiConstants.awsAccounts}$accountId/',
        data: {
          'enabled_regions': regions,
        },
      );

      if (response != null) {
        await fetchAccounts();
        final updatedAccount = state.accounts.firstWhere(
          (a) => a.id == accountId,
          orElse: () => AWSAccountModel.fromJson(response),
        );
        selectAccount(updatedAccount);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final awsAccountsProvider =
    StateNotifierProvider<AWSAccountsNotifier, AWSAccountsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final localPreferences = ref.watch(localPreferencesProvider);
  return AWSAccountsNotifier(
    apiClient: apiClient,
    localPreferences: localPreferences,
  );
});
