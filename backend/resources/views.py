from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from django.db.models import Q
from django.shortcuts import get_object_or_404
from users.utils import is_valid_uuid
from .models import Resource
from .serializers import ResourceSerializer, StopResourceSerializer, DeleteResourceSerializer
from .actions import execute_stop_ec2_instance, execute_delete_resource

class ResourceListView(generics.ListAPIView):
    serializer_class = ResourceSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Strict tenant isolation with preloaded account foreign key
        queryset = Resource.objects.filter(account__user=self.request.user).select_related('account')

        # Filters - Strict per-account isolation so resources never bleed across accounts
        account_param = self.request.query_params.get('account')
        target_account = None
        from aws_accounts.models import AWSAccount
        if account_param:
            if is_valid_uuid(account_param):
                target_account = AWSAccount.objects.filter(id=account_param, user=self.request.user).first()
            else:
                target_account = AWSAccount.objects.filter(account_id=account_param, user=self.request.user).first()
        else:
            target_account = AWSAccount.objects.filter(user=self.request.user, status='CONNECTED').first() or AWSAccount.objects.filter(user=self.request.user).first()

        if target_account:
            queryset = queryset.filter(account=target_account)

        service = self.request.query_params.get('service')
        if service and service.upper() != 'ALL':
            queryset = queryset.filter(service=service.upper())

        region = self.request.query_params.get('region')
        # S3 is an AWS global service (stored under global/us-east-1 in boto3), so don't exclude it on regional filters
        is_s3_search = (service and service.upper() == 'S3')
        if not is_s3_search:
            if region and region.lower() != 'all':
                queryset = queryset.filter(
                    Q(region__iexact=region.strip()) | Q(region__in=['global', '']) | Q(service='S3')
                )
            elif account_param:
                from aws_accounts.models import AWSAccount
                if is_valid_uuid(account_param):
                    acc = AWSAccount.objects.filter(id=account_param, user=self.request.user).first()
                else:
                    acc = AWSAccount.objects.filter(account_id=account_param, user=self.request.user).first()
                if acc and acc.enabled_regions:
                    raw_regs = acc.enabled_regions if isinstance(acc.enabled_regions, list) else [acc.enabled_regions]
                    active_regs = [r.strip().lower() for r in raw_regs if r and r.strip().lower() != 'all']
                    if active_regs:
                        queryset = queryset.filter(
                            Q(region__in=active_regs) | Q(region__in=['global', '']) | Q(service='S3')
                        )

        risk = self.request.query_params.get('risk')
        if risk and risk.upper() != 'ALL':
            queryset = queryset.filter(risk_level=risk.upper())

        state = self.request.query_params.get('state')
        if state and state.lower() != 'all':
            queryset = queryset.filter(state__iexact=state)

        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(
                Q(name__icontains=search) |
                Q(resource_id__icontains=search) |
                Q(service__icontains=search) |
                Q(region__icontains=search)
            )

        return queryset.distinct()

class ResourceDetailView(generics.RetrieveAPIView):
    serializer_class = ResourceSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Resource.objects.filter(account__user=self.request.user).select_related('account')

class StopResourceView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        resource = get_object_or_404(Resource, pk=pk, account__user=request.user)
        serializer = StopResourceSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({'success': False, 'errors': serializer.errors}, status=status.HTTP_400_BAD_REQUEST)

        success, message = execute_stop_ec2_instance(request.user, resource)
        if success:
            return Response({'success': True, 'message': message, 'resource': ResourceSerializer(resource).data})
        return Response({'success': False, 'message': message}, status=status.HTTP_400_BAD_REQUEST)

class DeleteResourceView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        resource = get_object_or_404(Resource, pk=pk, account__user=request.user)
        serializer = DeleteResourceSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({'success': False, 'errors': serializer.errors}, status=status.HTTP_400_BAD_REQUEST)

        typed_id = serializer.validated_data['confirm_resource_id']
        success, message = execute_delete_resource(request.user, resource, typed_id)
        if success:
            return Response({'success': True, 'message': message})
        return Response({'success': False, 'message': message}, status=status.HTTP_400_BAD_REQUEST)


class ResourceCostDetailView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk):
        resource = get_object_or_404(Resource, pk=pk, account__user=request.user)
        latest_cost = resource.cost_records.order_by('-last_updated').first()
        from .serializers import ResourceCostSerializer
        
        if latest_cost:
            cost_data = ResourceCostSerializer(latest_cost).data
        else:
            hourly = float(resource.estimated_hourly_cost or 0.0)
            cost_data = {
                'resource_id': resource.resource_id,
                'service': resource.service,
                'region': resource.region,
                'resource_type': resource.resource_type,
                'actual_cost': '0.0000',
                'estimated_cost': f"{round(hourly * 24.0, 4):.4f}",
                'currency': 'USD',
                'pricing_rate': f"{hourly:.6f}",
                'pricing_unit': 'Hrs',
                'cost_source': 'AWS_PRICING',
                'cost_source_display': 'AWS Pricing API',
                'billing_status': 'PRICING_ESTIMATE',
                'billing_status_display': 'Pricing-Based Estimate',
                'approx_inr': round(hourly * 24.0 * 86.50, 2),
                'notes': 'Calculated from authoritative AWS on-demand hourly pricing. Final AWS billing may differ.',
                'last_updated': resource.updated_at.isoformat() if resource.updated_at else None
            }

        return Response({
            'success': True,
            'resource_id': resource.resource_id,
            'service': resource.service,
            'state': resource.state,
            'region': resource.region,
            'cost_info': cost_data,
            'disclaimer': 'Final AWS billing may differ.'
        })

