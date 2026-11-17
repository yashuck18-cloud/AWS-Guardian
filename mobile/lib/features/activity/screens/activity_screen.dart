import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/guardian_card.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/activity_provider.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activityProvider.notifier).fetchAuditLogs();
    });
  }

  IconData _getActionIcon(String action) {
    if (action.contains('CONNECTED') || action.contains('VERIFIED')) {
      return Icons.cloud_done_rounded;
    } else if (action.contains('SCAN')) {
      return Icons.radar_rounded;
    } else if (action.contains('ALERT')) {
      return Icons.warning_amber_rounded;
    } else if (action.contains('STOPPED')) {
      return Icons.stop_circle_outlined;
    } else if (action.contains('DELETED')) {
      return Icons.delete_outline_rounded;
    } else if (action.contains('NOTIFICATION')) {
      return Icons.send_rounded;
    }
    return Icons.history_rounded;
  }

  Color _getActionColor(String action) {
    if (action.contains('CONNECTED') || action.contains('VERIFIED')) {
      return AppColors.success;
    } else if (action.contains('ALERT')) {
      return AppColors.warning;
    } else if (action.contains('STOPPED') || action.contains('DELETED')) {
      return AppColors.critical;
    } else if (action.contains('NOTIFICATION')) {
      return AppColors.info;
    }
    return AppColors.primaryLight;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activityProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Activity & Audit Trail', style: AppTypography.headingMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryLight,
          backgroundColor: AppColors.surfaceElevated,
          onRefresh: () => ref.read(activityProvider.notifier).fetchAuditLogs(),
          child: state.isLoading && state.logs.isEmpty
              ? const ListSkeletonLoader(count: 5)
              : state.logs.isEmpty
                  ? const EmptyState(
                      icon: Icons.history_rounded,
                      title: 'No activity recorded yet',
                      description: 'Actions such as scans, connections, and alert resolutions will appear in this timeline.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.logs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final log = state.logs[index];
                        final icon = _getActionIcon(log.action);
                        final color = _getActionColor(log.action);

                        return GuardianCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, size: 20, color: color),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      log.actionDisplay.isNotEmpty ? log.actionDisplay : log.action,
                                      style: AppTypography.sectionTitle,
                                    ),
                                    const SizedBox(height: 4),
                                    if (log.details.isNotEmpty)
                                      Text(
                                        log.details.entries.map((e) => '${e.key}: ${e.value}').join(' • '),
                                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    const SizedBox(height: 8),
                                    Text(
                                      Formatters.timeAgo(log.timestamp),
                                      style: AppTypography.caption,
                                    ),
                                  ],
                                ),
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
}
