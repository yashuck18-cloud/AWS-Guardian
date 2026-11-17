import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/resource_model.dart';

class ResourcesFilter {
  final String service;
  final String region;
  final String risk;
  final String state;
  final String search;
  final String? accountId;

  ResourcesFilter({
    this.service = 'ALL',
    this.region = 'all',
    this.risk = 'ALL',
    this.state = 'all',
    this.search = '',
    this.accountId,
  });

  ResourcesFilter copyWith({
    String? service,
    String? region,
    String? risk,
    String? state,
    String? search,
    String? accountId,
  }) {
    return ResourcesFilter(
      service: service ?? this.service,
      region: region ?? this.region,
      risk: risk ?? this.risk,
      state: state ?? this.state,
      search: search ?? this.search,
      accountId: accountId ?? this.accountId,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (service != 'ALL') params['service'] = service;
    if (region != 'all') params['region'] = region;
    if (risk != 'ALL') params['risk'] = risk;
    if (state != 'all') params['state'] = state;
    if (search.isNotEmpty) params['search'] = search;
    if (accountId != null) params['account'] = accountId;
    return params;
  }
}

class ResourcesState {
  final List<ResourceModel> resources;
  final ResourcesFilter filter;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;

  ResourcesState({
    this.resources = const [],
    required this.filter,
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
  });

  ResourcesState copyWith({
    List<ResourceModel>? resources,
    ResourcesFilter? filter,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
  }) {
    return ResourcesState(
      resources: resources ?? this.resources,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: errorMessage,
    );
  }
}

class ResourcesNotifier extends StateNotifier<ResourcesState> {
  final ApiClient _apiClient;
  Timer? _searchDebounceTimer;

  ResourcesNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(ResourcesState(filter: ResourcesFilter()));

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchResources({bool forceReload = false}) async {
    final hasExistingData = state.resources.isNotEmpty && !forceReload;
    if (hasExistingData) {
      state = state.copyWith(isRefreshing: true, errorMessage: null);
    } else {
      state = state.copyWith(isLoading: true, isRefreshing: false, errorMessage: null);
    }

    try {
      final response = await _apiClient.get(
        ApiConstants.resources,
        queryParameters: state.filter.toQueryParams(),
      );

      List<dynamic> list = [];
      if (response is List) {
        list = response;
      } else if (response is Map && response['results'] is List) {
        list = response['results'] as List;
      }

      final resources = list
          .map((e) => ResourceModel.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        resources: resources,
        isLoading: false,
        isRefreshing: false,
      );

      // If newly connected account is being scanned in background and returned 0 items initially,
      // schedule a quick follow-up reload to display newly populated resources automatically
      if (resources.isEmpty && state.filter.accountId != null) {
        Future.delayed(const Duration(seconds: 3), () {
          if (state.resources.isEmpty) {
            fetchResources(forceReload: true);
          }
        });
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: e.toString(),
      );
    }
  }

  void setAccount(String? accountId, {bool forceReload = false, String? region}) {
    final newRegion = region ?? (forceReload ? 'all' : state.filter.region);
    final isDifferentAccount = state.filter.accountId != accountId;
    final isDifferentRegion = region != null && state.filter.region.toLowerCase() != region.toLowerCase();

    if (isDifferentAccount || isDifferentRegion || forceReload || state.resources.isEmpty) {
      state = state.copyWith(
        resources: (forceReload || isDifferentAccount || isDifferentRegion) ? [] : state.resources,
        isLoading: true,
        filter: state.filter.copyWith(accountId: accountId, region: newRegion),
      );
      fetchResources(forceReload: true);
    }
  }

  void setFilter(ResourcesFilter filter) {
    state = state.copyWith(filter: filter);
    fetchResources();
  }

  void updateSearch(String query) {
    state = state.copyWith(filter: state.filter.copyWith(search: query));
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 350), () {
      fetchResources();
    });
  }

  void updateServiceFilter(String service) {
    state = state.copyWith(filter: state.filter.copyWith(service: service));
    fetchResources();
  }

  Future<bool> stopInstance(String resourceId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.resources}$resourceId/stop/',
        data: {'confirm': true},
      );
      if (response['success'] == true) {
        await fetchResources();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteResource(String resourceId, String typedConfirmId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.resources}$resourceId/delete/',
        data: {'confirm_resource_id': typedConfirmId},
      );
      if (response['success'] == true) {
        // Instantly remove from in-memory state
        state = state.copyWith(
          resources: state.resources.where((r) => r.id != resourceId).toList(),
        );
        await fetchResources(forceReload: true);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final resourcesProvider =
    StateNotifierProvider<ResourcesNotifier, ResourcesState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ResourcesNotifier(apiClient: apiClient);
});
