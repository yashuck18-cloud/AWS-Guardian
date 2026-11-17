import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/toast.dart';
import '../../../shared/widgets/guardian_card.dart';
import '../../../shared/widgets/guardian_badge.dart';
import '../../../shared/widgets/guardian_button.dart';
import '../providers/alerts_provider.dart';

class AlertDetailsScreen extends ConsumerStatefulWidget {
  final String alertId;
  const AlertDetailsScreen({super.key, required this.alertId});

  @override
  ConsumerState<AlertDetailsScreen> createState() => _AlertDetailsScreenState();
}

class _AlertDetailsScreenState extends ConsumerState<AlertDetailsScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(alertsProvider).alerts.isEmpty) {
        ref.read(alertsProvider.notifier).fetchAlerts();
      }
    });
  }

  Future<void> _handleAcknowledge(String id) async {
    setState(() => _isLoading = true);
    final success = await ref.read(alertsProvider.notifier).acknowledgeAlert(id);
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (success) {
      Toast.showSuccess(context, 'Alert acknowledged');
    } else {
      Toast.showError(context, 'Failed to acknowledge alert');
    }
  }

  Future<void> _handleResolve(String id) async {
    setState(() => _isLoading = true);
    final success = await ref.read(alertsProvider.notifier).resolveAlert(id);
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (success) {
      Toast.showSuccess(context, 'Alert resolved');
    } else {
      Toast.showError(context, 'Failed to resolve alert');
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertsState = ref.watch(alertsProvider);
    final alertMatches = alertsState.alerts.where((a) => a.id == widget.alertId).toList();
    final alert = alertMatches.isNotEmpty
        ? alertMatches.first
        : (alertsState.alerts.isNotEmpty ? alertsState.alerts.first : null);

    if (alert == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Alert Details', style: AppTypography.headingMedium),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => context.canPop() ? context.pop() : context.go('/alerts'),
          ),
        ),
        body: Center(
          child: alertsState.isLoading
              ? const CircularProgressIndicator(color: AppColors.primary)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 48, color: AppColors.warning),
                    const SizedBox(height: 16),
                    Text('Loading alert details...', style: AppTypography.bodyMedium),
                    const SizedBox(height: 16),
                    GuardianButton(
                      label: 'View All Alerts',
                      onPressed: () => context.go('/alerts'),
                    ),
                  ],
                ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Alert Details', style: AppTypography.headingMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.canPop() ? context.pop() : context.go('/alerts'),
        ),
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
                        GuardianBadge.severity(alert.severity),
                        GuardianBadge.status(alert.status),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      alert.title,
                      style: AppTypography.headingLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      alert.description,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildDetailRow('First Detected', Formatters.formatDateTime(alert.firstDetectedAt)),
                    const SizedBox(height: 10),
                    _buildDetailRow('Last Detected', Formatters.formatDateTime(alert.lastDetectedAt)),
                    if (alert.resolvedAt != null) ...[
                      const SizedBox(height: 10),
                      _buildDetailRow('Resolved On', Formatters.formatDateTime(alert.resolvedAt)),
                    ],
                    if (alert.estimatedCostImpact > 0) ...[
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        'Est. Monthly Impact',
                        '${Formatters.currency(alert.estimatedCostImpact)} / mo',
                        isHighlighted: true,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Associated Resource Card
              Text('Associated Resource', style: AppTypography.sectionTitle),
              const SizedBox(height: 12),
              GuardianCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (alert.resourceService.isNotEmpty) ...[
                      GuardianBadge.service(alert.resourceService),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.resourceName.isNotEmpty ? alert.resourceName : alert.resourceIdStr,
                            style: AppTypography.sectionTitle,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            alert.resourceIdStr,
                            style: AppTypography.code.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (alert.resource != null)
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primaryLight),
                        onPressed: () => context.push('/resources/${alert.resource!.id}'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              if (alert.resource != null) ...[
                GuardianButton(
                  label: 'View Resource Details',
                  variant: ButtonVariant.outlined,
                  width: double.infinity,
                  icon: Icons.inventory_2_outlined,
                  onPressed: () => context.push('/resources/${alert.resource!.id}'),
                ),
                const SizedBox(height: 12),
              ],

              if (alert.isActive) ...[
                GuardianButton(
                  label: 'Acknowledge Alert',
                  variant: ButtonVariant.secondary,
                  width: double.infinity,
                  isLoading: _isLoading,
                  icon: Icons.remove_red_eye_outlined,
                  onPressed: () => _handleAcknowledge(alert.id),
                ),
                const SizedBox(height: 12),
                GuardianButton(
                  label: 'Mark as Resolved',
                  variant: ButtonVariant.primary,
                  width: double.infinity,
                  isLoading: _isLoading,
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: () => _handleResolve(alert.id),
                ),
              ] else if (alert.isAcknowledged) ...[
                GuardianButton(
                  label: 'Mark as Resolved',
                  variant: ButtonVariant.primary,
                  width: double.infinity,
                  isLoading: _isLoading,
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: () => _handleResolve(alert.id),
                ),
              ],
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
        Text(label, style: AppTypography.caption),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: isHighlighted ? AppColors.warning : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
