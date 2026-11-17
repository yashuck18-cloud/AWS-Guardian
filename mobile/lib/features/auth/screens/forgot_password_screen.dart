import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/toast.dart';
import '../../../shared/widgets/guardian_button.dart';
import '../../../shared/widgets/guardian_text_field.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      Toast.showError(context, 'Please enter your email address');
      return;
    }

    setState(() => _isLoading = true);
    final authNotifier = ref.read(authProvider.notifier);
    final success = await authNotifier.forgotPassword(email);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      setState(() => _isSent = true);
    } else {
      Toast.showError(context, 'Unable to send reset link. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: _isSent ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reset Password',
          style: AppTypography.displayMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the email associated with your AWS Guardian account and we will send password reset instructions.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 32),
        GuardianTextField(
          controller: _emailController,
          labelText: 'Email Address',
          hintText: 'alex@company.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppColors.textMuted),
        ),
        const SizedBox(height: 28),
        GuardianButton(
          label: 'Send Reset Link',
          width: double.infinity,
          isLoading: _isLoading,
          onPressed: _handleReset,
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3), width: 1.5),
            ),
            child: const Icon(Icons.mark_email_read_rounded, size: 48, color: AppColors.success),
          ),
          const SizedBox(height: 24),
          Text(
            'Reset Link Sent',
            style: AppTypography.headingLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Check ${_emailController.text} for instructions to reset your password.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 32),
          GuardianButton(
            label: 'Back to Login',
            variant: ButtonVariant.outlined,
            width: double.infinity,
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
    );
  }
}
