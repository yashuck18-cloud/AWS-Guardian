from django.db import models
import uuid

class Scan(models.Model):
    STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('IN_PROGRESS', 'In Progress'),
        ('COMPLETED', 'Completed'),
        ('FAILED', 'Failed'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    account = models.ForeignKey('aws_accounts.AWSAccount', on_delete=models.CASCADE, related_name='scans')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING', db_index=True)
    
    started_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    resources_found = models.IntegerField(default=0)
    alerts_created = models.IntegerField(default=0)
    alerts_resolved = models.IntegerField(default=0)
    warnings_count = models.IntegerField(default=0)
    
    scanned_regions = models.JSONField(default=list, blank=True)
    service_errors = models.JSONField(default=dict, blank=True)
    error_message = models.TextField(blank=True, default='')

    # Notification tracking
    notification_sent = models.BooleanField(default=False, db_index=True)
    notification_status = models.CharField(max_length=50, default='NOT_SENT', db_index=True)
    notification_title = models.CharField(max_length=256, blank=True, default='')
    notification_message = models.TextField(blank=True, default='')
    trigger_source = models.CharField(max_length=50, default='MANUAL', db_index=True)

    class Meta:
        db_table = 'guardian_scans'
        ordering = ['-started_at']
        indexes = [
            models.Index(fields=['account', 'started_at']),
        ]

    def __str__(self):
        return f"Scan {self.account.name} - {self.status} ({self.resources_found} resources)"
