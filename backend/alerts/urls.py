from django.urls import path
from .views import (
    AlertListView,
    AlertDetailView,
    AlertAcknowledgeView,
    AlertResolveView
)

urlpatterns = [
    path('', AlertListView.as_view(), name='alert_list'),
    path('<uuid:pk>/', AlertDetailView.as_view(), name='alert_detail'),
    path('<uuid:pk>/acknowledge/', AlertAcknowledgeView.as_view(), name='alert_acknowledge'),
    path('<uuid:pk>/resolve/', AlertResolveView.as_view(), name='alert_resolve'),
]
