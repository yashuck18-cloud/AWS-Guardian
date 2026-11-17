class AnalyticsModel {
  final List<ServiceStat> serviceDistribution;
  final List<RegionStat> regionDistribution;
  final Map<String, int> riskDistribution;
  final List<TrendPoint> trendData;
  final int resolvedAlertsCount;
  final int totalAlertsCount;

  AnalyticsModel({
    this.serviceDistribution = const [],
    this.regionDistribution = const [],
    this.riskDistribution = const {},
    this.trendData = const [],
    this.resolvedAlertsCount = 0,
    this.totalAlertsCount = 0,
  });

  factory AnalyticsModel.fromJson(Map<String, dynamic> json) {
    final data = json['analytics'] ?? json;
    final services = (data['service_distribution'] as List<dynamic>?)
            ?.map((e) => ServiceStat.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final regions = (data['region_distribution'] as List<dynamic>?)
            ?.map((e) => RegionStat.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final risks = (data['risk_distribution'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v as int? ?? 0)) ??
        {};
    final trends = (data['trend_data'] as List<dynamic>?)
            ?.map((e) => TrendPoint.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return AnalyticsModel(
      serviceDistribution: services,
      regionDistribution: regions,
      riskDistribution: risks,
      trendData: trends,
      resolvedAlertsCount: data['resolved_alerts_count'] as int? ?? 0,
      totalAlertsCount: data['total_alerts_count'] as int? ?? 0,
    );
  }
}

class ServiceStat {
  final String service;
  final int count;
  final double totalHourly;

  ServiceStat({required this.service, required this.count, this.totalHourly = 0.0});

  factory ServiceStat.fromJson(Map<String, dynamic> json) {
    return ServiceStat(
      service: json['service']?.toString() ?? '',
      count: json['count'] as int? ?? 0,
      totalHourly: (json['total_hourly'] != null)
          ? double.tryParse(json['total_hourly'].toString()) ?? 0.0
          : 0.0,
    );
  }
}

class RegionStat {
  final String region;
  final int count;

  RegionStat({required this.region, required this.count});

  factory RegionStat.fromJson(Map<String, dynamic> json) {
    return RegionStat(
      region: json['region']?.toString() ?? '',
      count: json['count'] as int? ?? 0,
    );
  }
}

class TrendPoint {
  final String date;
  final int resources;
  final int alerts;

  TrendPoint({required this.date, required this.resources, required this.alerts});

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      date: json['date']?.toString() ?? '',
      resources: json['resources'] as int? ?? 0,
      alerts: json['alerts'] as int? ?? 0,
    );
  }
}

class CostModel {
  final bool actualBillingAvailable;
  final String actualBillingMessage;
  final double estimatedMonthlyTotal;
  final double monthToDateCost;
  final double projectedMonthlyCost;
  final double dailyRunRate;
  final String billingPeriod;
  final double estimatedMonthlyPotentialWaste;
  final Map<String, double> serviceBreakdown;
  final Map<String, double> serviceMtdBreakdown;
  final double approxInrTotal;
  final double approxInrMtd;
  final String costSourceDisplay;
  final String billingStatus;
  final bool isEstimated;

  CostModel({
    this.actualBillingAvailable = false,
    this.actualBillingMessage = '',
    this.estimatedMonthlyTotal = 0.0,
    this.monthToDateCost = 0.0,
    this.projectedMonthlyCost = 0.0,
    this.dailyRunRate = 0.0,
    this.billingPeriod = 'October 2026',
    this.estimatedMonthlyPotentialWaste = 0.0,
    this.serviceBreakdown = const {},
    this.serviceMtdBreakdown = const {},
    this.approxInrTotal = 0.0,
    this.approxInrMtd = 0.0,
    this.costSourceDisplay = 'AWS Pricing API',
    this.billingStatus = 'PRICING_ESTIMATE',
    this.isEstimated = true,
  });

  factory CostModel.fromJson(Map<String, dynamic> json) {
    final data = json['cost_data'] ?? json;
    final breakdown = (data['service_breakdown'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, double.tryParse(v.toString()) ?? 0.0)) ??
        {};
    final mtdBreakdown = (data['service_mtd_breakdown'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, double.tryParse(v.toString()) ?? 0.0)) ??
        {};

    final projTotal = (data['projected_monthly_cost'] != null)
        ? double.tryParse(data['projected_monthly_cost'].toString()) ?? 0.0
        : (data['estimated_monthly_total'] != null)
            ? double.tryParse(data['estimated_monthly_total'].toString()) ?? 0.0
            : 0.0;

    return CostModel(
      actualBillingAvailable: data['actual_billing_available'] as bool? ?? false,
      actualBillingMessage: data['actual_billing_message']?.toString() ?? '',
      estimatedMonthlyTotal: projTotal,
      monthToDateCost: double.tryParse(data['month_to_date_cost']?.toString() ?? '0') ?? 0.0,
      projectedMonthlyCost: projTotal,
      dailyRunRate: double.tryParse(data['daily_run_rate']?.toString() ?? '0') ?? 0.0,
      billingPeriod: data['billing_period']?.toString() ?? 'October 2026',
      estimatedMonthlyPotentialWaste: (data['estimated_monthly_potential_waste'] != null)
          ? double.tryParse(data['estimated_monthly_potential_waste'].toString()) ?? 0.0
          : 0.0,
      serviceBreakdown: breakdown,
      serviceMtdBreakdown: mtdBreakdown,
      approxInrTotal: double.tryParse(data['approx_inr_total']?.toString() ?? '0') ?? 0.0,
      approxInrMtd: double.tryParse(data['approx_inr_mtd']?.toString() ?? '0') ?? 0.0,
      costSourceDisplay: data['cost_source_display']?.toString() ?? 'AWS Pricing API',
      billingStatus: data['billing_status']?.toString() ?? 'PRICING_ESTIMATE',
      isEstimated: data['is_estimated'] as bool? ?? true,
    );
  }
}
