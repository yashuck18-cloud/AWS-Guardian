from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from users.utils import is_valid_uuid
from aws_accounts.models import AWSAccount
from .models import Scan
from .serializers import ScanSerializer, TriggerScanRequestSerializer
from .runner import execute_account_scan, run_scan_in_background

class TriggerScanView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = TriggerScanRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({'success': False, 'errors': serializer.errors}, status=status.HTTP_400_BAD_REQUEST)

        account_id = serializer.validated_data.get('account_id')
        is_sync = serializer.validated_data.get('sync', True)

        if account_id:
            account = get_object_or_404(AWSAccount, id=account_id, user=request.user)
            accounts = [account]
        else:
            accounts = list(AWSAccount.objects.filter(user=request.user))
            if not accounts:
                return Response({
                    'success': False,
                    'message': 'No AWS accounts connected. Please connect an AWS account first.'
                }, status=status.HTTP_400_BAD_REQUEST)

        scans_results = []
        for acc in accounts:
            if is_sync:
                scan = execute_account_scan(acc.id)
                if scan:
                    scans_results.append(ScanSerializer(scan).data)
            else:
                run_scan_in_background(acc.id)

        return Response({
            'success': True,
            'message': 'Scan completed successfully.' if is_sync else 'Scan started in background.',
            'scans': scans_results
        })

class ScanHistoryListView(generics.ListAPIView):
    serializer_class = ScanSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        queryset = Scan.objects.filter(account__user=self.request.user).select_related('account')
        account_id = self.request.query_params.get('account')
        if account_id and is_valid_uuid(account_id):
            queryset = queryset.filter(account__id=account_id)
        return queryset

class ScanDetailView(generics.RetrieveAPIView):
    serializer_class = ScanSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Scan.objects.filter(account__user=self.request.user).select_related('account')
