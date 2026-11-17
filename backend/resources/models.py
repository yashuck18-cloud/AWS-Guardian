from django.db import models
import uuid

class Resource(models.Model):
    SERVICE_CHOICES = [
        ('EC2', 'EC2 Instance'),
        ('EBS', 'EBS Volume'),
        ('SG', 'Security Group'),
        ('RDS', 'RDS Database'),
        ('S3', 'S3 Bucket'),
        ('ELB', 'Elastic Load Balancer'),
        ('EIP', 'Elastic IP'),
        ('NAT', 'NAT Gateway'),
    ]

    RISK_CHOICES = [
        ('NONE', 'None'),
        ('LOW', 'Low Risk'),
        ('MEDIUM', 'Medium Risk'),
        ('HIGH', 'High Risk'),
        ('CRITICAL', 'Critical Risk'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    account = models.ForeignKey('aws_accounts.AWSAccount', on_delete=models.CASCADE, related_name='resources')
    service = models.CharField(max_length=20, choices=SERVICE_CHOICES, db_index=True)
    resource_id = models.CharField(max_length=128, db_index=True)
    name = models.CharField(max_length=256, blank=True, default='')
    region = models.CharField(max_length=64, db_index=True)
    state = models.CharField(max_length=64, db_index=True)
    resource_type = models.CharField(max_length=64, blank=True, default='')
    
    risk_level = models.CharField(max_length=20, choices=RISK_CHOICES, default='NONE', db_index=True)
    risk_reason = models.TextField(blank=True, default='')
    
    # Cost impact estimation (hourly in USD)
    estimated_hourly_cost = models.DecimalField(max_digits=10, decimal_places=4, default=0.0)

    # Detailed metadata from AWS SDK
    metadata = models.JSONField(default=dict, blank=True)
    
    last_seen_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'guardian_resources'
        unique_together = ('account', 'service', 'resource_id', 'region')
        ordering = ['-updated_at']
        indexes = [
            models.Index(fields=['account', 'service']),
            models.Index(fields=['account', 'risk_level']),
            models.Index(fields=['account', 'state']),
            models.Index(fields=['account', 'region']),
        ]

    def __str__(self):
        return f"[{self.service}] {self.name or self.resource_id} ({self.region}) - {self.risk_level}"


class ResourceCost(models.Model):
    BILLING_STATUS_CHOICES = [
        ('ACTUAL', 'Actual Billed Cost'),
        ('ESTIMATED', 'Current Estimated Cost'),
        ('PRICING_ESTIMATE', 'Pricing-Based Estimate'),
        ('UNAVAILABLE', 'Cost Unavailable'),
    ]

    COST_SOURCE_CHOICES = [
        ('AWS_COST_EXPLORER', 'AWS Cost Explorer'),
        ('AWS_BILLING', 'AWS Billing API'),
        ('AWS_PRICING', 'AWS Pricing API'),
        ('RESOURCE_API', 'Resource Configuration API'),
        ('CALCULATED', 'Authoritative Calculation'),
        ('UNAVAILABLE', 'Unavailable'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    resource = models.ForeignKey(Resource, on_delete=models.CASCADE, related_name='cost_records', null=True, blank=True)
    account = models.ForeignKey('aws_accounts.AWSAccount', on_delete=models.CASCADE, related_name='cost_records')
    aws_resource_id = models.CharField(max_length=128, db_index=True)
    resource_type = models.CharField(max_length=64, blank=True, default='')
    region = models.CharField(max_length=64, db_index=True, default='')
    service = models.CharField(max_length=32, db_index=True)

    billing_period_start = models.DateTimeField(null=True, blank=True)
    billing_period_end = models.DateTimeField(null=True, blank=True)

    actual_cost = models.DecimalField(max_digits=12, decimal_places=4, default=0.0)
    estimated_cost = models.DecimalField(max_digits=12, decimal_places=4, default=0.0)
    currency = models.CharField(max_length=10, default='USD')

    pricing_rate = models.DecimalField(max_digits=12, decimal_places=6, default=0.0)
    pricing_unit = models.CharField(max_length=32, default='Hrs')
    usage_quantity = models.DecimalField(max_digits=16, decimal_places=4, default=0.0)
    usage_unit = models.CharField(max_length=32, default='Hrs')

    cost_source = models.CharField(max_length=32, choices=COST_SOURCE_CHOICES, default='AWS_PRICING')
    billing_status = models.CharField(max_length=32, choices=BILLING_STATUS_CHOICES, default='PRICING_ESTIMATE', db_index=True)

    notes = models.TextField(blank=True, default='')
    last_updated = models.DateTimeField(auto_now=True, db_index=True)

    class Meta:
        db_table = 'guardian_resource_costs'
        ordering = ['-last_updated']
        indexes = [
            models.Index(fields=['account', 'service']),
            models.Index(fields=['account', 'billing_status']),
            models.Index(fields=['aws_resource_id', 'last_updated']),
        ]

    @property
    def resource_id(self):
        return self.aws_resource_id

    def __str__(self):
        return f"Cost [{self.service}] {self.aws_resource_id} - {self.billing_status} ({self.currency} {self.actual_cost or self.estimated_cost})"


