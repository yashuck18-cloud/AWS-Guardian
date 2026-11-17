import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/guardian_card.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  final List<Map<String, String>> _faqs = const [
    {
      'question': 'What is AWS Guardian?',
      'answer':
          'AWS Guardian is an enterprise-grade cloud resource detection and cost protection application designed to identify idle, forgotten, or misconfigured AWS assets like running test EC2 instances, unattached EBS volumes, and unassociated Elastic IPs.',
    },
    {
      'question': 'How does the AWS connection work?',
      'answer':
          'AWS Guardian connects to your AWS account securely using IAM Role delegation and AWS Security Token Service (STS) AssumeRole. You grant temporary, read-only permissions without ever exposing permanent access keys or root passwords.',
    },
    {
      'question': 'What is an IAM Role?',
      'answer':
          'An IAM Role is an AWS identity that you can create in your account that has specific permissions. Unlike IAM Users, IAM Roles do not have permanent credentials; instead, AWS STS issues temporary security credentials upon assuming the role.',
    },
    {
      'question': 'Why do I need an External ID?',
      'answer':
          'The External ID is a unique secret string used in the IAM Role Trust Policy condition. It prevents the "Confused Deputy Problem" by ensuring only your specific AWS Guardian account can assume the role.',
    },
    {
      'question': 'What happens during a scan?',
      'answer':
          'During a scan, AWS Guardian makes read-only Describe API calls (e.g. DescribeInstances, DescribeVolumes) across your configured regions, passes the results through our rule engine to detect idle conditions, and generates alerts.',
    },
    {
      'question': 'Can AWS Guardian delete my resources automatically?',
      'answer':
          'NO. AWS Guardian NEVER automatically deletes AWS resources. The system only detects, explains, and recommends actions. Any stopping or deletion requires explicit user initiation and confirmation.',
    },
    {
      'question': 'How are notifications sent?',
      'answer':
          'Notifications are sent via twice-daily summaries (Morning 09:00 and Evening 19:00) directly to your mobile app and optional Telegram Bot integration, as well as immediate push alerts for Critical risk findings.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Help & FAQs', style: AppTypography.headingMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _faqs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final faq = _faqs[index];
            return GuardianCard(
              padding: EdgeInsets.zero,
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  iconColor: AppColors.primaryLight,
                  collapsedIconColor: AppColors.textSecondary,
                  title: Text(
                    faq['question']!,
                    style: AppTypography.sectionTitle.copyWith(fontSize: 15),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      child: Text(
                        faq['answer']!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
