import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/toast.dart';
import '../../../core/utils/dialogs.dart';
import '../../../shared/widgets/guardian_card.dart';
import '../../../shared/widgets/guardian_badge.dart';
import '../../../shared/widgets/guardian_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/aws_region_picker_modal.dart';
import '../../../core/constants/aws_regions.dart';
import '../../resources/providers/resources_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../analytics/providers/analytics_provider.dart';
import '../providers/aws_accounts_provider.dart';

class AWSAccountsScreen extends ConsumerStatefulWidget {
  const AWSAccountsScreen({super.key});

  @override
  ConsumerState<AWSAccountsScreen> createState() => _AWSAccountsScreenState();
}

class _AWSAccountsScreenState extends ConsumerState<AWSAccountsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(awsAccountsProvider.notifier).fetchAccounts();
    });
  }

  Future<void> _handleChangeRegion(String accountId, String currentRegion) async {
    AwsRegionPickerModal.show(
      context,
      currentRegion: currentRegion,
      onRegionSelected: (newRegion) async {
        Toast.showInfo(context, 'Switching region to ${AwsRegions.getName(newRegion)}...');
        final success = await ref
            .read(awsAccountsProvider.notifier)
            .updateAccountRegion(accountId, newRegion);
        if (!mounted) return;
        if (success) {
          Toast.showSuccess(
            context,
            'Region changed to ${AwsRegions.getName(newRegion)} ✓ Scanning resources...',
          );
          ref.read(resourcesProvider.notifier).setAccount(accountId, forceReload: true, region: newRegion);
          ref.read(dashboardProvider.notifier).fetchDashboardStats(accountId: accountId, region: newRegion);
          ref.read(analyticsProvider.notifier).fetchAnalyticsData(accountId: accountId);
        } else {
          Toast.showError(context, 'Failed to update account region');
        }
      },
    );
  }

  Future<void> _handleDelete(String accId, String accName) async {
    final confirmed = await DialogUtils.showConfirmDialog(
      context: context,
      title: 'Disconnect AWS Account',
      message: 'Are you sure you want to disconnect $accName? Scanned resources will be removed from AWS Guardian monitoring.',
      confirmLabel: 'Disconnect',
      isDanger: true,
      icon: Icons.link_off_rounded,
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(awsAccountsProvider.notifier).deleteAccount(accId);
      if (!mounted) return;
      if (success) {
        Toast.showSuccess(context, 'Account disconnected.');
      } else {
        Toast.showError(context, 'Failed to disconnect account.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsState = ref.watch(awsAccountsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('AWS Accounts', style: AppTypography.headingMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => context.push('/iam-instructions'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryLight,
          backgroundColor: AppColors.surfaceElevated,
          onRefresh: () => ref.read(awsAccountsProvider.notifier).fetchAccounts(),
          child: accountsState.isLoading && accountsState.accounts.isEmpty
              ? const ListSkeletonLoader(count: 3)
              : accountsState.accounts.isEmpty
                  ? EmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: 'No AWS accounts connected',
                      description: 'Connect your AWS account using IAM Role ARN + External ID to start monitoring.',
                      buttonLabel: 'Connect AWS Account',
                      onButtonPressed: () => context.push('/connect-aws'),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: accountsState.accounts.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == accountsState.accounts.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: GuardianButton(
                              label: 'Connect AWS Account',
                              icon: Icons.add_rounded,
                              variant: ButtonVariant.outlined,
                              width: double.infinity,
                              onPressed: () => context.push('/connect-aws'),
                            ),
                          );
                        }

                        final account = accountsState.accounts[index];
                        return GuardianCard(
                          onTap: () => context.push('/aws-accounts/${account.id}'),
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      account.name,
                                      style: AppTypography.headingMedium.copyWith(fontSize: 17),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  GuardianBadge.status(account.status),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.critical),
                                    tooltip: 'Disconnect Account',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _handleDelete(account.id, account.name),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Account ID: ${account.accountId}',
                                style: AppTypography.code.copyWith(fontSize: 13),
                              ),
                              const SizedBox(height: 10),

                              // Interactive Region Switcher Row
                              InkWell(
                                onTap: () => _handleChangeRegion(
                                  account.id,
                                  account.enabledRegions.isNotEmpty
                                      ? account.enabledRegions.first
                                      : 'ap-south-1',
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF00A4E4).withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.public_rounded, size: 16, color: Color(0xFF00A4E4)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Region: ${AwsRegions.getFormattedLabel(account.enabledRegions.isNotEmpty ? account.enabledRegions.first : 'ap-south-1')}',
                                          style: const TextStyle(
                                            color: Color(0xFF00A4E4),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E293B),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFF334155)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Change',
                                              style: TextStyle(
                                                color: Color(0xFF00A4E4),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(width: 3),
                                            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF00A4E4)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Last scan', style: AppTypography.caption),
                                      const SizedBox(height: 2),
                                      Text(
                                        Formatters.timeAgo(account.lastScanAt),
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      _buildCountChip(
                                        icon: Icons.layers_outlined,
                                        count: '${account.resourceCount}',
                                        label: 'Resources',
                                      ),
                                      const SizedBox(width: 8),
                                      _buildCountChip(
                                        icon: Icons.warning_amber_rounded,
                                        count: '${account.alertCount}',
                                        label: 'Alerts',
                                        isAlert: account.alertCount > 0,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildCountChip({
    required IconData icon,
    required String count,
    required String label,
    bool isAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAlert ? AppColors.warning.withValues(alpha: 0.4) : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: isAlert ? AppColors.warning : AppColors.textSecondary,
          ),
          const SizedBox(width: 5),
          Text(
            count,
            style: AppTypography.label.copyWith(
              color: isAlert ? AppColors.warning : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
