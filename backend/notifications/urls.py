from django.urls import path
from .views import (
    NotificationSettingsView,
    NotificationHistoryListView,
    TestTelegramNotificationView,
    TriggerSummaryNotificationView,
    FCMDeviceRegistrationView,
    FCMDeviceDeactivateView,
    FCMDeviceListView,
    TestFCMNotificationView,
)

urlpatterns = [
    path('settings/', NotificationSettingsView.as_view(), name='notification_settings'),
    path('history/', NotificationHistoryListView.as_view(), name='notification_history'),
    path('devices/', FCMDeviceListView.as_view(), name='device_list'),
    path('devices/register/', FCMDeviceRegistrationView.as_view(), name='device_register'),
    path('devices/deactivate/', FCMDeviceDeactivateView.as_view(), name='device_deactivate'),
    path('register-device/', FCMDeviceRegistrationView.as_view(), name='device_register_alias'),
    path('test-fcm/', TestFCMNotificationView.as_view(), name='test_fcm'),
    path('test-telegram/', TestTelegramNotificationView.as_view(), name='test_telegram'),
    path('send-summary/', TriggerSummaryNotificationView.as_view(), name='send_summary'),
]
