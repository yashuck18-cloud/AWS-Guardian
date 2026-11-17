import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/toast.dart';
import '../../../shared/widgets/guardian_card.dart';
import '../../../shared/widgets/guardian_badge.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/alerts_provider.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  final List<String> _severities = ['ALL', 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'];
  final List<String> _statuses = ['ACTIVE', 'ACKNOWLEDGED', 'RESOLVED', 'ALL'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(alertsProvider.notifier).fetchAlerts();
    });
  }

  Future<void> _handleAcknowledge(String alertId) async {
    final success = await ref.read(alertsProvider.notifier).acknowledgeAlert(alertId);
    if (mounted) {
      if (success) {
        Toast.showSuccess(context, 'Alert acknowledged');
      } else {
        Toast.showError(context, 'Failed to acknowledge alert');
      }
    }
  }

  Future<void> _handleResolve(String alertId) async {
    final success = await ref.read(alertsProvider.notifier).resolveAlert(alertId);
    if (mounted) {
      if (success) {
        Toast.showSuccess(context, 'Alert marked as resolved');
      } else {
        Toast.showError(context, 'Failed to resolve alert');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertsState = ref.watch(alertsProvider);
    final currentSeverity = alertsState.filter.severity;
    final currentStatus = alertsState.filter.status;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Security Findings', style: AppTypography.headingMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary, size: 20),
            onPressed: () => ref.read(alertsProvider.notifier).fetchAlerts(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status Tabs Horizontal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: _statuses.map((st) {
                  final isSelected = currentStatus == st;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(alertsProvider.notifier).updateStatus(st);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryLight : AppColors.border,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withAlpha(75),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          st,
                          textAlign: TextAlign.center,
                          style: AppTypography.label.copyWith(
                            fontSize: 10.5,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Severity Filter Chips
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _severities.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final sev = _severities[index];
                  final isSelected = currentSeverity == sev;

                  return ChoiceChip(
                    label: Text(sev),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withAlpha(50),
                    backgroundColor: AppColors.surfaceElevated,
                    side: BorderSide(
                      color: isSelected ? AppColors.primaryLight : AppColors.border,
                    ),
                    labelStyle: AppTypography.label.copyWith(
                      color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 11,
                    ),
                    onSelected: (val) {
                      ref.read(alertsProvider.notifier).updateSeverity(sev);
                    },
                  );
                },
              ),
            ),
            // Subtle Background Refresh Indicator
            if (alertsState.isRefreshing)
              const LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
              ),

            // Alerts List
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryLight,
                backgroundColor: AppColors.surfaceElevated,
                onRefresh: () => ref.read(alertsProvider.notifier).fetchAlerts(forceReload: true),
                child: alertsState.isLoading && alertsState.alerts.isEmpty
                    ? const ListSkeletonLoader(count: 4)
                    : alertsState.alerts.isEmpty
                        ? const EmptyState(
                            icon: Icons.check_circle_outline_rounded,
                            title: 'You\'re all clear 🎉',
                            description: 'No active alerts or cost waste findings matching your filter criteria.',
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.all(16),
                            itemCount: alertsState.alerts.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final alert = alertsState.alerts[index];
                              return GuardianCard(
                                onTap: () => context.push('/alerts/${alert.id}'),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        GuardianBadge.severity(alert.severity),
                                        Text(
                                          Formatters.timeAgo(alert.lastDetectedAt),
                                          style: AppTypography.caption,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      alert.title,
                                      style: AppTypography.sectionTitle.copyWith(fontSize: 15),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      alert.description,
                                      style: AppTypography.bodyMedium.copyWith(fontSize: 12.5),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(color: AppColors.border, height: 1),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              if (alert.resourceService.isNotEmpty) ...[
                                                GuardianBadge.service(alert.resourceService),
                                                const SizedBox(width: 8),
                                              ],
                                              Expanded(
                                                child: Text(
                                                  alert.resourceName.isNotEmpty
                                                      ? alert.resourceName
                                                      : alert.resourceIdStr,
                                                  style: AppTypography.caption.copyWith(
                                                    color: AppColors.textSecondary,
                                                    fontFamily: 'monospace',
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (alert.isActive)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                                                color: AppColors.textSecondary,
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                onPressed: () => _handleAcknowledge(alert.id),
                                                tooltip: 'Acknowledge',
                                              ),
                                              const SizedBox(width: 10),
                                              IconButton(
                                                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                                                color: AppColors.success,
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                onPressed: () => _handleResolve(alert.id),
                                                tooltip: 'Resolve',
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
          ],
        ),
      ),
    );
  }
}
