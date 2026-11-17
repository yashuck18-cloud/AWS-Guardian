import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/shared/models/user_model.dart';
import 'package:mobile/shared/models/aws_account_model.dart';
import 'package:mobile/shared/models/resource_model.dart';
import 'package:mobile/shared/models/alert_model.dart';
import 'package:mobile/shared/models/dashboard_stats_model.dart';

void main() {
  group('Models Serialization Tests', () {
    test('UserModel serialization and deserialization', () {
      final json = {
        'id': 'user-123',
        'email': 'dev@guardian.cloud',
        'name': 'Dev Architect',
        'avatar_url': 'https://example.com/avatar.png',
        'scan_interval_hours': 12,
        'ec2_threshold_hours': 48,
        'ebs_threshold_hours': 24,
        'theme_preference': 'dark',
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 'user-123');
      expect(user.email, 'dev@guardian.cloud');
      expect(user.name, 'Dev Architect');
      expect(user.ec2ThresholdHours, 48);

      final outJson = user.toJson();
      expect(outJson['email'], 'dev@guardian.cloud');
    });

    test('AWSAccountModel parsing', () {
      final json = {
        'id': 'acc-001',
        'name': 'Production AWS',
        'account_id': '123456789012',
        'role_arn': 'arn:aws:iam::123456789012:role/AWSGuardianRole',
        'external_id': 'guardian-secret-123',
        'status': 'CONNECTED',
        'status_display': 'Connected',
        'resource_count': 42,
        'alert_count': 3,
        'enabled_regions': ['ap-south-1', 'us-east-1'],
      };

      final acc = AWSAccountModel.fromJson(json);
      expect(acc.isConnected, isTrue);
      expect(acc.accountId, '123456789012');
      expect(acc.resourceCount, 42);
      expect(acc.alertCount, 3);
    });

    test('ResourceModel risk checks', () {
      final json = {
        'id': 'res-001',
        'service': 'EC2',
        'resource_id': 'i-0123456789abcdef0',
        'name': 'Batch Worker',
        'region': 'ap-south-1',
        'state': 'running',
        'risk_level': 'CRITICAL',
        'risk_reason': 'Running for > 14 days',
        'estimated_hourly_cost': 0.0416,
      };

      final res = ResourceModel.fromJson(json);
      expect(res.isCritical, isTrue);
      expect(res.hasRisk, isTrue);
      expect(res.displayName, 'Batch Worker');
    });

    test('AlertModel parsing', () {
      final json = {
        'id': 'alert-001',
        'rule_code': 'EC2_IDLE',
        'title': 'Idle EC2 detected',
        'description': 'Instance running beyond threshold',
        'severity': 'HIGH',
        'status': 'ACTIVE',
        'estimated_cost_impact': 45.50,
      };

      final alert = AlertModel.fromJson(json);
      expect(alert.isActive, isTrue);
      expect(alert.severity, 'HIGH');
      expect(alert.estimatedCostImpact, 45.50);
    });

    test('DashboardStatsModel parsing', () {
      final json = {
        'stats': {
          'total_resources': 156,
          'running_resources': 42,
          'needs_attention': 8,
          'critical_count': 2,
          'risk_overview': {
            'critical': 2,
            'high': 4,
            'medium': 2,
            'low': 0,
            'total_alerts': 8,
          },
          'resources_by_service': {'EC2': 45, 'S3': 28, 'RDS': 16},
          'recent_alerts': [],
        }
      };

      final stats = DashboardStatsModel.fromJson(json);
      expect(stats.totalResources, 156);
      expect(stats.runningResources, 42);
      expect(stats.needsAttention, 8);
      expect(stats.riskOverview.totalAlerts, 8);
    });
  });
}
