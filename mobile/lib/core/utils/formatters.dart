import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String currency(num amount, {int decimals = 2}) {
    final format = NumberFormat.currency(symbol: '\$', decimalDigits: decimals);
    return format.format(amount);
  }

  static String formatDate(dynamic dt) {
    if (dt == null) return 'N/A';
    DateTime? parsed;
    if (dt is DateTime) {
      parsed = dt;
    } else if (dt is String) {
      parsed = DateTime.tryParse(dt);
    }
    if (parsed == null) return dt.toString();
    return DateFormat('MMM dd, yyyy').format(parsed.toLocal());
  }

  static String formatDateTime(dynamic dt) {
    if (dt == null) return 'N/A';
    DateTime? parsed;
    if (dt is DateTime) {
      parsed = dt;
    } else if (dt is String) {
      parsed = DateTime.tryParse(dt);
    }
    if (parsed == null) return dt.toString();
    return DateFormat('MMM dd, yyyy • hh:mm a').format(parsed.toLocal());
  }

  static String timeAgo(dynamic dt) {
    if (dt == null) return 'Never';
    DateTime? parsed;
    if (dt is DateTime) {
      parsed = dt;
    } else if (dt is String) {
      parsed = DateTime.tryParse(dt);
    }
    if (parsed == null) return 'Recently';

    final now = DateTime.now();
    final difference = now.difference(parsed.toLocal());

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? 'min' : 'mins'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 30) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      return formatDate(parsed);
    }
  }

  static String maskAccountId(String accountId) {
    if (accountId.length <= 4) return accountId;
    return '•••• •••• ${accountId.substring(accountId.length - 4)}';
  }

  static String regionName(String region) {
    switch (region.toLowerCase()) {
      case 'ap-south-1':
        return 'ap-south-1 (Mumbai)';
      case 'ap-south-2':
        return 'ap-south-2 (Hyderabad)';
      case 'us-east-1':
        return 'us-east-1 (N. Virginia)';
      case 'us-east-2':
        return 'us-east-2 (Ohio)';
      case 'us-west-1':
        return 'us-west-1 (N. California)';
      case 'us-west-2':
        return 'us-west-2 (Oregon)';
      case 'eu-west-1':
        return 'eu-west-1 (Ireland)';
      case 'eu-central-1':
        return 'eu-central-1 (Frankfurt)';
      case 'eu-west-2':
        return 'eu-west-2 (London)';
      case 'eu-west-3':
        return 'eu-west-3 (Paris)';
      case 'eu-north-1':
        return 'eu-north-1 (Stockholm)';
      case 'ap-southeast-1':
        return 'ap-southeast-1 (Singapore)';
      case 'ap-southeast-2':
        return 'ap-southeast-2 (Sydney)';
      case 'ap-northeast-1':
        return 'ap-northeast-1 (Tokyo)';
      case 'ap-northeast-2':
        return 'ap-northeast-2 (Seoul)';
      case 'ap-northeast-3':
        return 'ap-northeast-3 (Osaka)';
      case 'ca-central-1':
        return 'ca-central-1 (Central)';
      case 'sa-east-1':
        return 'sa-east-1 (São Paulo)';
      case 'all':
        return 'All Regions';
      case 'global':
        return 'Global';
      default:
        return region;
    }
  }
}
