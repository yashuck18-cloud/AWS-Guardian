from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status
from audit.models import AuditLog
from audit.logger import log_audit_event, sanitize_details

User = get_user_model()

class AuditLogTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(email='audit@example.com', name='Audit User', password='Password123!')
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)

    def test_sanitize_sensitive_details(self):
        raw = {
            'account_id': '123456789012',
            'password': 'secret_password_123',
            'session_token': 'secret_token_abc',
            'nested': {
                'bot_token': 'tg_123',
                'regular_field': 'hello'
            }
        }
        clean = sanitize_details(raw)
        self.assertEqual(clean['password'], '[REDACTED]')
        self.assertEqual(clean['session_token'], '[REDACTED]')
        self.assertEqual(clean['nested']['bot_token'], '[REDACTED]')
        self.assertEqual(clean['nested']['regular_field'], 'hello')

    def test_audit_event_logged_and_queried(self):
        log_audit_event(self.user, 'SCAN_STARTED', {'account_id': '123456789012'})
        self.assertEqual(AuditLog.objects.filter(user=self.user, action='SCAN_STARTED').count(), 1)

        resp = self.client.get('/api/audit/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        results = resp.data.get('results', resp.data)
        self.assertEqual(len(results), 1)
