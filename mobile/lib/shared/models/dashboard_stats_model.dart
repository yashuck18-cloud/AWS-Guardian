import 'alert_model.dart';

class DashboardStatsModel {
  final int totalResources;
  final int runningResources;
  final int needsAttention;
  final int criticalCount;
  final RiskOverview riskOverview;
  final Map<String, int> resourcesByService;
  final List<AlertModel> recentAlerts;
  final int connectedAccountsCount;
  final int totalAccountsCount;
  final String? lastScanTime;
  final double combinedTotalCost;
  final double combinedApproxInr;
  final double currentCost;
  final double monthToDateCost;
  final double projectedMonthlyCost;
  final double dailyCost;
  final String billingPeriod;
  final String costCurrency;
  final String costSource;
  final String billingStatus;
  final String paymentStatus;
  final String paymentStatusLabel;
  final bool isPaid;
  final double unpaidCost;
  final double paidCost;
  final double approxInr;
  final double approxInrMtd;
  final double approxInrUnpaid;
  final Map<String, double> serviceCosts;
  final Map<String, double> serviceMtdCosts;
  final String selectedMonth;
  final String selectedMonthLabel;
  final bool isCurrentMonth;
  final List<MonthOption> availableMonths;
  final List<ResourceCostItem> resourceCosts;
  final int chargedServicesCount;
  final int chargedResourcesCount;

  DashboardStatsModel({
    this.totalResources = 0,
    this.runningResources = 0,
    this.needsAttention = 0,
    this.criticalCount = 0,
    required this.riskOverview,
    this.resourcesByService = const {},
    this.recentAlerts = const [],
    this.connectedAccountsCount = 0,
    this.totalAccountsCount = 0,
    this.lastScanTime,
    this.combinedTotalCost = 0.0,
    this.combinedApproxInr = 0.0,
    this.currentCost = 0.0,
    this.monthToDateCost = 0.0,
    this.projectedMonthlyCost = 0.0,
    this.dailyCost = 0.0,
    this.billingPeriod = '',
    this.costCurrency = 'USD',
    this.costSource = 'AWS_PRICING',
    this.billingStatus = 'PRICING_ESTIMATE',
    this.paymentStatus = 'UNPAID',
    this.paymentStatusLabel = 'Accruing (Unpaid)',
    this.isPaid = false,
    this.unpaidCost = 0.0,
    this.paidCost = 0.0,
    this.approxInr = 0.0,
    this.approxInrMtd = 0.0,
    this.approxInrUnpaid = 0.0,
    this.serviceCosts = const {},
    this.serviceMtdCosts = const {},
    this.selectedMonth = '',
    this.selectedMonthLabel = '',
    this.isCurrentMonth = true,
    this.availableMonths = const [],
    this.resourceCosts = const [],
    this.chargedServicesCount = 0,
    this.chargedResourcesCount = 0,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] ?? json;
    final riskData = stats['risk_overview'] as Map<String, dynamic>? ?? {};
    final serviceMap = (stats['resources_by_service'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v as int? ?? 0)) ??
        {};
    final alertsList = (stats['recent_alerts'] as List<dynamic>?)
            ?.map((e) => AlertModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final svcCosts = (stats['service_costs'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, double.tryParse(v.toString()) ?? 0.0)) ??
        {};
    final svcMtdCosts = (stats['service_mtd_costs'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, double.tryParse(v.toString()) ?? 0.0)) ??
        {};

    final monthsList = (stats['available_months'] as List<dynamic>?)
            ?.map((e) => MonthOption.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final resCostsList = (stats['resource_costs'] as List<dynamic>?)
            ?.map((e) => ResourceCostItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return DashboardStatsModel(
      totalResources: stats['total_resources'] as int? ?? 0,
      runningResources: stats['running_resources'] as int? ?? 0,
      needsAttention: stats['needs_attention'] as int? ?? 0,
      criticalCount: stats['critical_count'] as int? ?? 0,
      riskOverview: RiskOverview.fromJson(riskData),
      resourcesByService: serviceMap,
      recentAlerts: alertsList,
      connectedAccountsCount: stats['connected_accounts_count'] as int? ?? 0,
      totalAccountsCount: stats['total_accounts_count'] as int? ?? 0,
      lastScanTime: stats['last_scan_time']?.toString(),
      combinedTotalCost: double.tryParse(stats['combined_total_cost']?.toString() ?? '0') ?? 0.0,
      combinedApproxInr: double.tryParse(stats['combined_approx_inr']?.toString() ?? '0') ?? 0.0,
      currentCost: double.tryParse(stats['current_cost']?.toString() ?? '0') ?? 0.0,
      monthToDateCost: double.tryParse(stats['month_to_date_cost']?.toString() ?? '0') ?? 0.0,
      projectedMonthlyCost: double.tryParse(stats['projected_monthly_cost']?.toString() ?? '0') ?? 0.0,
      dailyCost: double.tryParse(stats['daily_cost']?.toString() ?? '0') ?? 0.0,
      billingPeriod: stats['billing_period']?.toString() ?? '',
      costCurrency: stats['cost_currency']?.toString() ?? 'USD',
      costSource: stats['cost_source']?.toString() ?? 'AWS_PRICING',
      billingStatus: stats['billing_status']?.toString() ?? 'PRICING_ESTIMATE',
      paymentStatus: stats['payment_status']?.toString() ?? 'UNPAID',
      paymentStatusLabel: stats['payment_status_label']?.toString() ?? 'Accruing (Unpaid)',
      isPaid: stats['is_paid'] as bool? ?? false,
      unpaidCost: double.tryParse(stats['unpaid_cost']?.toString() ?? '0') ?? 0.0,
      paidCost: double.tryParse(stats['paid_cost']?.toString() ?? '0') ?? 0.0,
      approxInr: double.tryParse(stats['approx_inr']?.toString() ?? '0') ?? 0.0,
      approxInrMtd: double.tryParse(stats['approx_inr_mtd']?.toString() ?? '0') ?? 0.0,
      approxInrUnpaid: double.tryParse(stats['approx_inr_unpaid']?.toString() ?? '0') ?? 0.0,
      serviceCosts: svcCosts,
      serviceMtdCosts: svcMtdCosts,
      selectedMonth: stats['selected_month']?.toString() ?? '',
      selectedMonthLabel: stats['selected_month_label']?.toString() ?? '',
      isCurrentMonth: stats['is_current_month'] as bool? ?? true,
      availableMonths: monthsList,
      resourceCosts: resCostsList,
      chargedServicesCount: stats['charged_services_count'] as int? ?? svcCosts.length,
      chargedResourcesCount: stats['charged_resources_count'] as int? ?? resCostsList.length,
    );
  }

  factory DashboardStatsModel.empty() {
    return DashboardStatsModel(
      riskOverview: RiskOverview(critical: 0, high: 0, medium: 0, low: 0, totalAlerts: 0),
    );
  }
}

class MonthOption {
  final String key;
  final int year;
  final int month;
  final String label;
  final bool isCurrent;

  MonthOption({
    required this.key,
    required this.year,
    required this.month,
    required this.label,
    required this.isCurrent,
  });

  factory MonthOption.fromJson(Map<String, dynamic> json) {
    return MonthOption(
      key: json['key']?.toString() ?? '',
      year: json['year'] as int? ?? 2026,
      month: json['month'] as int? ?? 11,
      label: json['label']?.toString() ?? '',
      isCurrent: json['is_current'] as bool? ?? false,
    );
  }
}

class ResourceCostItem {
  final String resourceId;
  final String name;
  final String service;
  final String region;
  final String state;
  final double hourlyCost;
  final double mtdCost;
  final double monthlyCost;

  ResourceCostItem({
    required this.resourceId,
    required this.name,
    required this.service,
    required this.region,
    required this.state,
    required this.hourlyCost,
    required this.mtdCost,
    required this.monthlyCost,
  });

  factory ResourceCostItem.fromJson(Map<String, dynamic> json) {
    return ResourceCostItem(
      resourceId: json['resource_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      service: json['service']?.toString() ?? '',
      region: json['region']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      hourlyCost: double.tryParse(json['hourly_cost']?.toString() ?? '0') ?? 0.0,
      mtdCost: double.tryParse(json['mtd_cost']?.toString() ?? '0') ?? 0.0,
      monthlyCost: double.tryParse(json['monthly_cost']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class RiskOverview {
  final int critical;
  final int high;
  final int medium;
  final int low;
  final int totalAlerts;

  RiskOverview({
    required this.critical,
    required this.high,
    required this.medium,
    required this.low,
    required this.totalAlerts,
  });

  factory RiskOverview.fromJson(Map<String, dynamic> json) {
    return RiskOverview(
      critical: json['critical'] as int? ?? 0,
      high: json['high'] as int? ?? 0,
      medium: json['medium'] as int? ?? 0,
      low: json['low'] as int? ?? 0,
      totalAlerts: json['total_alerts'] as int? ?? 0,
    );
  }
}
