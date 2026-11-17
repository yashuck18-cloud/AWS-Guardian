class ResourceCostModel {
  final String id;
  final String resourceId;
  final String service;
  final String region;
  final String resourceType;
  final double actualCost;
  final double estimatedCost;
  final double monthToDateCost;
  final double projectedMonthlyCost;
  final double dailyCost;
  final String currency;
  final double pricingRate;
  final String pricingUnit;
  final double usageQuantity;
  final String usageUnit;
  final String costSource;
  final String costSourceDisplay;
  final String billingStatus;
  final String billingStatusDisplay;
  final double approxInr;
  final String notes;
  final String? lastUpdated;

  ResourceCostModel({
    this.id = '',
    this.resourceId = '',
    this.service = '',
    this.region = '',
    this.resourceType = '',
    this.actualCost = 0.0,
    this.estimatedCost = 0.0,
    this.monthToDateCost = 0.0,
    this.projectedMonthlyCost = 0.0,
    this.dailyCost = 0.0,
    this.currency = 'USD',
    this.pricingRate = 0.0,
    this.pricingUnit = 'Hrs',
    this.usageQuantity = 0.0,
    this.usageUnit = 'Hrs',
    this.costSource = 'AWS_PRICING',
    this.costSourceDisplay = 'AWS Pricing API',
    this.billingStatus = 'PRICING_ESTIMATE',
    this.billingStatusDisplay = 'Pricing-Based Estimate',
    this.approxInr = 0.0,
    this.notes = '',
    this.lastUpdated,
  });

  bool get isActual => billingStatus == 'ACTUAL';
  bool get isEstimated => billingStatus == 'ESTIMATED';
  bool get isPricingEstimate => billingStatus == 'PRICING_ESTIMATE';
  bool get isCostUnavailable => billingStatus == 'UNAVAILABLE';

  factory ResourceCostModel.fromJson(Map<String, dynamic> json) {
    final act = double.tryParse(json['actual_cost']?.toString() ?? '0') ?? 0.0;
    final est = double.tryParse(json['estimated_cost']?.toString() ?? '0') ?? 0.0;
    final rate = double.tryParse(json['pricing_rate']?.toString() ?? '0') ?? 0.0;

    final mtd = json['month_to_date_cost'] != null
        ? double.tryParse(json['month_to_date_cost'].toString()) ?? act
        : act;
    final proj = json['projected_monthly_cost'] != null
        ? double.tryParse(json['projected_monthly_cost'].toString()) ?? est
        : est;
    final daily = json['daily_cost'] != null
        ? double.tryParse(json['daily_cost'].toString()) ?? (rate * 24.0)
        : (rate * 24.0);

    return ResourceCostModel(
      id: json['id']?.toString() ?? '',
      resourceId: json['resource_id']?.toString() ?? '',
      service: json['service']?.toString() ?? '',
      region: json['region']?.toString() ?? '',
      resourceType: json['resource_type']?.toString() ?? '',
      actualCost: act,
      estimatedCost: est,
      monthToDateCost: mtd,
      projectedMonthlyCost: proj,
      dailyCost: daily,
      currency: json['currency']?.toString() ?? 'USD',
      pricingRate: rate,
      pricingUnit: json['pricing_unit']?.toString() ?? 'Hrs',
      usageQuantity: double.tryParse(json['usage_quantity']?.toString() ?? '0') ?? 0.0,
      usageUnit: json['usage_unit']?.toString() ?? 'Hrs',
      costSource: json['cost_source']?.toString() ?? 'AWS_PRICING',
      costSourceDisplay: json['cost_source_display']?.toString() ?? 'AWS Pricing API',
      billingStatus: json['billing_status']?.toString() ?? 'PRICING_ESTIMATE',
      billingStatusDisplay: json['billing_status_display']?.toString() ?? 'Pricing-Based Estimate',
      approxInr: double.tryParse(json['approx_inr']?.toString() ?? '0') ?? 0.0,
      notes: json['notes']?.toString() ?? '',
      lastUpdated: json['last_updated']?.toString(),
    );
  }
}

class ResourceModel {
  final String id;
  final String? accountId;
  final String accountName;
  final String accountNumber;
  final String service;
  final String serviceDisplay;
  final String resourceId;
  final String name;
  final String region;
  final String state;
  final String resourceType;
  final String riskLevel;
  final String riskDisplay;
  final String riskReason;
  final double estimatedHourlyCost;
  final ResourceCostModel? costInfo;
  final Map<String, dynamic> metadata;
  final String? lastSeenAt;
  final String? createdAt;
  final String? updatedAt;

  ResourceModel({
    required this.id,
    this.accountId,
    this.accountName = '',
    this.accountNumber = '',
    required this.service,
    this.serviceDisplay = '',
    required this.resourceId,
    this.name = '',
    required this.region,
    required this.state,
    this.resourceType = '',
    this.riskLevel = 'NONE',
    this.riskDisplay = 'None',
    this.riskReason = '',
    this.estimatedHourlyCost = 0.0,
    this.costInfo,
    this.metadata = const {},
    this.lastSeenAt,
    this.createdAt,
    this.updatedAt,
  });

  String get displayName => name.isNotEmpty ? name : resourceId;
  String get resourceIdentifier => displayName;
  String get serviceType => service;
  bool get isCritical => riskLevel == 'CRITICAL';
  bool get isHigh => riskLevel == 'HIGH';
  bool get isMedium => riskLevel == 'MEDIUM';
  bool get isLow => riskLevel == 'LOW';
  bool get hasRisk => riskLevel != 'NONE';

  factory ResourceModel.fromJson(Map<String, dynamic> json) {
    return ResourceModel(
      id: json['id']?.toString() ?? '',
      accountId: json['account']?.toString(),
      accountName: json['account_name']?.toString() ?? '',
      accountNumber: json['account_number']?.toString() ?? '',
      service: json['service']?.toString() ?? '',
      serviceDisplay: json['service_display']?.toString() ?? json['service']?.toString() ?? '',
      resourceId: json['resource_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      region: json['region']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      resourceType: json['resource_type']?.toString() ?? '',
      riskLevel: json['risk_level']?.toString() ?? 'NONE',
      riskDisplay: json['risk_display']?.toString() ?? 'None',
      riskReason: json['risk_reason']?.toString() ?? '',
      estimatedHourlyCost: (json['estimated_hourly_cost'] != null)
          ? double.tryParse(json['estimated_hourly_cost'].toString()) ?? 0.0
          : 0.0,
      costInfo: json['cost_info'] != null ? ResourceCostModel.fromJson(json['cost_info']) : null,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      lastSeenAt: json['last_seen_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

