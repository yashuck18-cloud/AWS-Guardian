import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/toast.dart';
import '../../../shared/widgets/guardian_button.dart';
import '../../../shared/widgets/guardian_text_field.dart';
import '../../../shared/widgets/guardian_card.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  bool _isUpdatingProfile = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) {
      _nameController.text = user.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _oldPassController.dispose();
    _newPassController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      Toast.showError(context, 'Name cannot be empty');
      return;
    }

    setState(() => _isUpdatingProfile = true);
    final success = await ref.read(authProvider.notifier).updateProfile({'name': name});
    setState(() => _isUpdatingProfile = false);

    if (mounted) {
      if (success) {
        Toast.showSuccess(context, 'Profile updated successfully');
      } else {
        Toast.showError(context, 'Failed to update profile');
      }
    }
  }

  Future<void> _handleChangePassword() async {
    final oldPass = _oldPassController.text;
    final newPass = _newPassController.text;

    if (oldPass.isEmpty || newPass.isEmpty) {
      Toast.showError(context, 'Please fill in both password fields');
      return;
    }

    if (newPass.length < 8) {
      Toast.showError(context, 'New password must be at least 8 characters');
      return;
    }

    setState(() => _isChangingPassword = true);
    final success = await ref.read(authProvider.notifier).changePassword(oldPass, newPass);
    setState(() => _isChangingPassword = false);

    if (mounted) {
      if (success) {
        _oldPassController.clear();
        _newPassController.clear();
        Toast.showSuccess(context, 'Password changed successfully');
      } else {
        final err = ref.read(authProvider).errorMessage ?? 'Failed to change password';
        Toast.showError(context, err);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Profile & Security', style: AppTypography.headingMedium),
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
              // User Card
              GuardianCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'G',
                        style: AppTypography.headingLarge.copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.name ?? '', style: AppTypography.sectionTitle),
                          const SizedBox(height: 2),
                          Text(user?.email ?? '', style: AppTypography.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Edit Name
              Text('Personal Information', style: AppTypography.sectionTitle),
              const SizedBox(height: 12),
              GuardianTextField(
                controller: _nameController,
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              GuardianButton(
                label: 'Save Profile Changes',
                variant: ButtonVariant.outlined,
                width: double.infinity,
                isLoading: _isUpdatingProfile,
                onPressed: _handleUpdateProfile,
              ),
              const SizedBox(height: 32),

              // Change Password
              Text('Account Security', style: AppTypography.sectionTitle),
              const SizedBox(height: 12),
              GuardianTextField(
                controller: _oldPassController,
                labelText: 'Current Password',
                obscureText: true,
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),
              GuardianTextField(
                controller: _newPassController,
                labelText: 'New Password (min 8 characters)',
                obscureText: true,
                prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              GuardianButton(
                label: 'Update Password',
                variant: ButtonVariant.secondary,
                width: double.infinity,
                isLoading: _isChangingPassword,
                onPressed: _handleChangePassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
