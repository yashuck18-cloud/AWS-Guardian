class ApiConstants {
  ApiConstants._();

  // Production Render URL (Update with your onrender.com service name after deploying)
  static const String renderBaseUrl = 'https://aws-guardian-backend.onrender.com/api';

  // Public Ngrok Tunnel URL for Remote, 4G/5G, and Cross-Network Access
  static const String ngrokBaseUrl = 'https://utter-settle-sedation.ngrok-free.dev/api';

  // Local Development URLs
  static const String localHostBaseUrl = 'http://127.0.0.1:8000/api';
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:8000/api';
  static const String localLanBaseUrl = 'http://10.28.71.165:8000/api';

  // Default Base URL: Pointed to Production Render Cloud API
  static String get defaultBaseUrl => renderBaseUrl;

  // Fallback candidate URLs probed automatically if primary is unreachable
  static const List<String> fallbackUrls = [
    localHostBaseUrl,
    localLanBaseUrl,
    androidEmulatorBaseUrl,
    renderBaseUrl,
  ];

  // Auth endpoints
  static const String register = '/auth/register/';
  static const String login = '/auth/login/';
  static const String profile = '/auth/profile/';
  static const String changePassword = '/auth/change-password/';
  static const String forgotPassword = '/auth/forgot-password/';
  static const String deleteAccount = '/auth/delete-account/';

  // AWS Accounts endpoints
  static const String awsAccounts = '/aws-accounts/';
  static const String generateExternalId = '/aws-accounts/generate-external-id/';
  static const String verifyAccount = '/aws-accounts/verify/';

  // AWS Guardian Host Cloud Identity
  static const String guardianAwsAccountId = '662371887384';
  static const String guardianAwsPrincipal = 'arn:aws:iam::662371887384:root';

  // Resources endpoints
  static const String resources = '/resources/';

  // Scanner endpoints
  static const String triggerScan = '/scanner/scan/';
  static const String scanHistory = '/scanner/history/';

  // Alerts endpoints
  static const String alerts = '/alerts/';

  // Dashboard & Analytics endpoints
  static const String dashboard = '/analytics/dashboard/';
  static const String analytics = '/analytics/data/';
  static const String costs = '/analytics/costs/';

  // Audit Logs endpoints
  static const String auditLogs = '/audit/';

  // Notifications endpoints
  static const String notifications = '/notifications/';
  static const String registerDevice = '/notifications/register-device/';
  static const String deactivateDevice = '/notifications/devices/deactivate/';
  static const String notificationSettings = '/notifications/settings/';
  static const String notificationHistory = '/notifications/history/';
  static const String testFCM = '/notifications/test-fcm/';
  static const String testTelegram = '/notifications/test-telegram/';
  static const String sendSummary = '/notifications/send-summary/';
}
