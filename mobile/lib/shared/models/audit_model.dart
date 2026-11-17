class AuditEventModel {
  final String id;
  final String action;
  final String actionDisplay;
  final Map<String, dynamic> details;
  final String? ipAddress;
  final String timestamp;

  AuditEventModel({
    required this.id,
    required this.action,
    this.actionDisplay = '',
    this.details = const {},
    this.ipAddress,
    required this.timestamp,
  });

  factory AuditEventModel.fromJson(Map<String, dynamic> json) {
    return AuditEventModel(
      id: json['id']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      actionDisplay: json['action_display']?.toString() ?? json['action']?.toString() ?? '',
      details: (json['details'] as Map<String, dynamic>?) ?? {},
      ipAddress: json['ip_address']?.toString(),
      timestamp: json['timestamp']?.toString() ?? '',
    );
  }
}

class ScanModel {
  final String id;
  final String? accountId;
  final String accountName;
  final String accountNumber;
  final String status;
  final String statusDisplay;
  final String startedAt;
  final String? completedAt;
  final int resourcesFound;
  final int alertsCreated;
  final int alertsResolved;
  final int warningsCount;
  final List<String> scannedRegions;
  final Map<String, dynamic> serviceErrors;
  final String errorMessage;

  ScanModel({
    required this.id,
    this.accountId,
    this.accountName = '',
    this.accountNumber = '',
    required this.status,
    this.statusDisplay = '',
    required this.startedAt,
    this.completedAt,
    this.resourcesFound = 0,
    this.alertsCreated = 0,
    this.alertsResolved = 0,
    this.warningsCount = 0,
    this.scannedRegions = const [],
    this.serviceErrors = const {},
    this.errorMessage = '',
  });

  bool get isCompleted => status == 'COMPLETED';
  bool get isInProgress => status == 'IN_PROGRESS';
  bool get isFailed => status == 'FAILED';

  factory ScanModel.fromJson(Map<String, dynamic> json) {
    return ScanModel(
      id: json['id']?.toString() ?? '',
      accountId: json['account']?.toString(),
      accountName: json['account_name']?.toString() ?? '',
      accountNumber: json['account_number']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      statusDisplay: json['status_display']?.toString() ?? json['status']?.toString() ?? '',
      startedAt: json['started_at']?.toString() ?? '',
      completedAt: json['completed_at']?.toString(),
      resourcesFound: json['resources_found'] as int? ?? 0,
      alertsCreated: json['alerts_created'] as int? ?? 0,
      alertsResolved: json['alerts_resolved'] as int? ?? 0,
      warningsCount: json['warnings_count'] as int? ?? 0,
      scannedRegions: (json['scanned_regions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      serviceErrors: (json['service_errors'] as Map<String, dynamic>?) ?? {},
      errorMessage: json['error_message']?.toString() ?? '',
    );
  }
}
