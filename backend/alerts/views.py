from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.utils import timezone
from users.utils import is_valid_uuid
from .models import Alert
from .serializers import AlertSerializer
from audit.logger import log_audit_event

class AlertListView(generics.ListAPIView):
    serializer_class = AlertSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Strict tenant isolation with preloaded account and resource foreign keys
        queryset = Alert.objects.filter(account__user=self.request.user).select_related('account', 'resource')

        account_id = self.request.query_params.get('account')
        if account_id and is_valid_uuid(account_id):
            queryset = queryset.filter(account__id=account_id)
            from aws_accounts.models import AWSAccount
            acc = AWSAccount.objects.filter(id=account_id, user=self.request.user).first()
            if acc and acc.enabled_regions and 'all' not in [r.lower() for r in acc.enabled_regions]:
                from django.db.models import Q
                queryset = queryset.filter(
                    Q(resource__region__in=acc.enabled_regions) | Q(resource__isnull=True)
                )

        region_param = self.request.query_params.get('region')
        if region_param and region_param.lower() != 'all':
            queryset = queryset.filter(resource__region__iexact=region_param.strip())

        severity = self.request.query_params.get('severity')
        if severity and severity.upper() != 'ALL':
            queryset = queryset.filter(severity=severity.upper())

        status_param = self.request.query_params.get('status')
        if status_param and status_param.upper() != 'ALL':
            queryset = queryset.filter(status=status_param.upper())

        service = self.request.query_params.get('service')
        if service and service.upper() != 'ALL':
            queryset = queryset.filter(resource__service=service.upper())

        return queryset

class AlertDetailView(generics.RetrieveAPIView):
    serializer_class = AlertSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Alert.objects.filter(account__user=self.request.user).select_related('account', 'resource')

class AlertAcknowledgeView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        alert = get_object_or_404(Alert, pk=pk, account__user=request.user)
        if alert.status == 'RESOLVED':
            return Response({
                'success': False,
                'message': 'Cannot acknowledge an alert that is already resolved.'
            }, status=status.HTTP_400_BAD_REQUEST)

        alert.status = 'ACKNOWLEDGED'
        alert.save()

        log_audit_event(
            request.user,
            'ALERT_ACKNOWLEDGED',
            {
                'alert_id': str(alert.id),
                'title': alert.title,
                'severity': alert.severity
            }
        )

        return Response({
            'success': True,
            'message': 'Alert acknowledged.',
            'alert': AlertSerializer(alert).data
        })

class AlertResolveView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        alert = get_object_or_404(Alert, pk=pk, account__user=request.user)
        alert.status = 'RESOLVED'
        alert.resolved_at = timezone.now()
        alert.save()

        log_audit_event(
            request.user,
            'ALERT_RESOLVED',
            {
                'alert_id': str(alert.id),
                'title': alert.title,
                'severity': alert.severity,
                'manually_resolved': True
            }
        )

        return Response({
            'success': True,
            'message': 'Alert marked as resolved.',
            'alert': AlertSerializer(alert).data
        })
