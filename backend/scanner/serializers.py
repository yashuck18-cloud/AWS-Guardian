from rest_framework import serializers
from .models import Scan

class ScanSerializer(serializers.ModelSerializer):
    account_name = serializers.CharField(source='account.name', read_only=True)
    account_number = serializers.CharField(source='account.account_id', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = Scan
        fields = (
            'id', 'account', 'account_name', 'account_number',
            'status', 'status_display', 'trigger_source', 'started_at', 'completed_at',
            'resources_found', 'alerts_created', 'alerts_resolved',
            'warnings_count', 'scanned_regions', 'service_errors', 'error_message',
            'notification_sent', 'notification_status', 'notification_title', 'notification_message'
        )
        read_only_fields = fields

class TriggerScanRequestSerializer(serializers.Serializer):
    account_id = serializers.UUIDField(required=False)
    sync = serializers.BooleanField(default=True)
