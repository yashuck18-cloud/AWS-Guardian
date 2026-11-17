import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/aws_regions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/toast.dart';
import '../../../shared/widgets/guardian_button.dart';
import '../../../shared/widgets/guardian_text_field.dart';
import '../../../shared/widgets/guardian_card.dart';
import '../../../shared/widgets/aws_region_picker_modal.dart';
import '../providers/aws_accounts_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../resources/providers/resources_provider.dart';

class ConnectAccountScreen extends ConsumerStatefulWidget {
  const ConnectAccountScreen({super.key});

  @override
  ConsumerState<ConnectAccountScreen> createState() => _ConnectAccountScreenState();
}

class _ConnectAccountScreenState extends ConsumerState<ConnectAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Production');
  final _accountIdController = TextEditingController();
  final _roleArnController = TextEditingController();
  final _regionController = TextEditingController(text: 'all');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final accounts = ref.read(awsAccountsProvider).accounts;
    if (accounts.isNotEmpty) {
      final acc = accounts.first;
      _accountIdController.text = acc.accountId;
      _roleArnController.text = acc.roleArn;
      _nameController.text = acc.name;
    } else {
      _accountIdController.text = '713863946092';
      _roleArnController.text = 'arn:aws:iam::713863946092:role/AWSGuardianReadOnlyRole';
      _regionController.text = 'ap-south-1';
    }

    _accountIdController.addListener(() {
      final acc = _accountIdController.text.trim();
      if (acc.length == 12) {
        final currentRole = _roleArnController.text.trim();
        if (currentRole.isEmpty || currentRole.contains('AWSGuardianReadOnlyRole') || currentRole.startsWith(':role/')) {
          _roleArnController.text = 'arn:aws:iam::$acc:role/AWSGuardianReadOnlyRole';
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountIdController.dispose();
    _roleArnController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  void _showRegionPickerSheet() {
    AwsRegionPickerModal.show(
      context,
      currentRegion: _regionController.text.trim(),
      onRegionSelected: (code) {
        setState(() {
          _regionController.text = code;
        });
      },
    );
  }

  Future<void> _handleConnect() async {
    // Auto-normalize role ARN before validating and submitting
    final rawAcc = _accountIdController.text.trim();
    var roleArn = _roleArnController.text.trim();
    if (roleArn.isNotEmpty && !roleArn.startsWith('arn:aws:iam::')) {
      if (roleArn.startsWith(':role/')) {
        roleArn = 'arn:aws:iam::$rawAcc$roleArn';
      } else if (roleArn.startsWith('role/')) {
        roleArn = 'arn:aws:iam::$rawAcc:$roleArn';
      } else if (roleArn.startsWith('/')) {
        roleArn = 'arn:aws:iam::$rawAcc:role$roleArn';
      } else {
        roleArn = 'arn:aws:iam::$rawAcc:role/$roleArn';
      }
      _roleArnController.text = roleArn;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final notifier = ref.read(awsAccountsProvider.notifier);

    final rawRegion = _regionController.text.trim().toLowerCase();
    final List<String> enabledRegions = (rawRegion.isEmpty || rawRegion == 'all')
        ? ['all', 'ap-south-1', 'us-east-1', 'us-east-2', 'us-west-2', 'eu-west-1', 'ap-southeast-1']
        : [rawRegion];

    final success = await notifier.connectAccount(
      name: _nameController.text.trim(),
      accountId: _accountIdController.text.trim(),
      roleArn: _roleArnController.text.trim(),
      enabledRegions: enabledRegions,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (success) {
      Toast.showSuccess(context, 'AWS Account Connected & Verified ✓ All Resources Discovered');
      final newSelected = ref.read(awsAccountsProvider).selectedAccount;
      if (newSelected != null) {
        ref.read(resourcesProvider.notifier).setAccount(newSelected.id, forceReload: true);
        ref.read(resourcesProvider.notifier).fetchResources(forceReload: true);
        ref.read(dashboardProvider.notifier).fetchDashboardStats(accountId: newSelected.id);
      }
      context.go('/resources');
    } else {
      final err = ref.read(awsAccountsProvider).errorMessage ??
          'Failed to verify IAM Role connection. Please review Trust Policy in AWS.';
      _showErrorBottomSheet(err);
    }
  }

  String _generateTrustPolicyJson() {
    return '{\n'
        '  "Version": "2012-10-17",\n'
        '  "Statement": [\n'
        '    {\n'
        '      "Effect": "Allow",\n'
        '      "Principal": {\n'
        '        "AWS": "arn:aws:iam::${ApiConstants.guardianAwsAccountId}:root"\n'
        '      },\n'
        '      "Action": "sts:AssumeRole"\n'
        '    }\n'
        '  ]\n'
        '}';
  }

  void _showErrorBottomSheet(String error) {
    final isAccessDenied = error.toLowerCase().contains('access denied') ||
        error.toLowerCase().contains('trust policy');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.critical, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Verification Failed', style: AppTypography.headingMedium),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.critical.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.critical.withValues(alpha: 0.3)),
                  ),
                  child: Text(error, style: AppTypography.caption.copyWith(color: AppColors.textPrimary, height: 1.4)),
                ),
                if (isAccessDenied) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Fix: Update IAM Trust Policy',
                          style: AppTypography.sectionTitle.copyWith(fontSize: 13, color: AppColors.primaryLight),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '1. In AWS Console, go to IAM > Roles > (your role)\n'
                          '2. Click "Trust relationships" > "Edit trust policy"\n'
                          '3. Paste the correct JSON below and Save changes',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GuardianButton(
                    label: 'Copy Correct Trust Policy JSON',
                    variant: ButtonVariant.primary,
                    icon: Icons.copy_rounded,
                    width: double.infinity,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _generateTrustPolicyJson()));
                      Toast.showSuccess(ctx, 'Trust Policy JSON copied to clipboard!');
                    },
                  ),
                ],
                const SizedBox(height: 12),
                GuardianButton(
                  label: 'View Full IAM Instructions',
                  variant: ButtonVariant.outlined,
                  width: double.infinity,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.push('/iam-instructions');
                  },
                ),
                const SizedBox(height: 8),
                GuardianButton(
                  label: 'Close',
                  variant: ButtonVariant.secondary,
                  width: double.infinity,
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Connect AWS Account', style: AppTypography.headingMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => context.push('/iam-instructions'),
            child: Text('Guide', style: AppTypography.bodyMedium.copyWith(color: AppColors.primaryLight)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Security Notice Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_rounded, color: AppColors.primaryLight, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Zero Secret Storage: AWS Guardian uses AWS STS AssumeRole. We never ask for or store permanent AWS access keys.',
                          style: AppTypography.caption.copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Auto-Fill for My Production Account
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flash_on_rounded, color: Color(0xFF10B981), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Quick Preset: Production (713863946092)', style: AppTypography.label.copyWith(fontSize: 13, color: AppColors.textPrimary)),
                            Text('Role: AWSGuardianReadOnlyRole', style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11)),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _nameController.text = 'Production';
                            _accountIdController.text = '713863946092';
                            _roleArnController.text = 'arn:aws:iam::713863946092:role/AWSGuardianReadOnlyRole';
                            _regionController.text = 'ap-south-1';
                          });
                          Toast.showSuccess(context, 'Filled 713863946092 details');
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF10B981)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Auto-Fill', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Step 1
                Text('Step 1: Account Details', style: AppTypography.sectionTitle),
                const SizedBox(height: 12),
                GuardianTextField(
                  controller: _nameController,
                  labelText: 'Account Label (Friendly Name)',
                  hintText: 'e.g. Production / Staging / Dev',
                  helperText: 'A friendly nickname to identify this account across the app (e.g. Production, Staging)',
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Account name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                GuardianTextField(
                  controller: _accountIdController,
                  labelText: 'AWS Account ID (12 digits)',
                  hintText: '123456789012',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.numbers_rounded, size: 20, color: AppColors.textMuted),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Account ID is required';
                    if (val.trim().length != 12 || !RegExp(r'^\d+$').hasMatch(val.trim())) {
                      return 'Must be exactly 12 numeric digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Step 2
                Text('Step 2: IAM Trust Delegation (Cross-Account)', style: AppTypography.sectionTitle),
                const SizedBox(height: 8),
                Text(
                  'Your IAM Role must allow AWS Guardian to assume it. Enter Guardian\'s Account ID in your IAM role trust policy.',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 12),

                // Card 1: Guardian AWS Account ID to trust
                GuardianCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  backgroundColor: AppColors.surfaceElevated,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.shield_outlined, size: 18, color: AppColors.primaryLight),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Guardian Account to Trust ("Another AWS account")',
                              style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ApiConstants.guardianAwsAccountId,
                              style: AppTypography.code.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy Guardian Account ID',
                        icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primaryLight),
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: ApiConstants.guardianAwsAccountId));
                          Toast.showSuccess(context, 'Guardian Account ID (662371887384) copied');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Quick copy full JSON button
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _generateTrustPolicyJson()));
                    Toast.showSuccess(context, 'Ready-to-paste Trust Policy JSON copied!');
                  },
                  icon: const Icon(Icons.code_rounded, size: 16, color: AppColors.primaryLight),
                  label: Text(
                    'Copy Ready-to-Paste Trust Policy JSON',
                    style: AppTypography.label.copyWith(color: AppColors.primaryLight, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primaryLight.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  ),
                ),
                const SizedBox(height: 24),

                // Step 3
                Text('Step 3: IAM Role ARN', style: AppTypography.sectionTitle),
                const SizedBox(height: 12),
                GuardianTextField(
                  controller: _roleArnController,
                  labelText: 'Role ARN',
                  hintText: 'arn:aws:iam::713863946092:role/AWSGuardianReadOnlyRole',
                  prefixIcon: const Icon(Icons.vpn_key_rounded, size: 20, color: AppColors.textMuted),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Role ARN is required';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Step 4
                Text('Step 4: AWS Region', style: AppTypography.sectionTitle),
                const SizedBox(height: 8),
                Text(
                  'Select the AWS region to monitor. Guardian will strictly scan and display only resources in this region.',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 12),

                // AWS Console Style Region Selector Card
                InkWell(
                  onTap: _showRegionPickerSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00A4E4).withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A4E4).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.public_rounded, color: Color(0xFF00A4E4), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AwsRegions.getName(_regionController.text.trim()),
                                style: const TextStyle(
                                  color: Color(0xFF00A4E4),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Region Code: ${_regionController.text.trim()}',
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E293B),
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            border: Border.fromBorderSide(BorderSide(color: Color(0xFF334155))),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Change',
                                style: TextStyle(
                                  color: Color(0xFF00A4E4),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF00A4E4)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                GuardianButton(
                  label: 'Verify Connection',
                  width: double.infinity,
                  isLoading: _isLoading,
                  onPressed: _handleConnect,
                ),
                const SizedBox(height: 16),

                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.menu_book_rounded, size: 18),
                    label: const Text('Read IAM Setup Instructions'),
                    onPressed: () => context.push('/iam-instructions'),
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
