class NotificationSettingsModel {
  final bool morningSummaryEnabled;
  final String morningSummaryTime;
  final bool eveningSummaryEnabled;
  final String eveningSummaryTime;
  final bool urgentAlertsEnabled;
  final String timezone;
  final bool telegramEnabled;
  final String telegramChatId;

  NotificationSettingsModel({
    this.morningSummaryEnabled = true,
    this.morningSummaryTime = '09:00',
    this.eveningSummaryEnabled = true,
    this.eveningSummaryTime = '19:00',
    this.urgentAlertsEnabled = true,
    this.timezone = 'UTC',
    this.telegramEnabled = false,
    this.telegramChatId = '',
  });

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    final data = json['settings'] ?? json;
    return NotificationSettingsModel(
      morningSummaryEnabled: data['morning_summary_enabled'] as bool? ?? true,
      morningSummaryTime: data['morning_summary_time']?.toString() ?? '09:00',
      eveningSummaryEnabled: data['evening_summary_enabled'] as bool? ?? true,
      eveningSummaryTime: data['evening_summary_time']?.toString() ?? '19:00',
      urgentAlertsEnabled: data['urgent_alerts_enabled'] as bool? ?? true,
      timezone: data['timezone']?.toString() ?? 'UTC',
      telegramEnabled: data['telegram_enabled'] as bool? ?? false,
      telegramChatId: data['telegram_chat_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'morning_summary_enabled': morningSummaryEnabled,
      'morning_summary_time': morningSummaryTime,
      'evening_summary_enabled': eveningSummaryEnabled,
      'evening_summary_time': eveningSummaryTime,
      'urgent_alerts_enabled': urgentAlertsEnabled,
      'timezone': timezone,
      'telegram_enabled': telegramEnabled,
      'telegram_chat_id': telegramChatId,
    };
  }

  NotificationSettingsModel copyWith({
    bool? morningSummaryEnabled,
    String? morningSummaryTime,
    bool? eveningSummaryEnabled,
    String? eveningSummaryTime,
    bool? urgentAlertsEnabled,
    String? timezone,
    bool? telegramEnabled,
    String? telegramChatId,
  }) {
    return NotificationSettingsModel(
      morningSummaryEnabled: morningSummaryEnabled ?? this.morningSummaryEnabled,
      morningSummaryTime: morningSummaryTime ?? this.morningSummaryTime,
      eveningSummaryEnabled: eveningSummaryEnabled ?? this.eveningSummaryEnabled,
      eveningSummaryTime: eveningSummaryTime ?? this.eveningSummaryTime,
      urgentAlertsEnabled: urgentAlertsEnabled ?? this.urgentAlertsEnabled,
      timezone: timezone ?? this.timezone,
      telegramEnabled: telegramEnabled ?? this.telegramEnabled,
      telegramChatId: telegramChatId ?? this.telegramChatId,
    );
  }
}

class NotificationHistoryModel {
  final String id;
  final String title;
  final String message;
  final String channel;
  final String channelDisplay;
  final String status;
  final String statusDisplay;
  final String errorDetails;
  final String? createdAt;

  NotificationHistoryModel({
    required this.id,
    required this.title,
    required this.message,
    required this.channel,
    this.channelDisplay = '',
    required this.status,
    this.statusDisplay = '',
    this.errorDetails = '',
    this.createdAt,
  });

  bool get isSent => status == 'SENT';

  factory NotificationHistoryModel.fromJson(Map<String, dynamic> json) {
    return NotificationHistoryModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      channel: json['channel']?.toString() ?? 'IN_APP',
      channelDisplay: json['channel_display']?.toString() ?? json['channel']?.toString() ?? '',
      status: json['status']?.toString() ?? 'SENT',
      statusDisplay: json['status_display']?.toString() ?? json['status']?.toString() ?? '',
      errorDetails: json['error_details']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
    );
  }
}
