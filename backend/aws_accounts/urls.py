from django.urls import path
from .views import (
    AWSAccountListCreateView,
    AWSAccountDetailView,
    GenerateExternalIdView,
    VerifyAccountConnectionView
)

urlpatterns = [
    path('', AWSAccountListCreateView.as_view(), name='aws_account_list_create'),
    path('generate-external-id/', GenerateExternalIdView.as_view(), name='generate_external_id'),
    path('verify/', VerifyAccountConnectionView.as_view(), name='verify_account_unpersisted'),
    path('<uuid:pk>/', AWSAccountDetailView.as_view(), name='aws_account_detail'),
    path('<uuid:pk>/verify/', VerifyAccountConnectionView.as_view(), name='verify_account'),
]
