from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status
from aws_accounts.models import AWSAccount
from resources.models import Resource
from alerts.models import Alert

User = get_user_model()

class AdminPanelApiTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.admin_user = User.objects.create_superuser(
            email='admin@awsguardian.com',
            name='Admin User',
            password='AdminPassword123!'
        )
        self.regular_user = User.objects.create_user(
            email='dev@awsguardian.com',
            name='Dev User',
            password='DevPassword123!'
        )

        # Login admin to obtain JWT
        res = self.client.post('/api/auth/login/', {
            'email': 'admin@awsguardian.com',
            'password': 'AdminPassword123!'
        })
        self.admin_token = res.data['token']

        # Login regular user
        res2 = self.client.post('/api/auth/login/', {
            'email': 'dev@awsguardian.com',
            'password': 'DevPassword123!'
        })
        self.regular_token = res2.data['token']

    def test_admin_dashboard_stats_authorized(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.admin_token}')
        res = self.client.get('/api/admin/dashboard/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertTrue(res.data['success'])
        self.assertIn('stats', res.data)
        self.assertEqual(res.data['stats']['total_users'], 2)

    def test_admin_dashboard_forbidden_for_regular_user(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.regular_token}')
        res = self.client.get('/api/admin/dashboard/')
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_admin_users_list_and_toggle(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.admin_token}')
        res = self.client.get('/api/admin/users/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['count'], 2)

        # Toggle regular user status
        toggle_res = self.client.post(f'/api/admin/users/{self.regular_user.id}/toggle-status/')
        self.assertEqual(toggle_res.status_code, status.HTTP_200_OK)
        self.regular_user.refresh_from_db()
        self.assertFalse(self.regular_user.is_active)

    def test_admin_system_health(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.admin_token}')
        res = self.client.get('/api/admin/system-health/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res.data['components']), 4)
