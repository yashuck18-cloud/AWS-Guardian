from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status
from aws_accounts.models import AWSAccount
from resources.models import Resource
from alerts.models import Alert
from alerts.deduplicator import sync_resource_alerts
from rules.engine import RuleEvaluationResult

User = get_user_model()

class AlertDeduplicationTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(email='alerts@example.com', name='Alert Tester', password='Pass!')
        self.account = AWSAccount.objects.create(
            user=self.user,
            name='Prod',
            account_id='123456789012',
            role_arn='arn:aws:iam::123456789012:role/AWSGuardianDemoRole'
        )
        self.resource = Resource.objects.create(
            account=self.account,
            service='EC2',
            resource_id='i-0123456789abcdef0',
            region='ap-south-1',
            state='running'
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)

    def test_alert_deduplication_keeps_single_active_alert(self):
        eval_result = RuleEvaluationResult(
            risk_level='HIGH',
            risk_reason='Long running instance',
            title='EC2 Threshold Exceeded',
            description='Test description',
            rule_code='EC2_RUNNING_THRESHOLD_EXCEEDED',
            cost_impact=30.0
        )

        # Scan 1: creates alert
        new_alert, updated, resolved = sync_resource_alerts(self.account, self.resource, eval_result)
        self.assertIsNotNone(new_alert)
        self.assertEqual(Alert.objects.filter(account=self.account, resource=self.resource).count(), 1)

        # Scan 2: condition persists -> should update existing alert, NOT create new row
        new_alert2, updated2, resolved2 = sync_resource_alerts(self.account, self.resource, eval_result)
        self.assertIsNone(new_alert2)
        self.assertIsNotNone(updated2)
        self.assertEqual(Alert.objects.filter(account=self.account, resource=self.resource).count(), 1)

    def test_alert_resolution_when_condition_clears(self):
        eval_result = RuleEvaluationResult(
            risk_level='HIGH',
            title='EC2 Threshold Exceeded',
            description='Test description',
            rule_code='EC2_RUNNING_THRESHOLD_EXCEEDED'
        )
        sync_resource_alerts(self.account, self.resource, eval_result)
        self.assertEqual(Alert.objects.filter(status='ACTIVE').count(), 1)

        # Next scan: condition cleared
        clear_result = RuleEvaluationResult(risk_level='NONE')
        sync_resource_alerts(self.account, self.resource, clear_result)
        self.assertEqual(Alert.objects.filter(status='ACTIVE').count(), 0)
        self.assertEqual(Alert.objects.filter(status='RESOLVED').count(), 1)

    def test_alert_acknowledge_and_resolve_endpoints(self):
        alert = Alert.objects.create(
            account=self.account,
            resource=self.resource,
            rule_code='EC2_TEST',
            title='Test Alert',
            description='Details',
            severity='HIGH',
            status='ACTIVE'
        )

        ack_resp = self.client.post(f'/api/alerts/{alert.id}/acknowledge/')
        self.assertEqual(ack_resp.status_code, status.HTTP_200_OK)
        alert.refresh_from_db()
        self.assertEqual(alert.status, 'ACKNOWLEDGED')

        res_resp = self.client.post(f'/api/alerts/{alert.id}/resolve/')
        self.assertEqual(res_resp.status_code, status.HTTP_200_OK)
        alert.refresh_from_db()
        self.assertEqual(alert.status, 'RESOLVED')
