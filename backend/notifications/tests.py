from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status
from unittest.mock import patch, MagicMock
from aws_accounts.models import AWSAccount
from resources.models import Resource
from alerts.models import Alert
from notifications.models import NotificationSettings, NotificationHistory, FCMDevice
from notifications.dispatcher import generate_user_alert_summary, dispatch_summary_notification, dispatch_urgent_alert_notification
from notifications.firebase_service import send_fcm_notification, send_fcm_to_user

User = get_user_model()

class NotificationTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(email='notif@example.com', name='Notif User', password='Password123!')
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)

        self.account = AWSAccount.objects.create(
            user=self.user,
            name='Prod',
            account_id='123456789012',
            role_arn='arn:aws:iam::123456789012:role/AWSGuardianDemoRole'
        )
        self.res = Resource.objects.create(
            account=self.account,
            service='EC2',
            resource_id='i-012345',
            region='ap-south-1',
            state='running'
        )
        self.alert = Alert.objects.create(
            account=self.account,
            resource=self.res,
            rule_code='EC2_TEST',
            title='EC2 Alert',
            description='Test',
            severity='HIGH',
            status='ACTIVE'
        )

    def test_summary_message_generation(self):
        msg, count = generate_user_alert_summary(self.user, summary_type="Morning")
        self.assertEqual(count, 1)
        self.assertIn("1 resources require attention", msg)
        self.assertIn("EC2: 1", msg)

    def test_dispatch_summary_and_record_history(self):
        success, msg = dispatch_summary_notification(self.user, summary_type="Morning")
        self.assertTrue(success)
        self.assertEqual(NotificationHistory.objects.filter(user=self.user, channel='IN_APP').count(), 1)

    def test_telegram_test_notification_endpoint(self):
        resp = self.client.post('/api/notifications/test-telegram/', {'chat_id': '123456789'}, format='json')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertTrue(resp.data['success'])

    def test_fcm_device_registration_endpoint(self):
        payload = {
            'fcm_token': 'test-fcm-token-12345',
            'platform': 'android',
            'device_name': 'Pixel 8',
            'device_id': 'dev-id-999',
            'app_version': '1.0.0'
        }
        resp = self.client.post('/api/notifications/devices/register/', payload, format='json')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertTrue(resp.data['success'])
        
        device = FCMDevice.objects.get(fcm_token='test-fcm-token-12345')
        self.assertEqual(device.user, self.user)
        self.assertEqual(device.platform, 'android')
        self.assertEqual(device.device_name, 'Pixel 8')
        self.assertTrue(device.is_active)

    def test_fcm_device_deactivate_endpoint(self):
        device = FCMDevice.objects.create(
            user=self.user,
            fcm_token='deactivate-token-999',
            platform='android',
            is_active=True
        )
        resp = self.client.post('/api/notifications/devices/deactivate/', {'fcm_token': 'deactivate-token-999'}, format='json')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertTrue(resp.data['success'])
        device.refresh_from_db()
        self.assertFalse(device.is_active)

    @patch('notifications.firebase_service.messaging.send')
    @patch('notifications.firebase_service.get_firebase_app')
    def test_fcm_send_notification_success(self, mock_app, mock_send):
        mock_app.return_value = MagicMock()
        mock_send.return_value = "projects/aws-guardian/messages/12345"

        device = FCMDevice.objects.create(
            user=self.user,
            fcm_token='valid-fcm-token',
            platform='android',
            is_active=True
        )

        success, res = send_fcm_notification(device, "Alert Title", "Alert Body", {'route': '/alerts/123'})
        self.assertTrue(success)
        self.assertIn("projects/aws-guardian/messages", res)
        self.assertTrue(NotificationHistory.objects.filter(user=self.user, channel='FCM', status='SENT').exists())

    @patch('notifications.firebase_service.messaging.send')
    @patch('notifications.firebase_service.get_firebase_app')
    def test_fcm_send_to_user(self, mock_app, mock_send):
        mock_app.return_value = MagicMock()
        mock_send.return_value = "projects/aws-guardian/messages/999"

        FCMDevice.objects.create(
            user=self.user,
            fcm_token='phone-1-token',
            platform='android',
            device_name='Phone 1',
            is_active=True
        )
        FCMDevice.objects.create(
            user=self.user,
            fcm_token='phone-2-token',
            platform='android',
            device_name='Phone 2',
            is_active=True
        )

        success_count, fail_count = send_fcm_to_user(self.user, "Test Title", "Test Body")
        self.assertEqual(success_count, 2)
        self.assertEqual(fail_count, 0)
