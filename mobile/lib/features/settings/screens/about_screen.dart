import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/guardian_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('About AWS Guardian', style: AppTypography.headingMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    AppConstants.logoIcon,
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppConstants.appName,
                style: AppTypography.headingLarge,
              ),
              const SizedBox(height: 6),
              Text(
                AppConstants.appTagline,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.primaryLight),
              ),
              const SizedBox(height: 6),
              Text(
                'Version ${AppConstants.appVersion} (Build ${AppConstants.buildNumber})',
                style: AppTypography.caption,
              ),
              const SizedBox(height: 32),

              // Principles Card
              GuardianCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Core Product Principles', style: AppTypography.sectionTitle),
                    const SizedBox(height: 14),
                    _buildPrincipleRow(
                      icon: Icons.lock_outline_rounded,
                      title: 'Zero Credential Storage',
                      desc: 'We never ask for or store AWS passwords or permanent access keys.',
                    ),
                    const SizedBox(height: 14),
                    _buildPrincipleRow(
                      icon: Icons.shield_outlined,
                      title: 'Never Auto-Delete',
                      desc: 'AWS Guardian never automatically terminates cloud assets without user verification.',
                    ),
                    const SizedBox(height: 14),
                    _buildPrincipleRow(
                      icon: Icons.attach_money_rounded,
                      title: 'Transparent Pricing',
                      desc: 'Clear distinction between actual AWS billing data and estimated cost impact.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                '© 2026 AWS Guardian. Built for Cloud Security Architects.',
                style: AppTypography.caption.copyWith(fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrincipleRow({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryLight, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.sectionTitle.copyWith(fontSize: 14)),
              const SizedBox(height: 2),
              Text(desc, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
