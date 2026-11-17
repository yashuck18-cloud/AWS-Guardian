import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/resources/screens/resources_screen.dart';
import '../../features/resources/screens/resource_details_screen.dart';
import '../../features/alerts/screens/alerts_screen.dart';
import '../../features/alerts/screens/alert_details_screen.dart';
import '../../features/aws_accounts/screens/aws_accounts_screen.dart';
import '../../features/aws_accounts/screens/connect_account_screen.dart';
import '../../features/aws_accounts/screens/account_details_screen.dart';
import '../../features/aws_accounts/screens/iam_instructions_screen.dart';
import '../../features/costs/screens/costs_screen.dart';
import '../../features/analytics/screens/analytics_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/activity/screens/activity_screen.dart';
import '../../features/more/screens/more_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/profile_screen.dart';
import '../../features/settings/screens/scanning_settings_screen.dart';
import '../../features/settings/screens/notification_settings_screen.dart';
import '../../features/settings/screens/appearance_screen.dart';
import '../../features/settings/screens/help_screen.dart';
import '../../features/settings/screens/about_screen.dart';
import '../../features/shared/shell_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../shared/widgets/guardian_button.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

void navigateToPath(String path) {
  final context = rootNavigatorKey.currentContext;
  if (context != null) {
    try {
      context.go(path);
    } catch (_) {
      try {
        context.push(path);
      } catch (e) {
        debugPrint('Failed to navigate to $path: $e');
      }
    }
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Shell Route with 5 Bottom Navigation Tabs
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/resources',
            builder: (context, state) => const ResourcesScreen(),
          ),
          GoRoute(
            path: '/alerts',
            builder: (context, state) => const AlertsScreen(),
          ),
          GoRoute(
            path: '/aws-accounts',
            builder: (context, state) => const AWSAccountsScreen(),
          ),
          GoRoute(
            path: '/more',
            builder: (context, state) => const MoreScreen(),
          ),
        ],
      ),

      GoRoute(
        path: '/accounts',
        redirect: (context, state) => '/aws-accounts',
      ),
      GoRoute(
        path: '/connect-aws',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ConnectAccountScreen(),
      ),
      GoRoute(
        path: '/iam-instructions',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const IAMInstructionsScreen(),
      ),
      GoRoute(
        path: '/aws-accounts/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AccountDetailsScreen(accountId: id);
        },
      ),
      GoRoute(
        path: '/resources/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ResourceDetailsScreen(resourceId: id);
        },
      ),
      GoRoute(
        path: '/alerts/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AlertDetailsScreen(alertId: id);
        },
      ),
      GoRoute(
        path: '/costs',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CostsScreen(),
      ),
      GoRoute(
        path: '/analytics',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/activity',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ActivityScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/profile',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings/scanning',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ScanningSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/notifications',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/appearance',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AppearanceScreen(),
      ),
      GoRoute(
        path: '/help',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: '/about',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AboutScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.critical),
              const SizedBox(height: 16),
              Text('Page Not Found (404)', style: AppTypography.headingLarge),
              const SizedBox(height: 8),
              Text(
                'The page ${state.uri.path} could not be resolved.',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              GuardianButton(
                label: 'Back to Dashboard',
                onPressed: () => context.go('/dashboard'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});
