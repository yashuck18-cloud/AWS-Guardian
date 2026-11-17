from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status
from .models import AWSAccount
from .sts_service import validate_role_arn, verify_aws_role

User = get_user_model()

class AWSAccountTests(TestCase):
    def setUp(self):
        self.user1 = User.objects.create_user(email='user1@example.com', name='User One', password='Password123!')
        self.user2 = User.objects.create_user(email='user2@example.com', name='User Two', password='Password123!')
        
        self.client1 = APIClient()
        self.client1.force_authenticate(user=self.user1)

        self.client2 = APIClient()
        self.client2.force_authenticate(user=self.user2)

    def test_role_arn_validator(self):
        valid_arn = "arn:aws:iam::123456789012:role/AWSGuardianRole"
        data, err = validate_role_arn(valid_arn)
        self.assertIsNone(err)
        self.assertEqual(data['account_id'], '123456789012')
        self.assertEqual(data['role_name'], 'AWSGuardianRole')

        invalid_arn = "invalid:arn:format"
        data, err = validate_role_arn(invalid_arn)
        self.assertIsNotNone(err)

    def test_demo_role_verification(self):
        is_success, acc_id, role_name, err = verify_aws_role(
            role_arn="arn:aws:iam::123456789012:role/AWSGuardianDemoRole",
            external_id="guardian-123456",
            expected_account_id="123456789012"
        )
        self.assertTrue(is_success)
        self.assertEqual(acc_id, '123456789012')

    def test_multi_tenant_isolation_aws_accounts(self):
        # User 1 creates account
        acc1 = AWSAccount.objects.create(
            user=self.user1,
            name='User1 Prod',
            account_id='111122223333',
            role_arn='arn:aws:iam::111122223333:role/AWSGuardianDemoRole'
        )

        # User 2 lists accounts - should NOT see User 1's account
        resp2 = self.client2.get('/api/aws-accounts/')
        self.assertEqual(resp2.status_code, status.HTTP_200_OK)
        ids = [a['id'] for a in resp2.data.get('results', resp2.data)]
        self.assertNotIn(str(acc1.id), ids)

        # User 2 attempts direct access to User 1's account
        detail_resp = self.client2.get(f'/api/aws-accounts/{acc1.id}/')
        self.assertEqual(detail_resp.status_code, status.HTTP_404_NOT_FOUND)
