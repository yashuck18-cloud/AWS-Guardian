from django.urls import path
from .views import TriggerScanView, ScanHistoryListView, ScanDetailView

urlpatterns = [
    path('scan/', TriggerScanView.as_view(), name='trigger_scan'),
    path('history/', ScanHistoryListView.as_view(), name='scan_history'),
    path('history/<uuid:pk>/', ScanDetailView.as_view(), name='scan_detail'),
]
