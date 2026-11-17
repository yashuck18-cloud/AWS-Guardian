import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/dialogs.dart';
import '../../../shared/widgets/guardian_card.dart';
import '../../auth/providers/auth_provider.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await DialogUtils.showConfirmDialog(
      context: context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out of AWS Guardian?',
      confirmLabel: 'Sign Out',
      isDanger: true,
      icon: Icons.logout_rounded,
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('More', style: AppTypography.headingMedium),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Banner
              GuardianCard(
                onTap: () => context.push('/settings/profile'),
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'G',
                        style: AppTypography.headingLarge.copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Cloud Architect',
                            style: AppTypography.sectionTitle.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? 'architect@cloud.com',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Insights & Tools Section
              Text('Insights & Controls', style: AppTypography.label.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 10),
              GuardianCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildMenuItem(
                      context,
                      title: 'Costs & Spend Impact',
                      subtitle: 'Transparent estimated spend and idle waste',
                      icon: Icons.attach_money_rounded,
                      color: AppColors.success,
                      onTap: () => context.push('/costs'),
                    ),
                    const Divider(),
                    _buildMenuItem(
                      context,
                      title: 'Analytics & Intelligence',
                      subtitle: 'Fleet breakdown, trends, and risk distribution',
                      icon: Icons.insights_rounded,
                      color: AppColors.info,
                      onTap: () => context.push('/analytics'),
                    ),
                    const Divider(),
                    _buildMenuItem(
                      context,
                      title: 'Notifications Digest',
                      subtitle: 'Morning/Evening summaries and Telegram delivery',
                      icon: Icons.notifications_active_rounded,
                      color: AppColors.primaryLight,
                      onTap: () => context.push('/notifications'),
                    ),
                    const Divider(),
                    _buildMenuItem(
                      context,
                      title: 'Activity & Audit Log',
                      subtitle: 'Complete immutable operational audit trail',
                      icon: Icons.history_rounded,
                      color: AppColors.warning,
                      onTap: () => context.push('/activity'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Settings & Support Section
              Text('Settings & Help', style: AppTypography.label.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 10),
              GuardianCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildMenuItem(
                      context,
                      title: 'Settings',
                      subtitle: 'Scanning thresholds, notification intervals, themes',
                      icon: Icons.settings_rounded,
                      color: AppColors.textSecondary,
                      onTap: () => context.push('/settings'),
                    ),
                    const Divider(),
                    _buildMenuItem(
                      context,
                      title: 'Help & FAQs',
                      subtitle: 'IAM role configuration and safety principles',
                      icon: Icons.help_outline_rounded,
                      color: AppColors.textSecondary,
                      onTap: () => context.push('/help'),
                    ),
                    const Divider(),
                    _buildMenuItem(
                      context,
                      title: 'About AWS Guardian',
                      subtitle: 'Version 1.0.0 • Architecture and security policy',
                      icon: Icons.info_outline_rounded,
                      color: AppColors.textSecondary,
                      onTap: () => context.push('/about'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout Button
              GuardianCard(
                onTap: () => _handleLogout(context, ref),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded, color: AppColors.critical, size: 20),
                    const SizedBox(width: 14),
                    Text(
                      'Sign Out',
                      style: AppTypography.sectionTitle.copyWith(color: AppColors.critical),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        'assets/images/logo_icon.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AWS Guardian v1.0.0',
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.sectionTitle.copyWith(fontSize: 15)),
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
