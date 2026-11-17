import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Dark Navy Canvas & Card Surfaces (Figma Premium Cloud Security Palette)
  static const Color background = Color(0xFF0B0F19);      // Canvas Deep Navy
  static const Color surface = Color(0xFF151B2C);         // Sleek Slate Card
  static const Color surfaceElevated = Color(0xFF1C2438); // Elevated Card Surface
  static const Color surfaceElevated2 = Color(0xFF242E46);// High-contrast Chip/Sub-card
  static const Color border = Color(0xFF1F293D);          // 1px Subtle Border
  static const Color borderLight = Color(0xFF2E3D5B);     // Active / Hover Border

  // Primary & Purple Accent Palette
  static const Color primary = Color(0xFF7C3AED);         // Deep Purple
  static const Color primaryLight = Color(0xFF8B5CF6);    // Vibrant Violet
  static const Color primaryDark = Color(0xFF6D28D9);     // Dark Indigo
  static const Color primaryAccent = Color(0xFFA855F7);   // Electric Purple
  static const Color accentIndigo = Color(0xFF6366F1);    // Indigo Glow

  // Typography
  static const Color textPrimary = Color(0xFFF8FAFC);     // Slate 50 High-Contrast
  static const Color textSecondary = Color(0xFF94A3B8);   // Slate 400
  static const Color textMuted = Color(0xFF64748B);       // Slate 500
  static const Color textDimmed = Color(0xFF475569);      // Slate 600

  // Semantic Status & Risk Colors
  static const Color success = Color(0xFF10B981);         // Emerald 500
  static const Color warning = Color(0xFFF59E0B);         // Amber 500
  static const Color critical = Color(0xFFEF4444);        // Rose 500
  static const Color info = Color(0xFF38BDF8);           // Sky 400

  // Risk Severity Palette
  static const Color riskCritical = Color(0xFFEF4444);
  static const Color riskHigh = Color(0xFFF97316);
  static const Color riskMedium = Color(0xFFF59E0B);
  static const Color riskLow = Color(0xFF38BDF8);
  static const Color riskNone = Color(0xFF10B981);

  // AWS Service Brand Accents
  static const Color serviceEC2 = Color(0xFFFF9900);
  static const Color serviceS3 = Color(0xFF10B981);
  static const Color serviceRDS = Color(0xFF38BDF8);
  static const Color serviceEBS = Color(0xFF8B5CF6);
  static const Color serviceELB = Color(0xFFEC4899);
  static const Color serviceNAT = Color(0xFFA855F7);
  static const Color serviceEIP = Color(0xFF06B6D4);
  static const Color serviceSG = Color(0xFF14B8A6);

  // Premium Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGlowGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF151B2C), Color(0xFF111827)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient criticalGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x228B5CF6), Color(0x0A8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
