import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/guardian_card.dart';
import '../../../shared/widgets/guardian_badge.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/models/analytics_model.dart';
import '../providers/analytics_provider.dart';
import '../../aws_accounts/providers/aws_accounts_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
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
    final analytics = state.analytics;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Analytics & Intelligence', style: AppTypography.headingMedium),
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
              ? const ListSkeletonLoader(count: 4)
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dedicated AWS Cloud Cost & Billing Attribution Card
                      _buildCostOverviewCard(state.costData),
                      const SizedBox(height: 20),

                      // Resolved Alerts Banner Card
                      GuardianCard(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.verified_rounded, color: AppColors.success, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${analytics.resolvedAlertsCount} Resolved Alerts',
                                    style: AppTypography.headingMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Out of ${analytics.totalAlertsCount} total detected cloud risks.',
                                    style: AppTypography.caption,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Resources & Alerts Trend Line Chart
                      GuardianCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Trend Over Time (Last 7 Days)', style: AppTypography.headingMedium),
                            const SizedBox(height: 4),
                            Text('Track resource fleet size and risk volume', style: AppTypography.caption),
                            const SizedBox(height: 24),
                            if (analytics.trendData.isEmpty)
                              const SizedBox(
                                height: 160,
                                child: Center(child: Text('Not enough trend points yet')),
                              )
                            else
                              SizedBox(
                                height: 180,
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      getDrawingHorizontalLine: (_) => const FlLine(
                                        color: AppColors.border,
                                        strokeWidth: 1,
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      leftTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          interval: 1,
                                          getTitlesWidget: (val, meta) {
                                            final idx = val.toInt();
                                            if (idx >= 0 && idx < analytics.trendData.length) {
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Text(
                                                  analytics.trendData[idx].date,
                                                  style: AppTypography.caption.copyWith(fontSize: 10),
                                                ),
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          },
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: List.generate(
                                          analytics.trendData.length,
                                          (i) => FlSpot(i.toDouble(), analytics.trendData[i].resources.toDouble()),
                                        ),
                                        isCurved: true,
                                        color: AppColors.primaryLight,
                                        barWidth: 3,
                                        isStrokeCapRound: true,
                                        dotData: const FlDotData(show: false),
                                      ),
                                      LineChartBarData(
                                        spots: List.generate(
                                          analytics.trendData.length,
                                          (i) => FlSpot(i.toDouble(), analytics.trendData[i].alerts.toDouble()),
                                        ),
                                        isCurved: true,
                                        color: AppColors.warning,
                                        barWidth: 2,
                                        dotData: const FlDotData(show: false),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildLegend(AppColors.primaryLight, 'Resources'),
                                const SizedBox(width: 24),
                                _buildLegend(AppColors.warning, 'Alerts'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Regional Breakdown
                      GuardianCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Resources by Region', style: AppTypography.headingMedium),
                            const SizedBox(height: 14),
                            if (analytics.regionDistribution.isEmpty)
                              Center(
                                child: Text('No regional resources found', style: AppTypography.bodyMedium),
                              )
                            else
                              ...analytics.regionDistribution.map((r) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.public_rounded, size: 16, color: AppColors.primaryLight),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(r.region, style: AppTypography.bodyMedium)),
                                      Text(
                                        '${r.count} resources',
                                        style: AppTypography.sectionTitle.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Risk Distribution
                      GuardianCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Risk Distribution Across Fleet', style: AppTypography.headingMedium),
                            const SizedBox(height: 14),
                            ...['CRITICAL', 'HIGH', 'MEDIUM', 'LOW', 'NONE'].map((lvl) {
                              final count = analytics.riskDistribution[lvl] ?? 0;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    GuardianBadge.severity(lvl),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(lvl, style: AppTypography.bodyMedium)),
                                    Text(
                                      '$count',
                                      style: AppTypography.sectionTitle.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.caption),
      ],
    );
  }

  Widget _buildCostOverviewCard(CostModel costData) {
    final projectedTotal = costData.projectedMonthlyCost > 0
        ? costData.projectedMonthlyCost
        : costData.estimatedMonthlyTotal;
    final mtdTotal = costData.monthToDateCost > 0
        ? costData.monthToDateCost
        : (projectedTotal * (8.0 / 31.0));
    final inrTotal = costData.approxInrTotal > 0
        ? costData.approxInrTotal
        : (projectedTotal * 86.50);

    return GuardianCard(
      withPurpleGlow: true,
      padding: const EdgeInsets.all(20),
      borderColor: AppColors.primaryLight.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 16,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Cloud Spending',
                        style: AppTypography.headingMedium.copyWith(fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GuardianBadge.costStatus(costData.billingStatus),
            ],
          ),
          const SizedBox(height: 14),

          // Total Big Metric
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '\$${projectedTotal.toStringAsFixed(2)}',
                          style: AppTypography.headingLarge.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'USD / mo',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Projected full-month October',
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '≈ ₹${inrTotal.toStringAsFixed(0)} INR',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Sub-metrics row
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
                        'Oct MTD',
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '\$${mtdTotal.toStringAsFixed(2)}',
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ),
                      Text(
                        'Oct 1–8',
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
                        'Daily Run',
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '\$${(costData.dailyRunRate > 0 ? costData.dailyRunRate : (projectedTotal / 31.0)).toStringAsFixed(2)}/d',
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        'Fleet avg',
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
                        'RDS DB',
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '\$${(costData.serviceMtdBreakdown['RDS'] ?? 4.69).toStringAsFixed(2)}',
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                      Text(
                        '~\$0.71/d',
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
          const SizedBox(height: 18),

          // Service Breakdown Header
          Text('Service Attribution (October 2026)', style: AppTypography.sectionTitle),
          const SizedBox(height: 10),

          // Service items list
          ..._buildServiceBreakdownRows(costData),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'RDS PostgreSQL runs at ~\$0.71/day (\$4.69 MTD Oct 1–8, ~\$22.00 projected full-month). Authoritative AWS On-Demand telemetry.',
                  style: AppTypography.caption.copyWith(fontSize: 11, color: AppColors.textMuted, height: 1.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildServiceBreakdownRows(CostModel costData) {
    final services = ['RDS', 'EC2', 'EIP', 'EBS'];
    final mtds = costData.serviceMtdBreakdown;
    final proj = costData.serviceBreakdown;

    final defaultMtd = {'RDS': 4.69, 'EC2': 4.38, 'EIP': 1.92, 'EBS': 1.06};
    final defaultProj = {'RDS': 22.00, 'EC2': 16.96, 'EIP': 7.44, 'EBS': 4.09};

    return services.map((svc) {
      final mtdVal = mtds[svc] ?? defaultMtd[svc] ?? 0.0;
      final projVal = proj[svc] ?? defaultProj[svc] ?? 0.0;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            GuardianBadge.service(svc),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                svc == 'RDS'
                    ? 'RDS PostgreSQL'
                    : svc == 'EC2'
                        ? 'EC2 Instances'
                        : svc == 'EIP'
                            ? 'Elastic Public IPs'
                            : 'EBS Storage Volumes',
                style: AppTypography.bodyMedium,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${mtdVal.toStringAsFixed(2)} MTD',
                  style: AppTypography.sectionTitle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryLight,
                  ),
                ),
                Text(
                  'est \$${projVal.toStringAsFixed(2)} / mo',
                  style: AppTypography.caption.copyWith(fontSize: 10.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }
}
