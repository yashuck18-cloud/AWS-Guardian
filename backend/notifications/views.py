from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from django.utils import timezone
from .models import NotificationSettings, NotificationHistory, FCMDevice
from .serializers import (
    NotificationSettingsSerializer,
    NotificationHistorySerializer,
    TestTelegramSerializer,
    FCMDeviceSerializer,
    DeviceRegistrationSerializer
)
from .telegram_service import send_telegram_message
from .firebase_service import send_fcm_to_user
from .dispatcher import dispatch_summary_notification
from audit.logger import log_audit_event

class NotificationSettingsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        settings_obj, _ = NotificationSettings.objects.get_or_create(user=request.user)
        return Response({
            'success': True,
            'settings': NotificationSettingsSerializer(settings_obj).data
        })

    def patch(self, request):
        settings_obj, _ = NotificationSettings.objects.get_or_create(user=request.user)
        serializer = NotificationSettingsSerializer(settings_obj, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response({
                'success': True,
                'message': 'Notification settings updated.',
                'settings': serializer.data
            })
        return Response({
            'success': False,
            'message': 'Invalid settings data.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)


class NotificationHistoryListView(generics.ListAPIView):
    serializer_class = NotificationHistorySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return NotificationHistory.objects.filter(user=self.request.user)


class FCMDeviceRegistrationView(APIView):
    """
    Registers or updates an FCM device token for the authenticated user.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = DeviceRegistrationSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({
                'success': False,
                'message': 'Invalid registration payload.',
                'errors': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)

        fcm_token = serializer.validated_data['fcm_token']
        platform = serializer.validated_data.get('platform', 'android')
        device_name = serializer.validated_data.get('device_name', '')
        device_id = serializer.validated_data.get('device_id', '')
        app_version = serializer.validated_data.get('app_version', '')

        # Strict user isolation:
        # If this fcm_token or device_id was previously linked to another user,
        # deactivate those records so notifications are never misrouted.
        if device_id:
            FCMDevice.objects.filter(device_id=device_id).exclude(user=request.user).update(
                is_active=False,
                updated_at=timezone.now()
            )
        FCMDevice.objects.filter(fcm_token=fcm_token).exclude(user=request.user).update(
            is_active=False,
            updated_at=timezone.now()
        )

        # Get or create active device for current user
        device = FCMDevice.objects.filter(user=request.user, fcm_token=fcm_token).first()
        if not device and device_id:
            device = FCMDevice.objects.filter(user=request.user, device_id=device_id).first()

        if device:
            device.user = request.user
            device.fcm_token = fcm_token
            device.platform = platform
            if device_name:
                device.device_name = device_name
            if device_id:
                device.device_id = device_id
            if app_version:
                device.app_version = app_version
            device.is_active = True
            device.last_seen = timezone.now()
            device.save()
        else:
            # Create new device for this user
            device = FCMDevice.objects.create(
                user=request.user,
                fcm_token=fcm_token,
                platform=platform,
                device_name=device_name,
                device_id=device_id,
                app_version=app_version,
                is_active=True
            )

        log_audit_event(
            request.user,
            'DEVICE_REGISTERED',
            {
                'device_id': str(device.id),
                'platform': device.platform,
                'device_name': device.device_name
            }
        )

        return Response({
            'success': True,
            'message': 'FCM Device registered successfully.',
            'device': FCMDeviceSerializer(device).data
        }, status=status.HTTP_200_OK)


class FCMDeviceDeactivateView(APIView):
    """
    Deactivates an FCM device upon user logout.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        fcm_token = request.data.get('fcm_token')
        device_id = request.data.get('device_id')

        qs = FCMDevice.objects.filter(user=request.user)
        if fcm_token:
            qs = qs.filter(fcm_token=fcm_token)
        elif device_id:
            qs = qs.filter(device_id=device_id)
        else:
            return Response({
                'success': False,
                'message': 'Either fcm_token or device_id is required.'
            }, status=status.HTTP_400_BAD_REQUEST)

        updated = qs.update(is_active=False, updated_at=timezone.now())

        return Response({
            'success': True,
            'message': f'{updated} device(s) deactivated successfully.'
        })


class FCMDeviceListView(generics.ListAPIView):
    """
    Lists active FCM devices for the authenticated user.
    """
    serializer_class = FCMDeviceSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return FCMDevice.objects.filter(user=self.request.user, is_active=True)


class TestFCMNotificationView(APIView):
    """
    Sends a test FCM notification from Django to the authenticated user's registered devices.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        devices = FCMDevice.objects.filter(user=request.user, is_active=True)
        if not devices.exists():
            return Response({
                'success': False,
                'message': 'No active devices registered for your account. Please log into the mobile app to register.'
            }, status=status.HTTP_400_BAD_REQUEST)

        title = "AWS Guardian Test"
        body = "Django → FCM notification is working!"
        data = {
            'type': 'test_notification',
            'action': 'open_app',
            'timestamp': timezone.now().isoformat()
        }

        success_count, fail_count = send_fcm_to_user(
            user=request.user,
            title=title,
            body=body,
            data=data,
            notification_type="test"
        )

        if success_count > 0:
            return Response({
                'success': True,
                'message': f'Test notification sent successfully to {success_count} device(s).',
                'success_count': success_count,
                'fail_count': fail_count
            })
        else:
            return Response({
                'success': False,
                'message': 'Failed to deliver notification. Check Firebase Admin SDK credentials or device token.',
                'fail_count': fail_count
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class TestTelegramNotificationView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = TestTelegramSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({'success': False, 'errors': serializer.errors}, status=status.HTTP_400_BAD_REQUEST)

        settings_obj, _ = NotificationSettings.objects.get_or_create(user=request.user)
        chat_id = serializer.validated_data.get('chat_id') or settings_obj.telegram_chat_id

        if not chat_id:
            return Response({
                'success': False,
                'message': 'Please provide a Telegram Chat ID.'
            }, status=status.HTTP_400_BAD_REQUEST)

        test_msg = (
            "🛡️ *AWS GUARDIAN TEST NOTIFICATION*\n\n"
            "Your Telegram integration with AWS Guardian is working properly!\n"
            "You will receive automated morning & evening resource summaries here."
        )

        success, msg = send_telegram_message(chat_id, test_msg)

        NotificationHistory.objects.create(
            user=request.user,
            title="Test Telegram Notification",
            message=test_msg,
            channel='TELEGRAM',
            status='SENT' if success else 'FAILED',
            error_details='' if success else msg
        )

        if success:
            return Response({'success': True, 'message': 'Test notification sent successfully to Telegram.'})
        return Response({'success': False, 'message': msg}, status=status.HTTP_400_BAD_REQUEST)


class TriggerSummaryNotificationView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        summary_type = request.data.get('type', 'Manual')
        success, message_text = dispatch_summary_notification(request.user, summary_type=summary_type)
        return Response({
            'success': True,
            'message': 'Summary notification triggered.',
            'summary': message_text
        })
