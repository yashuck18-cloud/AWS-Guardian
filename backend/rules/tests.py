from django.test import TestCase
from django.contrib.auth import get_user_model
from datetime import datetime, timezone, timedelta
from aws_accounts.models import AWSAccount
from resources.models import Resource
from .engine import evaluate_resource_rules

User = get_user_model()

class RuleEngineTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(email='rules@example.com', name='Rule Tester', password='Pass!')
        self.account = AWSAccount.objects.create(
            user=self.user,
            name='Test Env',
            account_id='123456789012',
            role_arn='arn:aws:iam::123456789012:role/AWSGuardianDemoRole'
        )

    def test_ec2_long_running_rule(self):
        now = datetime.now(timezone.utc)
        # Running for 10 days
        launch_time = (now - timedelta(days=10)).isoformat()
        
        resource = Resource.objects.create(
            account=self.account,
            service='EC2',
            resource_id='i-0123456789abcdef0',
            region='ap-south-1',
            state='running',
            estimated_hourly_cost=0.0416,
            metadata={'launch_time': launch_time}
        )

        result = evaluate_resource_rules(resource, {'ec2_threshold_hours': 24})
        self.assertEqual(result.risk_level, 'CRITICAL')
        self.assertEqual(result.rule_code, 'EC2_RUNNING_LONG_TERM')
        self.assertIn('May require review', result.risk_reason)

    def test_ebs_unattached_rule(self):
        now = datetime.now(timezone.utc)
        create_time = (now - timedelta(days=5)).isoformat()

        resource = Resource.objects.create(
            account=self.account,
            service='EBS',
            resource_id='vol-0987654321fedcba0',
            region='ap-south-1',
            state='available',
            estimated_hourly_cost=0.0109,
            metadata={'create_time': create_time, 'is_attached': False}
        )

        result = evaluate_resource_rules(resource, {'ebs_threshold_hours': 24})
        self.assertEqual(result.risk_level, 'HIGH')
        self.assertEqual(result.rule_code, 'EBS_UNATTACHED_VOLUME')

    def test_eip_unassociated_rule(self):
        resource = Resource.objects.create(
            account=self.account,
            service='EIP',
            resource_id='eipalloc-123456',
            region='ap-south-1',
            state='unassociated',
            estimated_hourly_cost=0.0050,
            metadata={'is_associated': False}
        )

        result = evaluate_resource_rules(resource)
        self.assertEqual(result.risk_level, 'HIGH')
        self.assertEqual(result.rule_code, 'EIP_UNASSOCIATED')
