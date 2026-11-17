from django.db import models
from django.conf import settings
import uuid

class AuditLog(models.Model):
    ACTION_CHOICES = [
        ('AWS_ACCOUNT_CONNECTED', 'AWS Account Connected'),
        ('AWS_ACCOUNT_VERIFIED', 'AWS Account Verified'),
        ('AWS_ACCOUNT_DELETED', 'AWS Account Deleted'),
        ('SCAN_STARTED', 'Scan Started'),
        ('SCAN_COMPLETED', 'Scan Completed'),
        ('ALERT_CREATED', 'Alert Created'),
        ('ALERT_ACKNOWLEDGED', 'Alert Acknowledged'),
        ('ALERT_RESOLVED', 'Alert Resolved'),
        ('RESOURCE_STOPPED', 'Resource Stopped'),
        ('RESOURCE_DELETED', 'Resource Deleted'),
        ('NOTIFICATION_SENT', 'Notification Sent'),
        ('USER_REGISTERED', 'User Registered'),
        ('USER_ACCOUNT_DELETED', 'User Account Deleted'),
        ('SETTINGS_UPDATED', 'Settings Updated'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='audit_logs')
    action = models.CharField(max_length=64, choices=ACTION_CHOICES, db_index=True)
    details = models.JSONField(default=dict, blank=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        db_table = 'guardian_audit_logs'
        ordering = ['-timestamp']

    def __str__(self):
        return f"{self.user.email} - {self.action} at {self.timestamp}"
