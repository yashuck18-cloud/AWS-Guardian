from django.db import models
import uuid

class Alert(models.Model):
    SEVERITY_CHOICES = [
        ('LOW', 'Low Risk'),
        ('MEDIUM', 'Medium Risk'),
        ('HIGH', 'High Risk'),
        ('CRITICAL', 'Critical Risk'),
    ]

    STATUS_CHOICES = [
        ('ACTIVE', 'Active'),
        ('ACKNOWLEDGED', 'Acknowledged'),
        ('RESOLVED', 'Resolved'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    account = models.ForeignKey('aws_accounts.AWSAccount', on_delete=models.CASCADE, related_name='alerts')
    resource = models.ForeignKey('resources.Resource', on_delete=models.CASCADE, related_name='alerts', null=True, blank=True)
    
    rule_code = models.CharField(max_length=64, db_index=True)
    title = models.CharField(max_length=256)
    description = models.TextField()
    severity = models.CharField(max_length=20, choices=SEVERITY_CHOICES, default='HIGH', db_index=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='ACTIVE', db_index=True)
    
    # Cost impact (monthly estimate in USD)
    estimated_cost_impact = models.DecimalField(max_digits=10, decimal_places=2, default=0.0)

    first_detected_at = models.DateTimeField(auto_now_add=True)
    last_detected_at = models.DateTimeField(auto_now=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'guardian_alerts'
        ordering = ['-last_detected_at']
        indexes = [
            models.Index(fields=['account', 'status']),
            models.Index(fields=['account', 'severity']),
            models.Index(fields=['account', 'status', 'severity']),
            models.Index(fields=['account', 'last_detected_at']),
        ]

    def __str__(self):
        return f"[{self.severity}] {self.title} - {self.status}"
