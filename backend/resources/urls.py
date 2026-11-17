from django.urls import path
from .views import (
    ResourceListView,
    ResourceDetailView,
    ResourceCostDetailView,
    StopResourceView,
    DeleteResourceView
)

urlpatterns = [
    path('', ResourceListView.as_view(), name='resource_list'),
    path('<uuid:pk>/', ResourceDetailView.as_view(), name='resource_detail'),
    path('<uuid:pk>/cost/', ResourceCostDetailView.as_view(), name='resource_cost_detail'),
    path('<uuid:pk>/stop/', StopResourceView.as_view(), name='resource_stop'),
    path('<uuid:pk>/delete/', DeleteResourceView.as_view(), name='resource_delete'),
]

