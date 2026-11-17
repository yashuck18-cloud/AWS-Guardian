import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/toast.dart';
import '../../../core/providers.dart';
import '../../../shared/widgets/guardian_card.dart';
import '../../../shared/widgets/guardian_button.dart';
import '../../../shared/widgets/guardian_text_field.dart';

class AppearanceScreen extends ConsumerStatefulWidget {
  const AppearanceScreen({super.key});

  @override
  ConsumerState<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends ConsumerState<AppearanceScreen> {
  String _themeMode = 'dark';
  final _apiUrlController = TextEditingController();

  final List<Map<String, dynamic>> _themeOptions = [
    {
      'id': 'dark',
      'title': 'Dark Theme (Recommended)',
      'subtitle': 'Optimized for cloud security operations',
      'icon': Icons.dark_mode_rounded,
    },
    {
      'id': 'light',
      'title': 'Light Theme',
      'subtitle': 'High contrast daylight viewing',
      'icon': Icons.light_mode_rounded,
    },
    {
      'id': 'system',
      'title': 'System Default',
      'subtitle': 'Follows system appearance setting',
      'icon': Icons.settings_brightness_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(localPreferencesProvider);
    _themeMode = prefs.themeMode;
    _apiUrlController.text = prefs.apiBaseUrl;
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final prefs = ref.read(localPreferencesProvider);
    await prefs.setThemeMode(_themeMode);
    await prefs.setApiBaseUrl(_apiUrlController.text.trim());

    if (mounted) {
      Toast.showSuccess(context, 'Preferences updated successfully');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Appearance & API', style: AppTypography.headingMedium),
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
              Text('Theme Mode', style: AppTypography.sectionTitle),
              const SizedBox(height: 6),
              Text('Dark theme is default for cloud security engineering.', style: AppTypography.caption),
              const SizedBox(height: 12),
              GuardianCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: _themeOptions.map((opt) {
                    final isSelected = _themeMode == opt['id'];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: InkWell(
                        onTap: () => setState(() => _themeMode = opt['id']),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.surfaceElevated2 : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryLight : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                opt['icon'] as IconData,
                                color: isSelected ? AppColors.primaryLight : AppColors.textMuted,
                                size: 20,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      opt['title'] as String,
                                      style: AppTypography.bodyLarge.copyWith(
                                        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      opt['subtitle'] as String,
                                      style: AppTypography.caption,
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primaryLight,
                                  size: 18,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              Text('Backend API Endpoint', style: AppTypography.sectionTitle),
              const SizedBox(height: 6),
              Text(
                'Configure the server URL for local development or production deployment.',
                style: AppTypography.caption,
              ),
              const SizedBox(height: 12),
              GuardianTextField(
                controller: _apiUrlController,
                labelText: 'Base API URL',
                hintText: 'http://127.0.0.1:8000/api',
                prefixIcon: const Icon(Icons.dns_outlined, size: 18, color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Localhost / USB', style: TextStyle(fontSize: 12)),
                    backgroundColor: AppColors.surfaceElevated,
                    onPressed: () => setState(() => _apiUrlController.text = 'http://127.0.0.1:8000/api'),
                  ),
                  ActionChip(
                    label: const Text('Local Wi-Fi', style: TextStyle(fontSize: 12)),
                    backgroundColor: AppColors.surfaceElevated,
                    onPressed: () => setState(() => _apiUrlController.text = 'http://10.42.173.165:8000/api'),
                  ),
                  ActionChip(
                    label: const Text('Emulator', style: TextStyle(fontSize: 12)),
                    backgroundColor: AppColors.surfaceElevated,
                    onPressed: () => setState(() => _apiUrlController.text = 'http://10.0.2.2:8000/api'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              GuardianButton(
                label: 'Save Configuration',
                width: double.infinity,
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
