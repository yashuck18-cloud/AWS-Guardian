class AWSAccountModel {
  final String id;
  final String name;
  final String accountId;
  final String roleArn;
  final String externalId;
  final String status;
  final String statusDisplay;
  final String? lastScanAt;
  final String errorMessage;
  final List<String> enabledRegions;
  final String? createdAt;
  final int resourceCount;
  final int alertCount;

  AWSAccountModel({
    required this.id,
    required this.name,
    required this.accountId,
    required this.roleArn,
    required this.externalId,
    this.status = 'PENDING',
    this.statusDisplay = 'Pending',
    this.lastScanAt,
    this.errorMessage = '',
    this.enabledRegions = const ['ap-south-1', 'us-east-1', 'us-west-2'],
    this.createdAt,
    this.resourceCount = 0,
    this.alertCount = 0,
  });

  bool get isConnected => status == 'CONNECTED';
  bool get hasError => status == 'ERROR';

  factory AWSAccountModel.fromJson(Map<String, dynamic> json) {
    return AWSAccountModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      accountId: json['account_id']?.toString() ?? '',
      roleArn: json['role_arn']?.toString() ?? '',
      externalId: json['external_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      statusDisplay: json['status_display']?.toString() ?? 'Pending',
      lastScanAt: json['last_scan_at']?.toString(),
      errorMessage: json['error_message']?.toString() ?? '',
      enabledRegions: (json['enabled_regions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['ap-south-1', 'us-east-1'],
      createdAt: json['created_at']?.toString(),
      resourceCount: json['resource_count'] as int? ?? 0,
      alertCount: json['alert_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'account_id': accountId,
      'role_arn': roleArn,
      'external_id': externalId,
      'status': status,
      'enabled_regions': enabledRegions,
    };
  }
}
