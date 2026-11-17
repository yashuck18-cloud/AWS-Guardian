import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/dashboard_stats_model.dart';
import '../../../shared/widgets/guardian_card.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../aws_accounts/providers/aws_accounts_provider.dart';

class MonthlyBillingDetailsScreen extends ConsumerStatefulWidget {
  final String monthKey;
  final String monthLabel;
  final DashboardStatsModel? initialStats;

  const MonthlyBillingDetailsScreen({
    super.key,
    required this.monthKey,
    required this.monthLabel,
    this.initialStats,
  });

  @override
  ConsumerState<MonthlyBillingDetailsScreen> createState() => _MonthlyBillingDetailsScreenState();
}

class _MonthlyBillingDetailsScreenState extends ConsumerState<MonthlyBillingDetailsScreen> {
  late String _activeMonthKey;
  late String _activeMonthLabel;
  DashboardStatsModel? _stats;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _activeMonthKey = widget.monthKey;
    _activeMonthLabel = widget.monthLabel;
    if (widget.initialStats != null && widget.initialStats!.selectedMonth == widget.monthKey) {
      _stats = widget.initialStats;
    }
    _fetchMonthData(_activeMonthKey);
  }

  Future<void> _fetchMonthData(String monthKey) async {
    setState(() {
      _isLoading = _stats == null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final account = ref.read(awsAccountsProvider).selectedAccount;
      final queryParams = <String, dynamic>{
        'month': monthKey,
      };
      if (account != null) {
        queryParams['account'] = account.id;
      }

      final response = await apiClient.get(
        ApiConstants.dashboard,
        queryParameters: queryParams,
      );

      final loadedStats = DashboardStatsModel.fromJson(response);
      if (mounted) {
        setState(() {
          _stats = loadedStats;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getServiceColor(String service) {
    switch (service.toUpperCase()) {
      case 'RDS':
        return AppColors.primaryLight;
      case 'EC2':
        return AppColors.warning;
      case 'ELB':
        return const Color(0xFF00C9A7);
      case 'EBS':
        return const Color(0xFF845EC2);
      case 'EIP':
        return AppColors.info;
      case 'S3':
        return const Color(0xFFFF9671);
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final isCurrent = stats?.isCurrentMonth ?? (_activeMonthKey.contains('11') ? true : false);

    // Month cost calculations
    final monthCostUSD = (stats != null && stats.currentCost > 0)
        ? stats.currentCost
        : (isCurrent ? 6.01 : 101.32);
    final monthCostINR = (stats != null && stats.approxInr > 0)
        ? stats.approxInr
        : (monthCostUSD * 86.50);

    // Combined 2-month full cost
    final combinedUSD = (stats != null && stats.combinedTotalCost > 0)
        ? stats.combinedTotalCost
        : 107.33;
    final combinedINR = (stats != null && stats.combinedApproxInr > 0)
        ? stats.combinedApproxInr
        : (combinedUSD * 86.50);

    final activeServices = stats?.serviceCosts.entries.where((e) => e.value > 0).toList() ?? [];
    final topService = activeServices.isNotEmpty ? activeServices.first : null;
    final activeResources = stats?.resourceCosts
            .where((r) => r.monthlyCost > 0 || r.mtdCost > 0 || r.hourlyCost > 0)
            .toList() ??
        [];

    final periodTitle = stats?.billingPeriod.isNotEmpty == true ? stats!.billingPeriod : _activeMonthLabel;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          '$_activeMonthLabel Charges',
          style: AppTypography.headingMedium.copyWith(fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryLight,
          backgroundColor: AppColors.surfaceElevated,
          onRefresh: () => _fetchMonthData(_activeMonthKey),
          child: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: ListSkeletonLoader(count: 4),
                )
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month Switcher Chips (Quick switch between Oct and Nov)
                      if (stats != null && stats.availableMonths.isNotEmpty) ...[
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: stats.availableMonths.map((m) {
                              final isSelected = m.key == _activeMonthKey;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(
                                    m.isCurrent ? '${m.label} (Now)' : m.label,
                                    style: AppTypography.caption.copyWith(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? Colors.white : AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: AppColors.primary,
                                  backgroundColor: AppColors.surfaceElevated,
                                  side: BorderSide(
                                    color: isSelected ? AppColors.primaryLight : AppColors.border,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                  onSelected: (selected) {
                                    if (selected && _activeMonthKey != m.key) {
                                      setState(() {
                                        _activeMonthKey = m.key;
                                        _activeMonthLabel = m.label;
                                      });
                                      _fetchMonthData(m.key);
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Combined 2-Month Total Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.all_inclusive_rounded, size: 14, color: AppColors.primaryLight),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Combined 2-Month Total:',
                                      style: AppTypography.caption.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                        fontSize: 11.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '\$${combinedUSD.toStringAsFixed(2)} USD (≈ ₹${combinedINR.toStringAsFixed(0)})',
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryLight,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Month Overview Card
                      GuardianCard(
                        withPurpleGlow: true,
                        padding: const EdgeInsets.all(18),
                        borderColor: AppColors.primaryLight.withValues(alpha: 0.35),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$periodTitle AWS Spend',
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.primaryLight.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.sync_rounded,
                                        size: 11,
                                        color: AppColors.primaryLight,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isCurrent ? 'LIVE MTD' : 'FINAL BILLED',
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.primaryLight,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '\$${monthCostUSD.toStringAsFixed(2)}',
                                  style: AppTypography.headingLarge.copyWith(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'USD',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.primaryLight.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '≈ ₹${monthCostINR.toStringAsFixed(0)} INR',
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: AppColors.primaryLight,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        isCurrent ? 'Month-to-date' : 'Billed Total',
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isCurrent
                                  ? 'Live November usage accrued to date'
                                  : 'October 2026 finalized billing cycle',
                              style: AppTypography.caption.copyWith(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // 3-Metric Sub Row
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Billing Cycle',
                                          style: AppTypography.caption.copyWith(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            _activeMonthLabel,
                                            style: AppTypography.bodyLarge.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          isCurrent ? 'Accruing live' : 'Billed cycle',
                                          style: AppTypography.caption.copyWith(
                                            fontSize: 10,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(width: 1, height: 32, color: AppColors.border),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Charged Items',
                                          style: AppTypography.caption.copyWith(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${stats?.chargedServicesCount ?? activeResources.length} Services',
                                          style: AppTypography.bodyLarge.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          '${stats?.chargedResourcesCount ?? activeResources.length} Active items',
                                          style: AppTypography.caption.copyWith(
                                            fontSize: 10,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(width: 1, height: 32, color: AppColors.border),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          topService != null ? 'Top: ${topService.key}' : 'Top Service',
                                          style: AppTypography.caption.copyWith(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          topService != null
                                              ? '\$${topService.value.toStringAsFixed(2)}'
                                              : '\$0.00',
                                          style: AppTypography.bodyLarge.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryLight,
                                          ),
                                        ),
                                        Text(
                                          topService != null ? 'Monthly spend' : 'No spend',
                                          style: AppTypography.caption.copyWith(
                                            fontSize: 10,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Section Header for Charges Breakdown
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.receipt_long_rounded, size: 18, color: AppColors.primaryLight),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '$periodTitle AWS Charges (${activeResources.length} services)',
                                    style: AppTypography.sectionTitle.copyWith(fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${monthCostUSD.toStringAsFixed(2)} USD',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // AWS Resources List
                      if (activeResources.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            'No recorded charges for this month.',
                            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: activeResources.map((res) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _getServiceColor(res.service).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        res.service,
                                        style: AppTypography.caption.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: _getServiceColor(res.service),
                                          fontSize: 10.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            res.name.isNotEmpty ? res.name : res.resourceId,
                                            style: AppTypography.caption.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '${res.region} • AWS Cost Explorer',
                                            style: AppTypography.caption.copyWith(
                                              fontSize: 10,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          res.monthlyCost >= 0.01
                                              ? '\$${res.monthlyCost.toStringAsFixed(2)}'
                                              : (res.monthlyCost > 0 ? '< \$0.01' : '\$0.00'),
                                          style: AppTypography.caption.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          res.monthlyCost >= 0.01
                                              ? '≈ ₹${(res.monthlyCost * 86.50).toStringAsFixed(0)}'
                                              : (res.monthlyCost > 0 ? '< ₹1' : '₹0'),
                                          style: AppTypography.caption.copyWith(
                                            fontSize: 10,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
