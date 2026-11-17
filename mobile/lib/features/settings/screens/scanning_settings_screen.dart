import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/toast.dart';
import '../../../shared/widgets/guardian_card.dart';
import '../../../shared/widgets/guardian_button.dart';
import '../../auth/providers/auth_provider.dart';

class ScanningSettingsScreen extends ConsumerStatefulWidget {
  const ScanningSettingsScreen({super.key});

  @override
  ConsumerState<ScanningSettingsScreen> createState() => _ScanningSettingsScreenState();
}

class _ScanningSettingsScreenState extends ConsumerState<ScanningSettingsScreen> {
  int _scanInterval = 12;
  int _ec2Threshold = 24;
  int _ebsThreshold = 24;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) {
      _scanInterval = user.scanIntervalHours;
      _ec2Threshold = user.ec2ThresholdHours;
      _ebsThreshold = user.ebsThresholdHours;
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);
    final success = await ref.read(authProvider.notifier).updateProfile({
      'scan_interval_hours': _scanInterval,
      'ec2_threshold_hours': _ec2Threshold,
      'ebs_threshold_hours': _ebsThreshold,
    });
    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Toast.showSuccess(context, 'Scanning thresholds updated');
      } else {
        Toast.showError(context, 'Failed to update thresholds');
      }
    }
  }

  Widget _buildSelectionGrid({
    required List<Map<String, dynamic>> options,
    required int currentValue,
    required ValueChanged<int> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final val = opt['value'] as int;
        final label = opt['label'] as String;
        final isSelected = currentValue == val;

        return InkWell(
          onTap: () => onSelected(val),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.surfaceElevated2 : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primaryLight : AppColors.border,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? AppColors.primaryLight : AppColors.textMuted,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Scanning Settings', style: AppTypography.headingMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Automatic Scan Frequency', style: AppTypography.sectionTitle),
              const SizedBox(height: 6),
              Text(
                'How often AWS Guardian performs automated inspection of your cloud accounts.',
                style: AppTypography.caption,
              ),
              const SizedBox(height: 12),
              GuardianCard(
                padding: const EdgeInsets.all(16),
                child: _buildSelectionGrid(
                  options: const [
                    {'value': 6, 'label': 'Every 6 hours'},
                    {'value': 12, 'label': 'Every 12 hours'},
                    {'value': 24, 'label': 'Every 24 hours'},
                  ],
                  currentValue: _scanInterval,
                  onSelected: (val) => setState(() => _scanInterval = val),
                ),
              ),
              const SizedBox(height: 24),

              Text('EC2 Idle Runtime Threshold', style: AppTypography.sectionTitle),
              const SizedBox(height: 6),
              Text(
                'Flag EC2 instances running continuously beyond this threshold.',
                style: AppTypography.caption,
              ),
              const SizedBox(height: 12),
              GuardianCard(
                padding: const EdgeInsets.all(16),
                child: _buildSelectionGrid(
                  options: const [
                    {'value': 12, 'label': '12 hours'},
                    {'value': 24, 'label': '24 hours'},
                    {'value': 48, 'label': '48 hours'},
                    {'value': 168, 'label': '7 days (168h)'},
                  ],
                  currentValue: _ec2Threshold,
                  onSelected: (val) => setState(() => _ec2Threshold = val),
                ),
              ),
              const SizedBox(height: 24),

              Text('EBS Detached Threshold', style: AppTypography.sectionTitle),
              const SizedBox(height: 6),
              Text(
                'Flag unattached EBS volumes unassociated with an active EC2 instance.',
                style: AppTypography.caption,
              ),
              const SizedBox(height: 12),
              GuardianCard(
                padding: const EdgeInsets.all(16),
                child: _buildSelectionGrid(
                  options: const [
                    {'value': 12, 'label': '12 hours'},
                    {'value': 24, 'label': '24 hours'},
                    {'value': 48, 'label': '48 hours'},
                  ],
                  currentValue: _ebsThreshold,
                  onSelected: (val) => setState(() => _ebsThreshold = val),
                ),
              ),
              const SizedBox(height: 32),

              GuardianButton(
                label: 'Save Scanning Preferences',
                width: double.infinity,
                isLoading: _isLoading,
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
