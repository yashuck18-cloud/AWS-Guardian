from rest_framework import serializers
from .models import NotificationSettings, NotificationHistory, FCMDevice

class NotificationSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = NotificationSettings
        fields = (
            'morning_summary_enabled', 'morning_summary_time',
            'evening_summary_enabled', 'evening_summary_time',
            'urgent_alerts_enabled', 'timezone',
            'telegram_enabled', 'telegram_chat_id', 'updated_at'
        )

class NotificationHistorySerializer(serializers.ModelSerializer):
    channel_display = serializers.CharField(source='get_channel_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = NotificationHistory
        fields = ('id', 'title', 'message', 'channel', 'channel_display', 'status', 'status_display', 'error_details', 'created_at')
        read_only_fields = fields

class FCMDeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = FCMDevice
        fields = ('id', 'fcm_token', 'platform', 'device_name', 'device_id', 'app_version', 'is_active', 'last_seen', 'created_at')
        read_only_fields = ('id', 'last_seen', 'created_at')

class DeviceRegistrationSerializer(serializers.Serializer):
    fcm_token = serializers.CharField(required=True, allow_blank=False, max_length=1024)
    platform = serializers.ChoiceField(choices=['android', 'ios', 'web'], default='android')
    device_name = serializers.CharField(required=False, allow_blank=True, default='')
    device_id = serializers.CharField(required=False, allow_blank=True, default='')
    app_version = serializers.CharField(required=False, allow_blank=True, default='')

class TestTelegramSerializer(serializers.Serializer):
    chat_id = serializers.CharField(required=False, allow_blank=True)
