class AppConstants {
  AppConstants._();

  static const String appName = 'AWS Guardian';
  static const String appTagline = 'Find what you forgot. Protect your AWS bill.';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // Asset Paths
  static const String logo = 'assets/images/logo.png';
  static const String logoIcon = 'assets/images/logo_icon.png';

  // Storage Keys
  static const String keyAuthToken = 'aws_guardian_jwt_token';
  static const String keyUserEmail = 'aws_guardian_user_email';
  static const String keyUserData = 'aws_guardian_user_data';
  static const String keyOnboardingCompleted = 'aws_guardian_onboarding_completed';
  static const String keyThemeMode = 'aws_guardian_theme_mode';
  static const String keyApiBaseUrl = 'aws_guardian_api_base_url';
  static const String keyCachedAccounts = 'aws_guardian_cached_accounts';

  // Default AWS Regions
  static const List<String> supportedRegions = [
    'ap-south-1',
    'us-east-1',
    'us-west-2',
    'eu-west-1',
    'ap-southeast-1',
    'eu-central-1',
    'sa-east-1',
  ];

  static const String defaultRegion = 'ap-south-1';
}
