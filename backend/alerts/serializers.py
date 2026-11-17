from rest_framework import serializers
from .models import Alert
from resources.serializers import ResourceSerializer

class AlertSerializer(serializers.ModelSerializer):
    severity_display = serializers.CharField(source='get_severity_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    account_name = serializers.CharField(source='account.name', read_only=True)
    account_number = serializers.CharField(source='account.account_id', read_only=True)
    resource = ResourceSerializer(read_only=True)
    resource_name = serializers.CharField(source='resource.name', read_only=True)
    resource_id_str = serializers.CharField(source='resource.resource_id', read_only=True)
    resource_service = serializers.CharField(source='resource.service', read_only=True)
    resource_region = serializers.CharField(source='resource.region', read_only=True)

    class Meta:
        model = Alert
        fields = (
            'id', 'account', 'account_name', 'account_number', 'resource',
            'resource_name', 'resource_id_str', 'resource_service', 'resource_region',
            'rule_code', 'title', 'description', 'severity', 'severity_display',
            'status', 'status_display', 'estimated_cost_impact',
            'first_detected_at', 'last_detected_at', 'resolved_at'
        )
        read_only_fields = fields
