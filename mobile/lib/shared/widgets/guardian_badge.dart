import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class GuardianBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;
  final bool isSeverity;
  final bool isService;
  final IconData? icon;

  const GuardianBadge({
    super.key,
    required this.label,
    this.color,
    this.textColor,
    this.isSeverity = false,
    this.isService = false,
    this.icon,
  });

  factory GuardianBadge.severity(String severity) {
    return GuardianBadge(
      label: severity.toUpperCase(),
      isSeverity: true,
      color: _getSeverityColor(severity),
    );
  }

  factory GuardianBadge.status(String status) {
    final s = status.toUpperCase();
    Color bg = AppColors.borderLight;
    if (s == 'RUNNING' || s == 'CONNECTED' || s == 'ACTIVE' || s == 'COMPLETED') {
      bg = AppColors.success;
    } else if (s == 'STOPPED' || s == 'RESOLVED') {
      bg = AppColors.textMuted;
    } else if (s == 'ERROR' || s == 'FAILED') {
      bg = AppColors.critical;
    } else if (s == 'PENDING' || s == 'ACKNOWLEDGED' || s == 'IN_PROGRESS') {
      bg = AppColors.warning;
    }

    return GuardianBadge(
      label: s,
      color: bg,
    );
  }

  factory GuardianBadge.costStatus(String status) {
    final s = status.toUpperCase();
    Color bg = AppColors.primaryLight;
    String label = 'PRICING ESTIMATE';
    if (s == 'ACTUAL') {
      bg = AppColors.success;
      label = 'AWS BILLED COST';
    } else if (s == 'ESTIMATED') {
      bg = AppColors.warning;
      label = 'CURRENT ESTIMATED';
    } else if (s == 'PRICING_ESTIMATE') {
      bg = AppColors.primaryLight;
      label = 'PRICING ESTIMATE';
    } else if (s == 'UNAVAILABLE') {
      bg = AppColors.textMuted;
      label = 'UNAVAILABLE';
    }

    return GuardianBadge(
      label: label,
      color: bg,
    );
  }


  factory GuardianBadge.service(String service) {
    return GuardianBadge(
      label: service.toUpperCase(),
      isService: true,
      color: _getServiceColor(service),
    );
  }

  static Color _getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return AppColors.riskCritical;
      case 'HIGH':
        return AppColors.riskHigh;
      case 'MEDIUM':
        return AppColors.riskMedium;
      case 'LOW':
        return AppColors.riskLow;
      default:
        return AppColors.riskNone;
    }
  }

  static Color _getServiceColor(String service) {
    switch (service.toUpperCase()) {
      case 'EC2':
        return AppColors.serviceEC2;
      case 'S3':
        return AppColors.serviceS3;
      case 'RDS':
        return AppColors.serviceRDS;
      case 'EBS':
        return AppColors.serviceEBS;
      case 'ELB':
        return AppColors.serviceELB;
      case 'NAT':
        return AppColors.serviceNAT;
      case 'EIP':
        return AppColors.serviceEIP;
      case 'SG':
        return AppColors.serviceSG;
      default:
        return AppColors.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? AppColors.primaryLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: badgeColor),
            const SizedBox(width: 4),
          ] else if (isSeverity) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppTypography.label.copyWith(
              color: textColor ?? badgeColor,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
