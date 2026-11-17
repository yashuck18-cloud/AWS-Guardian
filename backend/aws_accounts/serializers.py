from rest_framework import serializers
from .models import AWSAccount
from .sts_service import validate_role_arn

class AWSAccountSerializer(serializers.ModelSerializer):
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    resource_count = serializers.SerializerMethodField()
    alert_count = serializers.SerializerMethodField()

    class Meta:
        model = AWSAccount
        fields = (
            'id', 'name', 'account_id', 'role_arn', 'external_id',
            'status', 'status_display', 'last_scan_at', 'error_message',
            'enabled_regions', 'created_at', 'resource_count', 'alert_count'
        )
        read_only_fields = ('id', 'external_id', 'status', 'last_scan_at', 'error_message', 'created_at')

    def get_resource_count(self, obj):
        return obj.resources.count()

    def get_alert_count(self, obj):
        return obj.alerts.filter(status='ACTIVE').count()

class ConnectAWSAccountSerializer(serializers.ModelSerializer):
    external_id = serializers.CharField(required=False, allow_blank=True, default='')

    class Meta:
        model = AWSAccount
        fields = ('id', 'name', 'account_id', 'role_arn', 'external_id', 'enabled_regions')
        read_only_fields = ('id',)

    def validate_account_id(self, value):
        val = value.strip()
        if not val.isdigit() or len(val) != 12:
            raise serializers.ValidationError("AWS Account ID must be exactly 12 digits.")
        return val

    def validate(self, attrs):
        account_id = attrs.get('account_id')
        role_arn = attrs.get('role_arn')
        if role_arn and account_id:
            from .sts_service import normalize_role_arn, validate_role_arn
            normalized = normalize_role_arn(role_arn, account_id)
            data, err = validate_role_arn(normalized, account_id)
            if err:
                raise serializers.ValidationError({'role_arn': err})
            attrs['role_arn'] = normalized
        return attrs

class VerifyAWSAccountSerializer(serializers.Serializer):
    account_id = serializers.CharField(required=True)
    role_arn = serializers.CharField(required=True)
    external_id = serializers.CharField(required=False, allow_blank=True, default='')
