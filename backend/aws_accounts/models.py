from django.db import models
from django.conf import settings
import uuid
import secrets

def generate_external_id():
    return f"guardian-{secrets.token_hex(12)}"

class AWSAccount(models.Model):
    STATUS_CHOICES = [
        ('PENDING', 'Pending Verification'),
        ('CONNECTED', 'Connected'),
        ('ERROR', 'Error'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='aws_accounts')
    name = models.CharField(max_length=120, help_text="User-friendly name (e.g., Production, Staging)")
    account_id = models.CharField(max_length=12, help_text="12-digit AWS Account ID")
    role_arn = models.CharField(max_length=256, help_text="IAM Role ARN (e.g., arn:aws:iam::123456789012:role/AWSGuardianRole)")
    external_id = models.CharField(max_length=128, blank=True, default='', help_text="Optional external ID for STS trust policy")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    last_scan_at = models.DateTimeField(null=True, blank=True)
    error_message = models.TextField(blank=True, default='')

    # Configured regions for scanning
    enabled_regions = models.JSONField(
        default=list,
        blank=True,
        help_text="List of AWS regions to scan"
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'guardian_aws_accounts'
        unique_together = ('user', 'account_id')
        ordering = ['-created_at']

    def save(self, *args, **kwargs):
        if not self.enabled_regions:
            self.enabled_regions = ['ap-south-1']
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.name} ({self.account_id}) - {self.status}"
