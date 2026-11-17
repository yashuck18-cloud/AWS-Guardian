from rest_framework import serializers
from django.contrib.auth import get_user_model
from aws_accounts.models import AWSAccount
from resources.models import Resource
from alerts.models import Alert
from scanner.models import Scan
from notifications.models import NotificationHistory, NotificationSettings
from audit.models import AuditLog

User = get_user_model()

class AdminUserListSerializer(serializers.ModelSerializer):
    aws_accounts_count = serializers.SerializerMethodField()
    resources_count = serializers.SerializerMethodField()
    active_alerts_count = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = (
            'id', 'email', 'name', 'avatar_url',
            'is_active', 'is_staff', 'is_superuser',
            'scan_interval_hours', 'ec2_threshold_hours', 'ebs_threshold_hours',
            'theme_preference', 'last_login', 'created_at',
            'aws_accounts_count', 'resources_count', 'active_alerts_count'
        )

    def get_aws_accounts_count(self, obj):
        return obj.aws_accounts.count()

    def get_resources_count(self, obj):
        return Resource.objects.filter(account__user=obj).count()

    def get_active_alerts_count(self, obj):
        return Alert.objects.filter(account__user=obj, status__in=['ACTIVE', 'ACKNOWLEDGED']).count()


class AdminAWSAccountSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.name', read_only=True)
    user_email = serializers.CharField(source='user.email', read_only=True)
    resources_count = serializers.SerializerMethodField()
    alerts_count = serializers.SerializerMethodField()
    scans_count = serializers.SerializerMethodField()

    class Meta:
        model = AWSAccount
        fields = (
            'id', 'user', 'user_name', 'user_email',
            'name', 'account_id', 'role_arn', 'external_id',
            'status', 'enabled_regions', 'last_scan_at', 'error_message',
            'created_at', 'updated_at',
            'resources_count', 'alerts_count', 'scans_count'
        )

    def get_resources_count(self, obj):
        return obj.resources.count()

    def get_alerts_count(self, obj):
        return obj.alerts.count()

    def get_scans_count(self, obj):
        return obj.scans.count()


class AdminResourceSerializer(serializers.ModelSerializer):
    account_name = serializers.CharField(source='account.name', read_only=True)
    account_aws_id = serializers.CharField(source='account.account_id', read_only=True)
    user_id = serializers.CharField(source='account.user.id', read_only=True)
    user_name = serializers.CharField(source='account.user.name', read_only=True)
    user_email = serializers.CharField(source='account.user.email', read_only=True)
    resource_name = serializers.CharField(source='name', read_only=True)
    status = serializers.CharField(source='state', read_only=True)
    detection_reason = serializers.CharField(source='risk_reason', read_only=True)
    last_seen = serializers.DateTimeField(source='last_seen_at', read_only=True)
    active_alerts_count = serializers.SerializerMethodField()
    cost_info = serializers.SerializerMethodField()

    class Meta:
        model = Resource
        fields = (
            'id', 'account', 'account_name', 'account_aws_id',
            'user_id', 'user_name', 'user_email',
            'service', 'resource_id', 'name', 'resource_name', 'region',
            'state', 'status', 'risk_level', 'risk_reason', 'detection_reason',
            'estimated_hourly_cost', 'cost_info', 'metadata',
            'last_seen_at', 'last_seen', 'created_at', 'active_alerts_count'
        )

    def get_active_alerts_count(self, obj):
        return obj.alerts.filter(status__in=['ACTIVE', 'ACKNOWLEDGED']).count()

    def get_cost_info(self, obj):
        latest_cost = obj.cost_records.order_by('-last_updated').first()
        from resources.serializers import ResourceCostSerializer
        if latest_cost:
            return ResourceCostSerializer(latest_cost).data
        hourly = float(obj.estimated_hourly_cost or 0.0)
        return {
            'resource_id': obj.resource_id,
            'service': obj.service,
            'region': obj.region,
            'actual_cost': '0.0000',
            'estimated_cost': f"{round(hourly * 24.0, 4):.4f}",
            'currency': 'USD',
            'pricing_rate': f"{hourly:.6f}",
            'pricing_unit': 'Hrs',
            'cost_source': 'AWS_PRICING',
            'billing_status': 'PRICING_ESTIMATE',
            'approx_inr': round(hourly * 24.0 * 86.50, 2),
            'notes': 'Calculated from authoritative AWS on-demand hourly pricing. Final AWS billing may differ.',
        }



class AdminAlertSerializer(serializers.ModelSerializer):
    account_name = serializers.CharField(source='account.name', read_only=True)
    account_aws_id = serializers.CharField(source='account.account_id', read_only=True)
    user_id = serializers.CharField(source='account.user.id', read_only=True)
    user_name = serializers.CharField(source='account.user.name', read_only=True)
    user_email = serializers.CharField(source='account.user.email', read_only=True)
    resource_type = serializers.CharField(source='resource.service', read_only=True, default='')
    resource_identifier = serializers.CharField(source='resource.resource_id', read_only=True, default='')
    resource_name = serializers.CharField(source='resource.name', read_only=True, default='')

    class Meta:
        model = Alert
        fields = (
            'id', 'account', 'account_name', 'account_aws_id',
            'user_id', 'user_name', 'user_email',
            'resource', 'resource_type', 'resource_identifier', 'resource_name',
            'rule_code', 'severity', 'title', 'description',
            'estimated_cost_impact', 'status', 'resolved_at',
            'first_detected_at', 'last_detected_at'
        )


class AdminScanSerializer(serializers.ModelSerializer):
    account_name = serializers.CharField(source='account.name', read_only=True)
    account_aws_id = serializers.CharField(source='account.account_id', read_only=True)
    user_id = serializers.CharField(source='account.user.id', read_only=True)
    user_name = serializers.CharField(source='account.user.name', read_only=True)
    user_email = serializers.CharField(source='account.user.email', read_only=True)
    alerts_generated = serializers.IntegerField(source='alerts_created', read_only=True)

    class Meta:
        model = Scan
        fields = (
            'id', 'account', 'account_name', 'account_aws_id',
            'user_id', 'user_name', 'user_email',
            'status', 'trigger_source', 'resources_found', 'alerts_created', 'alerts_generated',
            'notification_sent', 'notification_status', 'notification_title',
            'error_message', 'started_at', 'completed_at'
        )


class AdminNotificationSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.name', read_only=True)
    user_email = serializers.CharField(source='user.email', read_only=True)

    class Meta:
        model = NotificationHistory
        fields = (
            'id', 'user', 'user_name', 'user_email',
            'title', 'message', 'channel',
            'status', 'error_details', 'created_at'
        )


class AdminAuditLogSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.name', read_only=True, default='System')
    user_email = serializers.CharField(source='user.email', read_only=True, default='')

    class Meta:
        model = AuditLog
        fields = (
            'id', 'user', 'user_name', 'user_email',
            'action', 'ip_address',
            'details', 'timestamp'
        )


class AdminUserDetailSerializer(serializers.ModelSerializer):
    aws_accounts = AdminAWSAccountSerializer(many=True, read_only=True)
    notification_settings = serializers.SerializerMethodField()
    stats = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = (
            'id', 'email', 'name', 'avatar_url',
            'is_active', 'is_staff', 'is_superuser',
            'scan_interval_hours', 'ec2_threshold_hours', 'ebs_threshold_hours',
            'theme_preference', 'last_login', 'created_at', 'updated_at',
            'aws_accounts', 'notification_settings', 'stats'
        )

    def get_notification_settings(self, obj):
        try:
            settings = obj.notification_settings
            return {
                'morning_summary_enabled': settings.morning_summary_enabled,
                'evening_summary_enabled': settings.evening_summary_enabled,
                'urgent_alerts_enabled': settings.urgent_alerts_enabled,
                'telegram_enabled': settings.telegram_enabled,
                'telegram_chat_id': settings.telegram_chat_id,
            }
        except Exception:
            return None

    def get_stats(self, obj):
        return {
            'accounts_count': obj.aws_accounts.count(),
            'resources_count': Resource.objects.filter(account__user=obj).count(),
            'active_alerts_count': Alert.objects.filter(account__user=obj, status__in=['ACTIVE', 'ACKNOWLEDGED']).count(),
            'resolved_alerts_count': Alert.objects.filter(account__user=obj, status='RESOLVED').count(),
            'total_scans_count': Scan.objects.filter(account__user=obj).count(),
            'notifications_count': NotificationHistory.objects.filter(user=obj).count(),
        }
