from django.urls import path
from .views import DashboardSummaryView, AnalyticsDataView, CostOverviewView

urlpatterns = [
    path('dashboard/', DashboardSummaryView.as_view(), name='dashboard_summary'),
    path('data/', AnalyticsDataView.as_view(), name='analytics_data'),
    path('costs/', CostOverviewView.as_view(), name='cost_overview'),
]
