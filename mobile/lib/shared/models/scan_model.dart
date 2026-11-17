class ScanModel {
  final String id;
  final String accountId;
  final String accountName;
  final String status;
  final int resourcesFound;
  final int alertsGenerated;
  final String? errorMessage;
  final DateTime startedAt;
  final DateTime? completedAt;

  ScanModel({
    required this.id,
    required this.accountId,
    required this.accountName,
    required this.status,
    required this.resourcesFound,
    required this.alertsGenerated,
    this.errorMessage,
    required this.startedAt,
    this.completedAt,
  });

  factory ScanModel.fromJson(Map<String, dynamic> json) {
    return ScanModel(
      id: json['id'] ?? '',
      accountId: json['account'] ?? '',
      accountName: json['account_name'] ?? '',
      status: json['status'] ?? 'PENDING',
      resourcesFound: json['resources_found'] ?? 0,
      alertsGenerated: json['alerts_generated'] ?? 0,
      errorMessage: json['error_message'],
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at']) ?? DateTime.now()
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account': accountId,
      'account_name': accountName,
      'status': status,
      'resources_found': resourcesFound,
      'alerts_generated': alertsGenerated,
      'error_message': errorMessage,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  int get alertsCreated => alertsGenerated;
  int get resourcesScanned => resourcesFound;
  bool get isRunning => status == 'RUNNING' || status == 'IN_PROGRESS';
  bool get isCompleted => status == 'COMPLETED';
  bool get isFailed => status == 'FAILED';
}
