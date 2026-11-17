import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class GuardianCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final bool elevated;
  final bool withPurpleGlow;

  const GuardianCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 18,
    this.elevated = false,
    this.withPurpleGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ??
            (elevated ? AppColors.surfaceElevated : AppColors.surface),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? (withPurpleGlow ? AppColors.primaryLight.withAlpha(90) : AppColors.border),
          width: 1,
        ),
        boxShadow: [
          if (withPurpleGlow)
            BoxShadow(
              color: AppColors.primary.withAlpha(30),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          else
            BoxShadow(
              color: Colors.black.withAlpha(65),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: AppColors.primaryLight.withAlpha(25),
          highlightColor: AppColors.primaryLight.withAlpha(12),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
