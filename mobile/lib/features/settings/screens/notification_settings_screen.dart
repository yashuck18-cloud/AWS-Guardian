import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/toast.dart';
import '../../../shared/widgets/guardian_card.dart';
import '../../../shared/widgets/guardian_button.dart';
import '../../../shared/widgets/guardian_text_field.dart';
import '../../notifications/providers/notifications_provider.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  late bool _morningEnabled;
  late bool _eveningEnabled;
  late bool _urgentEnabled;
  late bool _telegramEnabled;
  final _chatIdController = TextEditingController();
  String _timezone = 'UTC';
  bool _isSaving = false;
  bool _isTestingTelegram = false;
  bool _isTestingFCM = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(notificationsProvider).settings;
    _morningEnabled = settings.morningSummaryEnabled;
    _eveningEnabled = settings.eveningSummaryEnabled;
    _urgentEnabled = settings.urgentAlertsEnabled;
    _telegramEnabled = settings.telegramEnabled;
    _chatIdController.text = settings.telegramChatId;
    _timezone = settings.timezone;
  }

  @override
  void dispose() {
    _chatIdController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final success = await ref.read(notificationsProvider.notifier).updateSettings({
      'morning_summary_enabled': _morningEnabled,
      'evening_summary_enabled': _eveningEnabled,
      'urgent_alerts_enabled': _urgentEnabled,
      'telegram_enabled': _telegramEnabled,
      'telegram_chat_id': _chatIdController.text.trim(),
      'timezone': _timezone,
    });
    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        Toast.showSuccess(context, 'Notification settings updated');
      } else {
        Toast.showError(context, 'Failed to update notification settings');
      }
    }
  }

  Future<void> _handleTestFCM() async {
    setState(() => _isTestingFCM = true);
    final res = await ref.read(notificationsProvider.notifier).testFCM();
    setState(() => _isTestingFCM = false);

    if (mounted) {
      if (res['success'] == true) {
        Toast.showSuccess(context, res['message'] ?? 'Test notification sent to your phone!');
      } else {
        Toast.showError(context, res['message'] ?? 'Failed to trigger test notification');
      }
    }
  }

  Future<void> _handleTestTelegram() async {
    final chatId = _chatIdController.text.trim();
    if (chatId.isEmpty) {
      Toast.showError(context, 'Please enter a Telegram Chat ID');
      return;
    }

    setState(() => _isTestingTelegram = true);
    final res = await ref.read(notificationsProvider.notifier).testTelegram(chatId);
    setState(() => _isTestingTelegram = false);

    if (mounted) {
      if (res['success'] == true) {
        Toast.showSuccess(context, 'Test message sent to Telegram');
      } else {
        Toast.showError(context, res['message'] ?? 'Failed to send test message');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Notification Settings', style: AppTypography.headingMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Scheduled Summaries', style: AppTypography.sectionTitle),
              const SizedBox(height: 12),
              GuardianCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text('Morning Summary (09:00)', style: AppTypography.bodyLarge),
                      subtitle: Text('Twice-daily fleet status digest', style: AppTypography.caption),
                      value: _morningEnabled,
                      activeThumbColor: AppColors.primaryLight,
                      onChanged: (val) => setState(() => _morningEnabled = val),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: Text('Evening Summary (19:00)', style: AppTypography.bodyLarge),
                      subtitle: Text('End of day cost & alert report', style: AppTypography.caption),
                      value: _eveningEnabled,
                      activeThumbColor: AppColors.primaryLight,
                      onChanged: (val) => setState(() => _eveningEnabled = val),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: Text('Urgent Alerts', style: AppTypography.bodyLarge),
                      subtitle: Text('Immediate alerts for Critical level findings', style: AppTypography.caption),
                      value: _urgentEnabled,
                      activeThumbColor: AppColors.critical,
                      onChanged: (val) => setState(() => _urgentEnabled = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Device Push Notifications (FCM) Card
              Text('Mobile Push Notifications (FCM)', style: AppTypography.sectionTitle),
              const SizedBox(height: 6),
              Text(
                'Receive heads-up security, cost waste, and twice-daily fleet summaries directly on your device.',
                style: AppTypography.caption,
              ),
              const SizedBox(height: 12),
              GuardianCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notifications_active_rounded, color: AppColors.primaryLight, size: 20),
                        const SizedBox(width: 8),
                        Text('FCM Delivery Pipeline', style: AppTypography.bodyLarge),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Test the Django REST API → Firebase Admin SDK → Android Phone push notification pipeline.',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 14),
                    GuardianButton(
                      label: 'Send Test Push Notification',
                      variant: ButtonVariant.outlined,
                      width: double.infinity,
                      isLoading: _isTestingFCM,
                      onPressed: _handleTestFCM,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Telegram Integration Card
              Text('Telegram Bot Integration', style: AppTypography.sectionTitle),
              const SizedBox(height: 6),
              Text(
                'Receive cloud summaries directly inside Telegram chat.',
                style: AppTypography.caption,
              ),
              const SizedBox(height: 12),
              GuardianCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: Text('Enable Telegram Delivery', style: AppTypography.bodyLarge),
                      contentPadding: EdgeInsets.zero,
                      value: _telegramEnabled,
                      activeThumbColor: AppColors.info,
                      onChanged: (val) => setState(() => _telegramEnabled = val),
                    ),
                    if (_telegramEnabled) ...[
                      const SizedBox(height: 12),
                      GuardianTextField(
                        controller: _chatIdController,
                        labelText: 'Telegram Chat ID',
                        hintText: 'e.g. 123456789',
                        prefixIcon: const Icon(Icons.send_rounded, size: 18, color: AppColors.info),
                      ),
                      const SizedBox(height: 14),
                      GuardianButton(
                        label: 'Send Test Notification',
                        variant: ButtonVariant.outlined,
                        width: double.infinity,
                        isLoading: _isTestingTelegram,
                        onPressed: _handleTestTelegram,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              GuardianButton(
                label: 'Save Notification Preferences',
                width: double.infinity,
                isLoading: _isSaving,
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
