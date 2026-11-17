import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/toast.dart';
import '../../../shared/widgets/guardian_card.dart';
import '../../../shared/widgets/guardian_button.dart';

class IAMInstructionsScreen extends StatelessWidget {
  const IAMInstructionsScreen({super.key});

  static const String guardianAccountId = '662371887384';
  static const String guardianPrincipal = 'arn:aws:iam::662371887384:root';

  final String _trustPolicySample = '''{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::662371887384:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}''';

  final List<Map<String, String>> _steps = const [
    {
      'step': '1',
      'title': 'Open AWS IAM Console',
      'desc': 'Log in to your AWS Management Console and open the IAM service.',
    },
    {
      'step': '2',
      'title': 'Create New IAM Role',
      'desc': 'Go to Roles > Create role. Under Trusted entity type, choose "AWS account".',
    },
    {
      'step': '3',
      'title': 'Select "Another AWS account"',
      'desc': 'Under "An AWS account", select "Another AWS account" and enter Guardian Account ID: 662371887384.',
    },
    {
      'step': '4',
      'title': 'External ID (Leave Unchecked)',
      'desc': 'Leave "Require external ID" unchecked. Only entering your Account ID and Role ARN is needed.',
    },
    {
      'step': '5',
      'title': 'Attach Read-Only Permissions',
      'desc': 'Search and attach "SecurityAudit" or "ViewOnlyAccess". Guardian never asks for write or admin access.',
    },
    {
      'step': '6',
      'title': 'Name Your Role',
      'desc': 'Name the role "AWSGuardianReadOnlyRole" and click Create Role.',
    },
    {
      'step': '7',
      'title': 'Verify Trust Policy (Crucial)',
      'desc': 'Click your role > "Trust relationships" tab. Ensure Principal AWS is arn:aws:iam::662371887384:root.',
    },
    {
      'step': '8',
      'title': 'Copy Role ARN',
      'desc': 'Copy the Role ARN (e.g. arn:aws:iam::<your-account-id>:role/AWSGuardianReadOnlyRole).',
    },
    {
      'step': '9',
      'title': 'Return to AWS Guardian App',
      'desc': 'Paste your Account ID and Role ARN into the form and select your preferred AWS Region.',
    },
    {
      'step': '10',
      'title': 'Connect & Verify',
      'desc': 'Tap "Connect AWS Account". Guardian will verify STS delegation and instantly discover your cloud resources.',
    },
  ];

  Future<void> _openAwsConsole(BuildContext context) async {
    final uri = Uri.parse('https://console.aws.amazon.com/iamv2/home#/roles');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        Toast.showInfo(context, 'Please open https://console.aws.amazon.com in your browser');
      }
    } catch (_) {
      if (context.mounted) {
        Toast.showInfo(context, 'Please open https://console.aws.amazon.com in your browser');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('IAM Setup Instructions', style: AppTypography.headingMedium),
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
              Text(
                'How to connect your AWS Account',
                style: AppTypography.headingLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'AWS Guardian connects using AWS STS AssumeRole with read-only least-privilege permissions.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 20),

              // Guardian Account ID Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: AppColors.primaryLight, size: 20),
                        const SizedBox(width: 8),
                        Text('AWS Guardian Host Account ID', style: AppTypography.sectionTitle.copyWith(fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter this 12-digit ID under "Another AWS account" when creating your IAM Role in AWS Console:',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SelectableText(
                            guardianAccountId,
                            style: AppTypography.code.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryLight,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primaryLight),
                            tooltip: 'Copy Guardian Account ID',
                            onPressed: () {
                              Clipboard.setData(const ClipboardData(text: guardianAccountId));
                              Toast.showSuccess(context, 'Guardian Account ID (662371887384) copied!');
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Trust Policy Code snippet
              GuardianCard(
                padding: const EdgeInsets.all(16),
                backgroundColor: AppColors.surfaceElevated,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Custom Trust Policy JSON', style: AppTypography.sectionTitle),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primaryLight),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _trustPolicySample));
                            Toast.showSuccess(context, 'Policy JSON copied to clipboard');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _trustPolicySample,
                      style: AppTypography.code.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Steps
              Text('Step-by-Step Guide', style: AppTypography.sectionTitle),
              const SizedBox(height: 12),
              ..._steps.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GuardianCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            s['step']!,
                            style: AppTypography.label.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s['title']!, style: AppTypography.sectionTitle.copyWith(fontSize: 15)),
                              const SizedBox(height: 4),
                              Text(s['desc']!, style: AppTypography.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Open Console Button
              GuardianButton(
                label: 'Open AWS Console',
                variant: ButtonVariant.primary,
                width: double.infinity,
                icon: Icons.open_in_new_rounded,
                onPressed: () => _openAwsConsole(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
