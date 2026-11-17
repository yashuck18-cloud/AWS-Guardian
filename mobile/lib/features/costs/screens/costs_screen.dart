import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/guardian_card.dart';
import '../../../shared/widgets/guardian_badge.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../analytics/providers/analytics_provider.dart';
import '../../aws_accounts/providers/aws_accounts_provider.dart';

class CostsScreen extends ConsumerStatefulWidget {
  const CostsScreen({super.key});

  @override
  ConsumerState<CostsScreen> createState() => _CostsScreenState();
}

class _CostsScreenState extends ConsumerState<CostsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selected = ref.read(awsAccountsProvider).selectedAccount;
      ref.read(analyticsProvider.notifier).fetchAnalyticsData(accountId: selected?.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsProvider);
    final costData = state.costData;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Costs & Spend Impact', style: AppTypography.headingMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryLight,
          backgroundColor: AppColors.surfaceElevated,
          onRefresh: () {
            final selected = ref.read(awsAccountsProvider).selectedAccount;
            return ref.read(analyticsProvider.notifier).fetchAnalyticsData(accountId: selected?.id);
          },
          child: state.isLoading
              ? const ListSkeletonLoader(count: 3)
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Transparency Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Estimated Cost Model',
                                    style: AppTypography.sectionTitle.copyWith(color: AppColors.info, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    costData.actualBillingMessage.isNotEmpty
                                        ? costData.actualBillingMessage
                                        : 'AWS Guardian estimates cost impact using hourly standard AWS instance rates. Exact AWS billing data requires AWS Cost Explorer permissions.',
                                    style: AppTypography.caption.copyWith(color: AppColors.textPrimary, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Monthly Total Card
                      GuardianCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estimated Monthly Spend',
                              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              Formatters.currency(costData.estimatedMonthlyTotal),
                              style: AppTypography.displayMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Potential Idle Waste', style: AppTypography.caption),
                                    const SizedBox(height: 4),
                                    Text(
                                      Formatters.currency(costData.estimatedMonthlyPotentialWaste),
                                      style: AppTypography.headingMedium.copyWith(
                                        color: costData.estimatedMonthlyPotentialWaste > 0
                                            ? AppColors.warning
                                            : AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    costData.estimatedMonthlyPotentialWaste > 0 ? 'Action Needed' : 'Optimized',
                                    style: AppTypography.label.copyWith(
                                      color: costData.estimatedMonthlyPotentialWaste > 0
                                          ? AppColors.warning
                                          : AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Breakdown by Service
                      Text('Monthly Cost by Service', style: AppTypography.sectionTitle),
                      const SizedBox(height: 12),
                      if (costData.serviceBreakdown.isEmpty)
                        GuardianCard(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'No active resources incurring estimated charges.',
                              style: AppTypography.bodyMedium,
                            ),
                          ),
                        )
                      else
                        GuardianCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: costData.serviceBreakdown.entries.map((e) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    GuardianBadge.service(e.key),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        e.key,
                                        style: AppTypography.sectionTitle,
                                      ),
                                    ),
                                    Text(
                                      '${Formatters.currency(e.value)} / mo',
                                      style: AppTypography.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
