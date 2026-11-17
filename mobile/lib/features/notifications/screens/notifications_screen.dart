import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/toast.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/guardian_card.dart';
import '../../../shared/widgets/guardian_button.dart';
import '../../../shared/widgets/guardian_badge.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _isTriggering = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).fetchNotifications();
    });
  }

  Future<void> _handleTriggerSummary() async {
    setState(() => _isTriggering = true);
    final success =
        await ref.read(notificationsProvider.notifier).triggerManualSummary();
    if (!mounted) return;
    setState(() => _isTriggering = false);

    if (success) {
      Toast.showSuccess(context, 'Manual summary dispatched successfully.');
    } else {
      Toast.showError(context, 'Failed to dispatch summary notification.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Notifications',
        showBack: true,
        actions: [
          IconButton(
            onPressed: () {
              ref.read(notificationsProvider.notifier).fetchNotifications();
            },
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary, size: 20),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight),
            )
          : RefreshIndicator(
              color: AppColors.primaryLight,
              backgroundColor: AppColors.surfaceElevated,
              onRefresh: () async {
                await ref.read(notificationsProvider.notifier).fetchNotifications();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Manual Trigger Card with Purple Glow
                    GuardianCard(
                      withPurpleGlow: true,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(75),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Instant Alert Digest',
                                  style: AppTypography.sectionTitle.copyWith(fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Dispatch active summary on-demand',
                                  style: AppTypography.caption.copyWith(fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GuardianButton(
                            label: 'Send Now',
                            variant: ButtonVariant.primary,
                            isLoading: _isTriggering,
                            height: 36,
                            onPressed: _handleTriggerSummary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section Heading
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Notification History', style: AppTypography.headingMedium),
                        if (state.history.isNotEmpty)
                          Text(
                            '${state.history.length} dispatched',
                            style: AppTypography.caption.copyWith(color: AppColors.primaryLight),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (state.history.isEmpty)
                      const EmptyState(
                        icon: Icons.notifications_off_outlined,
                        title: 'No notifications sent yet',
                        description:
                            'Automated morning and evening summaries will appear here once scheduled or triggered.',
                      )
                    else
                      ListView.separated(
                        itemCount: state.history.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = state.history[index];
                          return GuardianCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row: Channel badge + Title (Expanded) + Status pill
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceElevated2,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Text(
                                        item.channel,
                                        style: AppTypography.label.copyWith(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: AppTypography.sectionTitle.copyWith(fontSize: 13.5),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GuardianBadge.status(item.status),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Message content
                                Text(
                                  item.message,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Footer timestamp
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      Formatters.timeAgo(item.createdAt),
                                      style: AppTypography.caption.copyWith(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.check_circle_outline, size: 12, color: AppColors.success),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Delivered',
                                          style: AppTypography.caption.copyWith(
                                            fontSize: 10.5,
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w600,
                                          ),
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
                  ],
                ),
              ),
            ),
    );
  }
}
