class UserModel {
  final String id;
  final String email;
  final String name;
  final String avatarUrl;
  final int scanIntervalHours;
  final int ec2ThresholdHours;
  final int ebsThresholdHours;
  final String themePreference;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl = '',
    this.scanIntervalHours = 12,
    this.ec2ThresholdHours = 24,
    this.ebsThresholdHours = 24,
    this.themePreference = 'dark',
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString() ?? '',
      scanIntervalHours: json['scan_interval_hours'] as int? ?? 12,
      ec2ThresholdHours: json['ec2_threshold_hours'] as int? ?? 24,
      ebsThresholdHours: json['ebs_threshold_hours'] as int? ?? 24,
      themePreference: json['theme_preference']?.toString() ?? 'dark',
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'scan_interval_hours': scanIntervalHours,
      'ec2_threshold_hours': ec2ThresholdHours,
      'ebs_threshold_hours': ebsThresholdHours,
      'theme_preference': themePreference,
    };
  }

  UserModel copyWith({
    String? name,
    String? avatarUrl,
    int? scanIntervalHours,
    int? ec2ThresholdHours,
    int? ebsThresholdHours,
    String? themePreference,
  }) {
    return UserModel(
      id: id,
      email: email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      scanIntervalHours: scanIntervalHours ?? this.scanIntervalHours,
      ec2ThresholdHours: ec2ThresholdHours ?? this.ec2ThresholdHours,
      ebsThresholdHours: ebsThresholdHours ?? this.ebsThresholdHours,
      themePreference: themePreference ?? this.themePreference,
      createdAt: createdAt,
    );
  }
}
