import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/dialogs.dart';
import '../../../core/utils/toast.dart';
import '../../../shared/widgets/guardian_card.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _handleDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await DialogUtils.showConfirmDialog(
      context: context,
      title: 'Delete Account Permanently',
      message: 'This will permanently remove your user account and all connected AWS configurations. This cannot be undone.',
      confirmLabel: 'Delete Account',
      isDanger: true,
      icon: Icons.delete_forever_rounded,
    );

    if (confirmed == true && context.mounted) {
      final success = await ref.read(authProvider.notifier).deleteAccount();
      if (context.mounted) {
        if (success) {
          Toast.showSuccess(context, 'Account deleted');
          context.go('/login');
        } else {
          Toast.showError(context, 'Failed to delete account');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Settings', style: AppTypography.headingMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Account & Preferences', style: AppTypography.label.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 10),
              GuardianCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildSettingsItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Profile & Credentials',
                      subtitle: 'Name, email, and password security',
                      onTap: () => context.push('/settings/profile'),
                    ),
                    const Divider(),
                    _buildSettingsItem(
                      icon: Icons.tune_rounded,
                      title: 'Scanning Thresholds',
                      subtitle: 'EC2 runtime, EBS idle, and scan frequency',
                      onTap: () => context.push('/settings/scanning'),
                    ),
                    const Divider(),
                    _buildSettingsItem(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notification Schedules',
                      subtitle: 'Morning/Evening digests & Telegram Bot',
                      onTap: () => context.push('/settings/notifications'),
                    ),
                    const Divider(),
                    _buildSettingsItem(
                      icon: Icons.palette_outlined,
                      title: 'Appearance & API Config',
                      subtitle: 'Theme modes and API base endpoint',
                      onTap: () => context.push('/settings/appearance'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text('Danger Zone', style: AppTypography.label.copyWith(color: AppColors.critical)),
              const SizedBox(height: 10),
              GuardianCard(
                borderColor: AppColors.critical.withValues(alpha: 0.4),
                padding: EdgeInsets.zero,
                child: _buildSettingsItem(
                  icon: Icons.delete_outline_rounded,
                  title: 'Delete Account',
                  subtitle: 'Permanently remove your account and stored settings',
                  color: AppColors.critical,
                  onTap: () => _handleDeleteAccount(context, ref),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color ?? AppColors.primaryLight, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.sectionTitle.copyWith(
                      fontSize: 15,
                      color: color ?? AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.caption),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
