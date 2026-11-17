import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../shared/widgets/aws_region_picker_modal.dart';
import '../../../core/constants/aws_regions.dart';
import '../providers/aws_accounts_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../resources/providers/resources_provider.dart';
import '../../analytics/providers/analytics_provider.dart';

class AccountDetailsScreen extends ConsumerStatefulWidget {
  final String accountId;
  const AccountDetailsScreen({super.key, required this.accountId});

  @override
  ConsumerState<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends ConsumerState<AccountDetailsScreen> {
  bool _isVerifying = false;
  bool _isScanning = false;

  Future<void> _handleChangeRegion(String accId, String currentRegion) async {
    AwsRegionPickerModal.show(
      context,
      currentRegion: currentRegion,
      onRegionSelected: (newRegion) async {
        Toast.showInfo(context, 'Switching region to ${AwsRegions.getName(newRegion)}...');
        final success = await ref
            .read(awsAccountsProvider.notifier)
            .updateAccountRegion(accId, newRegion);
        if (!mounted) return;
        if (success) {
          Toast.showSuccess(
            context,
            'Region changed to ${AwsRegions.getName(newRegion)} ✓ Scanning resources...',
          );
          ref.read(resourcesProvider.notifier).setAccount(accId, forceReload: true, region: newRegion);
          ref.read(dashboardProvider.notifier).fetchDashboardStats(accountId: accId, region: newRegion);
          ref.read(analyticsProvider.notifier).fetchAnalyticsData(accountId: accId);
        } else {
          Toast.showError(context, 'Failed to update account region');
        }
      },
    );
  }

  Future<void> _handleVerify(String accId) async {
    setState(() => _isVerifying = true);
    final result = await ref.read(awsAccountsProvider.notifier).verifyAccount(accId);
    setState(() => _isVerifying = false);

    if (!mounted) return;
    if (result['success'] == true) {
      Toast.showSuccess(context, 'AWS Account verified successfully.');
      ref.read(resourcesProvider.notifier).setAccount(accId, forceReload: true);
      ref.read(dashboardProvider.notifier).fetchDashboardStats(accountId: accId);
    } else {
      Toast.showError(context, result['message'] ?? 'Verification failed.');
    }
  }

  Future<void> _handleTriggerScan(String accId, String accName) async {
    Toast.showInfo(context, 'Triggering scan for $accName...');
    setState(() => _isScanning = true);
    final res = await ref.read(dashboardProvider.notifier).triggerScan(accountId: accId);
    if (!mounted) return;
    setState(() => _isScanning = false);

    if (res != null) {
      final accounts = ref.read(awsAccountsProvider).accounts;
      final acc = accounts.isNotEmpty ? accounts.firstWhere((a) => a.id == accId, orElse: () => accounts.first) : null;
      final reg = (acc != null && acc.enabledRegions.isNotEmpty && acc.enabledRegions.length == 1)
          ? acc.enabledRegions.first
          : 'all';
      ref.read(resourcesProvider.notifier).setAccount(accId, forceReload: true, region: reg);
      ref.read(dashboardProvider.notifier).fetchDashboardStats(accountId: accId);
      Toast.showSuccess(context, 'Scan complete: ${res.resourcesFound} resources inspected');
    }
  }

  Future<void> _handleDelete(String accId, String accName) async {
    final confirmed = await DialogUtils.showConfirmDialog(
      context: context,
      title: 'Disconnect AWS Account',
      message: 'Are you sure you want to disconnect $accName? Scanned resources will be removed from AWS Guardian monitoring.',
      confirmLabel: 'Disconnect',
      isDanger: true,
      icon: Icons.delete_forever_rounded,
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(awsAccountsProvider.notifier).deleteAccount(accId);
      if (!mounted) return;
      if (success) {
        Toast.showSuccess(context, 'Account disconnected.');
        context.pop();
      } else {
        Toast.showError(context, 'Failed to disconnect account.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsState = ref.watch(awsAccountsProvider);
    final account = accountsState.accounts.firstWhere(
      (a) => a.id == widget.accountId,
      orElse: () => accountsState.accounts.isNotEmpty
          ? accountsState.accounts.first
          : throw Exception('Account not found'),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(account.name, style: AppTypography.headingMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.critical),
            onPressed: () => _handleDelete(account.id, account.name),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              GuardianCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(account.name, style: AppTypography.headingLarge),
                        GuardianBadge.status(account.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AWS Account ID: ${account.accountId}',
                      style: AppTypography.code,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildDetailRow('Last Scan', Formatters.formatDateTime(account.lastScanAt)),
                    const SizedBox(height: 10),
                    _buildDetailRow('Connected On', Formatters.formatDate(account.createdAt)),
                    const SizedBox(height: 10),
                    _buildDetailRow('Active Alerts', '${account.alertCount}', isHighlighted: account.alertCount > 0),
                    const SizedBox(height: 10),
                    _buildDetailRow('Discovered Resources', '${account.resourceCount}', isHighlighted: account.resourceCount > 0),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // IAM Configuration Card
              Text('IAM Role Configuration', style: AppTypography.sectionTitle),
              const SizedBox(height: 12),
              GuardianCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Role ARN', style: AppTypography.caption),
                    const SizedBox(height: 4),
                    SelectableText(account.roleArn, style: AppTypography.code.copyWith(fontSize: 12)),
                    const SizedBox(height: 16),
                    Text('External ID', style: AppTypography.caption),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(account.externalId, style: AppTypography.code.copyWith(fontSize: 12)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primaryLight),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: account.externalId));
                            Toast.showSuccess(context, 'External ID copied');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Enabled Regions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Configured Regions', style: AppTypography.sectionTitle),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.edit_location_alt_rounded, size: 15, color: Color(0xFF00A4E4)),
                    label: const Text(
                      'Change Region',
                      style: TextStyle(
                        color: Color(0xFF00A4E4),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => _handleChangeRegion(
                      account.id,
                      account.enabledRegions.isNotEmpty ? account.enabledRegions.first : 'ap-south-1',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: account.enabledRegions.map((reg) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(reg, style: AppTypography.label.copyWith(color: AppColors.textPrimary)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Actions
              GuardianButton(
                label: 'View All Discovered Resources (${account.resourceCount})',
                variant: ButtonVariant.primary,
                width: double.infinity,
                icon: Icons.inventory_2_outlined,
                onPressed: () {
                  ref.read(awsAccountsProvider.notifier).selectAccount(account);
                  final reg = (account.enabledRegions.isNotEmpty && account.enabledRegions.length == 1)
                      ? account.enabledRegions.first
                      : 'all';
                  ref.read(resourcesProvider.notifier).setAccount(account.id, forceReload: true, region: reg);
                  context.push('/resources');
                },
              ),
              const SizedBox(height: 12),

              GuardianButton(
                label: 'Trigger Scan Now',
                variant: ButtonVariant.secondary,
                width: double.infinity,
                isLoading: _isScanning,
                icon: Icons.refresh_rounded,
                onPressed: () => _handleTriggerScan(account.id, account.name),
              ),
              const SizedBox(height: 12),

              GuardianButton(
                label: 'Re-Verify IAM Role',
                variant: ButtonVariant.outlined,
                width: double.infinity,
                isLoading: _isVerifying,
                icon: Icons.verified_user_rounded,
                onPressed: () => _handleVerify(account.id),
              ),
              const SizedBox(height: 12),

              GuardianButton(
                label: 'Disconnect AWS Account',
                variant: ButtonVariant.danger,
                width: double.infinity,
                icon: Icons.link_off_rounded,
                onPressed: () => _handleDelete(account.id, account.name),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMedium),
        Text(
          value,
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: isHighlighted ? AppColors.warning : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
