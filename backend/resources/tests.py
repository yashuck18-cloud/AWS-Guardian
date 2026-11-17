from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status
from aws_accounts.models import AWSAccount
from resources.models import Resource

User = get_user_model()

class ResourceActionTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(email='res@example.com', name='Res User', password='Password123!')
        self.other_user = User.objects.create_user(email='other@example.com', name='Other User', password='Password123!')
        
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
            name='WebServer',
            region='ap-south-1',
            state='running'
        )

        self.client = APIClient()
        self.client.force_authenticate(user=self.user)

        self.other_client = APIClient()
        self.other_client.force_authenticate(user=self.other_user)

    def test_safe_stop_instance(self):
        resp = self.client.post(f'/api/resources/{self.resource.id}/stop/', {'confirm': True}, format='json')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.resource.refresh_from_db()
        self.assertEqual(self.resource.state, 'stopping')

    def test_delete_resource_typed_id_mismatch(self):
        # Must fail when typed ID does not match
        resp = self.client.post(f'/api/resources/{self.resource.id}/delete/', {'confirm_resource_id': 'wrong-id'}, format='json')
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertTrue(Resource.objects.filter(id=self.resource.id).exists())

    def test_delete_resource_typed_id_matches(self):
        # Succeeds when typed ID matches exact resource_id
        resp = self.client.post(f'/api/resources/{self.resource.id}/delete/', {'confirm_resource_id': 'i-0123456789abcdef0'}, format='json')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertFalse(Resource.objects.filter(id=self.resource.id).exists())

    def test_other_user_cannot_access_or_stop_resource(self):
        resp = self.other_client.post(f'/api/resources/{self.resource.id}/stop/', {'confirm': True}, format='json')
        self.assertEqual(resp.status_code, status.HTTP_404_NOT_FOUND)
