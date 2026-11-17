from django.db import models
from django.conf import settings
import uuid

class NotificationSettings(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='notification_settings')
    
    morning_summary_enabled = models.BooleanField(default=True)
    morning_summary_time = models.CharField(max_length=10, default='09:00')
    
    evening_summary_enabled = models.BooleanField(default=True)
    evening_summary_time = models.CharField(max_length=10, default='19:00')
    
    urgent_alerts_enabled = models.BooleanField(default=True)
    timezone = models.CharField(max_length=64, default='UTC')
    
    telegram_enabled = models.BooleanField(default=False)
    telegram_chat_id = models.CharField(max_length=64, blank=True, default='')

    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'guardian_notification_settings'

    def __str__(self):
        return f"NotificationSettings for {self.user.email}"


class FCMDevice(models.Model):
    PLATFORM_CHOICES = [
        ('android', 'Android'),
        ('ios', 'iOS'),
        ('web', 'Web'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='fcm_devices')
    fcm_token = models.TextField(help_text='Firebase Cloud Messaging Registration Token')
    platform = models.CharField(max_length=20, choices=PLATFORM_CHOICES, default='android')
    device_name = models.CharField(max_length=150, blank=True, default='')
    device_id = models.CharField(max_length=150, blank=True, default='', db_index=True)
    app_version = models.CharField(max_length=50, blank=True, default='')
    is_active = models.BooleanField(default=True, db_index=True)
    last_seen = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'guardian_notification_devices'
        ordering = ['-last_seen']
        indexes = [
            models.Index(fields=['user', 'is_active']),
            models.Index(fields=['platform', 'is_active']),
        ]

    def __str__(self):
        return f"{self.user.email} - {self.device_name or self.platform} ({'Active' if self.is_active else 'Inactive'})"


class NotificationHistory(models.Model):
    CHANNEL_CHOICES = [
        ('FCM', 'Push Notification (FCM)'),
        ('TELEGRAM', 'Telegram'),
        ('IN_APP', 'In-App'),
        ('EMAIL', 'Email'),
    ]

    STATUS_CHOICES = [
        ('SENT', 'Sent'),
        ('FAILED', 'Failed'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='notification_history')
    device = models.ForeignKey(FCMDevice, on_delete=models.SET_NULL, null=True, blank=True, related_name='notification_history')
    title = models.CharField(max_length=256)
    message = models.TextField()
    channel = models.CharField(max_length=20, choices=CHANNEL_CHOICES, default='FCM')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='SENT')
    error_details = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'guardian_notification_history'
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.channel}] {self.title} to {self.user.email} - {self.status}"
