import 'resource_model.dart';

class AlertModel {
  final String id;
  final String? accountId;
  final String accountName;
  final String accountNumber;
  final ResourceModel? resource;
  final String resourceName;
  final String resourceIdStr;
  final String resourceService;
  final String resourceRegion;
  final String ruleCode;
  final String title;
  final String description;
  final String severity;
  final String severityDisplay;
  final String status;
  final String statusDisplay;
  final double estimatedCostImpact;
  final String? firstDetectedAt;
  final String? lastDetectedAt;
  final String? resolvedAt;

  AlertModel({
    required this.id,
    this.accountId,
    this.accountName = '',
    this.accountNumber = '',
    this.resource,
    this.resourceName = '',
    this.resourceIdStr = '',
    this.resourceService = '',
    this.resourceRegion = '',
    required this.ruleCode,
    required this.title,
    required this.description,
    required this.severity,
    this.severityDisplay = '',
    this.status = 'ACTIVE',
    this.statusDisplay = 'Active',
    this.estimatedCostImpact = 0.0,
    this.firstDetectedAt,
    this.lastDetectedAt,
    this.resolvedAt,
  });

  bool get isActive => status == 'ACTIVE';
  bool get isAcknowledged => status == 'ACKNOWLEDGED';
  bool get isResolved => status == 'RESOLVED';

  String get resourceIdentifier {
    if (resourceName.isNotEmpty) return resourceName;
    if (resourceIdStr.isNotEmpty) return resourceIdStr;
    if (resource != null && resource!.resourceId.isNotEmpty) return resource!.resourceId;
    return 'Resource';
  }

  String get resourceType {
    if (resourceService.isNotEmpty) return resourceService;
    if (resource != null && resource!.service.isNotEmpty) return resource!.service;
    if (resource != null && resource!.resourceType.isNotEmpty) return resource!.resourceType;
    return 'AWS';
  }

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id']?.toString() ?? '',
      accountId: json['account']?.toString(),
      accountName: json['account_name']?.toString() ?? '',
      accountNumber: json['account_number']?.toString() ?? '',
      resource: json['resource'] != null && json['resource'] is Map<String, dynamic>
          ? ResourceModel.fromJson(json['resource'] as Map<String, dynamic>)
          : null,
      resourceName: json['resource_name']?.toString() ?? '',
      resourceIdStr: json['resource_id_str']?.toString() ?? '',
      resourceService: json['resource_service']?.toString() ?? '',
      resourceRegion: json['resource_region']?.toString() ?? '',
      ruleCode: json['rule_code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      severity: json['severity']?.toString() ?? 'HIGH',
      severityDisplay: json['severity_display']?.toString() ?? json['severity']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACTIVE',
      statusDisplay: json['status_display']?.toString() ?? json['status']?.toString() ?? '',
      estimatedCostImpact: (json['estimated_cost_impact'] != null)
          ? double.tryParse(json['estimated_cost_impact'].toString()) ?? 0.0
          : 0.0,
      firstDetectedAt: json['first_detected_at']?.toString(),
      lastDetectedAt: json['last_detected_at']?.toString(),
      resolvedAt: json['resolved_at']?.toString(),
    );
  }
}
