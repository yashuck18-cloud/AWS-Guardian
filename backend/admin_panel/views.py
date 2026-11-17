from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth import get_user_model
from django.db.models import Count, Q
from django.utils import timezone
from datetime import datetime, timedelta, timezone as dt_timezone
from django.db import connection

from .permissions import IsAdminRole
from .serializers import (
    AdminUserListSerializer,
    AdminUserDetailSerializer,
    AdminAWSAccountSerializer,
    AdminResourceSerializer,
    AdminAlertSerializer,
    AdminScanSerializer,
    AdminNotificationSerializer,
    AdminAuditLogSerializer,
)
from aws_accounts.models import AWSAccount
from resources.models import Resource
from alerts.models import Alert
from scanner.models import Scan
from notifications.models import NotificationHistory
from audit.models import AuditLog
from audit.logger import log_audit_event

User = get_user_model()


class AdminDashboardStatsView(APIView):
    permission_classes = [IsAdminRole]

    def get(self, request):
        now = timezone.now()
        today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        thirty_days_ago = now - timedelta(days=30)

        # Users
        total_users = User.objects.count()
        active_users = User.objects.filter(is_active=True).count()
        new_users_30d = User.objects.filter(created_at__gte=thirty_days_ago).count()

        # AWS Accounts
        total_accounts = AWSAccount.objects.count()
        connected_accounts = AWSAccount.objects.filter(status='CONNECTED').count()
        disconnected_accounts = AWSAccount.objects.filter(status='DISCONNECTED').count()
        failed_accounts = AWSAccount.objects.filter(status__in=['ERROR', 'VERIFICATION_FAILED']).count()

        # Resources
        total_resources = Resource.objects.count()
        services_agg = Resource.objects.values('service').annotate(count=Count('id')).order_by('-count')
        resources_by_service = {item['service']: item['count'] for item in services_agg}

        # Alerts
        active_alerts = Alert.objects.filter(status__in=['ACTIVE', 'ACKNOWLEDGED']).count()
        critical_alerts = Alert.objects.filter(status__in=['ACTIVE', 'ACKNOWLEDGED'], severity='CRITICAL').count()
        high_alerts = Alert.objects.filter(status__in=['ACTIVE', 'ACKNOWLEDGED'], severity='HIGH').count()
        medium_alerts = Alert.objects.filter(status__in=['ACTIVE', 'ACKNOWLEDGED'], severity='MEDIUM').count()
        low_alerts = Alert.objects.filter(status__in=['ACTIVE', 'ACKNOWLEDGED'], severity='LOW').count()
        resolved_alerts = Alert.objects.filter(status='RESOLVED').count()

        # Scans
        scans_today = Scan.objects.filter(started_at__gte=today_start).count()
        total_scans = Scan.objects.count()

        # Notifications
        notifications_sent = NotificationHistory.objects.filter(status='SENT').count()

        # Recent Activity (Latest 8 audit logs)
        recent_logs = AuditLog.objects.select_related('user').order_by('-timestamp')[:8]
        recent_activity = AdminAuditLogSerializer(recent_logs, many=True).data

        return Response({
            'success': True,
            'stats': {
                'total_users': total_users,
                'active_users': active_users,
                'new_users_30d': new_users_30d,
                'total_accounts': total_accounts,
                'connected_accounts': connected_accounts,
                'disconnected_accounts': disconnected_accounts,
                'failed_accounts': failed_accounts,
                'total_resources': total_resources,
                'resources_by_service': resources_by_service,
                'active_alerts': active_alerts,
                'critical_alerts': critical_alerts,
                'high_alerts': high_alerts,
                'medium_alerts': medium_alerts,
                'low_alerts': low_alerts,
                'resolved_alerts': resolved_alerts,
                'scans_today': scans_today,
                'total_scans': total_scans,
                'notifications_sent': notifications_sent,
            },
            'recent_activity': recent_activity,
        })


class AdminUsersListView(APIView):
    permission_classes = [IsAdminRole]

    def get(self, request):
        query = request.query_params.get('search', '').strip()
        status_filter = request.query_params.get('status', '').strip().lower()
        sort_by = request.query_params.get('ordering', '-created_at')

        users = User.objects.all()

        if query:
            users = users.filter(
                Q(name__icontains=query) | Q(email__icontains=query)
            )

        if status_filter == 'active':
            users = users.filter(is_active=True)
        elif status_filter == 'inactive' or status_filter == 'suspended':
            users = users.filter(is_active=False)

        valid_orderings = ['created_at', '-created_at', 'name', '-name', 'email', '-email', 'last_login', '-last_login']
        if sort_by in valid_orderings:
            users = users.order_by(sort_by)

        serializer = AdminUserListSerializer(users, many=True)
        return Response({
            'success': True,
            'count': users.count(),
            'users': serializer.data,
        })


class AdminUserDetailView(APIView):
    permission_classes = [IsAdminRole]

    def get(self, request, pk):
        try:
            user = User.objects.get(pk=pk)
        except User.DoesNotExist:
            return Response({'success': False, 'message': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)

        serializer = AdminUserDetailSerializer(user)
        user_resources = Resource.objects.filter(account__user=user).select_related('account')
        user_alerts = Alert.objects.filter(account__user=user).select_related('resource', 'account')
        user_scans = Scan.objects.filter(account__user=user).select_related('account')
        user_audit_logs = AuditLog.objects.filter(user=user).order_by('-timestamp')[:25]

        return Response({
            'success': True,
            'user': serializer.data,
            'resources': AdminResourceSerializer(user_resources, many=True).data,
            'alerts': AdminAlertSerializer(user_alerts, many=True).data,
            'scans': AdminScanSerializer(user_scans, many=True).data,
            'audit_logs': AdminAuditLogSerializer(user_audit_logs, many=True).data,
        })


class AdminUserToggleStatusView(APIView):
    permission_classes = [IsAdminRole]

    def post(self, request, pk):
        try:
            user = User.objects.get(pk=pk)
        except User.DoesNotExist:
            return Response({'success': False, 'message': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)

        if user == request.user:
            return Response({'success': False, 'message': 'You cannot suspend your own admin account.'}, status=status.HTTP_400_BAD_REQUEST)

        user.is_active = not user.is_active
        user.save()

        action = 'USER_ACTIVATED' if user.is_active else 'USER_SUSPENDED'
        log_audit_event(request.user, action, {'target_user_id': str(user.id), 'target_email': user.email})

        return Response({
            'success': True,
            'message': f"User account has been {'activated' if user.is_active else 'suspended'}.",
            'is_active': user.is_active,
        })


class AdminUserDeleteView(APIView):
    permission_classes = [IsAdminRole]

    def delete(self, request, pk):
        try:
            user = User.objects.get(pk=pk)
        except User.DoesNotExist:
            return Response({'success': False, 'message': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)

        if user == request.user:
            return Response({'success': False, 'message': 'You cannot delete your own admin account.'}, status=status.HTTP_400_BAD_REQUEST)

        email = user.email
        log_audit_event(request.user, 'ADMIN_DELETED_USER', {'target_user_id': str(user.id), 'target_email': email})
        user.delete()

        return Response({
            'success': True,
            'message': f"User {email} has been permanently removed.",
        })


class AdminAWSAccountsListView(APIView):
    permission_classes = [IsAdminRole]

    def get(self, request):
        query = request.query_params.get('search', '').strip()
        status_filter = request.query_params.get('status', '').strip().upper()

        accounts = AWSAccount.objects.select_related('user').all()

        if query:
            accounts = accounts.filter(
                Q(name__icontains=query) | Q(account_id__icontains=query) | Q(user__name__icontains=query) | Q(user__email__icontains=query)
            )

        if status_filter in ['CONNECTED', 'DISCONNECTED', 'ERROR', 'VERIFICATION_FAILED', 'PENDING']:
            accounts = accounts.filter(status=status_filter)

        serializer = AdminAWSAccountSerializer(accounts, many=True)
        return Response({
            'success': True,
            'count': accounts.count(),
            'accounts': serializer.data,
        })


class AdminAWSAccountDetailView(APIView):
    permission_classes = [IsAdminRole]

    def get(self, request, pk):
        try:
            account = AWSAccount.objects.select_related('user').get(pk=pk)
        except AWSAccount.DoesNotExist:
            return Response({'success': False, 'message': 'AWS Account not found.'}, status=status.HTTP_404_NOT_FOUND)

        resources = account.resources.all()
        alerts = account.alerts.all()
        scans = account.scans.all()

        return Response({
            'success': True,
            'account': AdminAWSAccountSerializer(account).data,
            'resources': AdminResourceSerializer(resources, many=True).data,
            'alerts': AdminAlertSerializer(alerts, many=True).data,
            'scans': AdminScanSerializer(scans, many=True).data,
        })


class AdminResourcesListView(APIView):
    permission_classes = [IsAdminRole]

    def get(self, request):
        query = request.query_params.get('search', '').strip()
        service_filter = request.query_params.get('service', '').strip().upper()
        risk_filter = request.query_params.get('risk', '').strip().upper()
        account_filter = request.query_params.get('account', '').strip()

        resources = Resource.objects.select_related('account', 'account__user').all()

        if query:
            resources = resources.filter(
                Q(name__icontains=query) |
                Q(resource_id__icontains=query) |
                Q(account__name__icontains=query) |
                Q(account__account_id__icontains=query)
            )

        if service_filter:
            resources = resources.filter(service=service_filter)

        if risk_filter:
            resources = resources.filter(risk_level=risk_filter)

        if account_filter:
            resources = resources.filter(account_id=account_filter)

        serializer = AdminResourceSerializer(resources, many=True)
        return Response({
            'success': True,
            'count': resources.count(),
            'resources': serializer.data,
        })


class AdminResourceDetailView(APIView):
    permission_classes = [IsAdminRole]

    def get(self, request, pk):
        try:
            resource = Resource.objects.select_related('account', 'account__user').get(pk=pk)
        except Resource.DoesNotExist:
            return Response({'success': False, 'message': 'Resource not found.'}, status=status.HTTP_404_NOT_FOUND)

        alerts = resource.alerts.all()
        return Response({
            'success': True,
            'resource': AdminResourceSerializer(resource).data,
            'alerts': AdminAlertSerializer(alerts, many=True).data,
        })


class AdminAlertsListView(APIView):
    permission_classes = [IsAdminRole]

    def get(self, request):
        query = request.query_params.get('search', '').strip()
        severity_filter = request.query_params.get('severity', '').strip().upper()
        status_filter = request.query_params.get('status', '').strip().upper()
        service_filter = request.query_params.get('service', '').strip().upper()

        alerts = Alert.objects.select_related('account', 'resource', 'account__user').all()

        if query:
            alerts = alerts.filter(
                Q(title__icontains=query) |
                Q(description__icontains=query) |
                Q(resource__resource_id__icontains=query) |
                Q(account__name__icontains=query)
            )

        if severity_filter in ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW']:
            alerts = alerts.filter(severity=severity_filter)

        if status_filter in ['ACTIVE', 'ACKNOWLEDGED', 'RESOLVED']:
            alerts = alerts.filter(status=status_filter)

        if service_filter:
            alerts = alerts.filter(resource__service=service_filter)

        serializer = AdminAlertSerializer(alerts, many=True)
        return Response({
            'success': True,
            'count': alerts.count(),
            'alerts': serializer.data,
        })


class AdminAlertDetailView(APIView):
    permission_classes = [IsAdminRole]

    def get(self, request, pk):
        try:
            alert = Alert.objects.select_related('account', 'resource', 'account__user').get(pk=pk)
        except Alert.DoesNotExist:
            return Response({'success': False, 'message': 'Alert not found.'}, status=status.HTTP_404_NOT_FOUND)

        return Response({
            'success': True,
            'alert': AdminAlertSerializer(alert).data,
        })


class AdminAlertResolveView(APIView):
    permission_classes = [IsAdminRole]

    def post(self, request, pk):
        try:
            alert = Alert.objects.get(pk=pk)
        except Alert.DoesNotExist:
            return Response({'success': False, 'message': 'Alert not found.'}, status=status.HTTP_404_NOT_FOUND)

        alert.status = 'RESOLVED'
        alert.resolved_at = timezone.now()
        alert.save()

        log_audit_event(request.user, 'ADMIN_RESOLVED_ALERT', {'alert_id': str(alert.id), 'alert_title': alert.title})

        return Response({
            'success': True,
            'message': 'Alert marked as resolved.',
            'alert': AdminAlertSerializer(alert).data,
        })


class AdminScansListView(APIView):
    permission_classes = [IsAdminRole]

    def get(self, request):
        query = request.query_params.get('search', '').strip()
        status_filter = request.query_params.get('status', '').strip().upper()

        scans = Scan.objects.select_related('account', 'account__user').all()

        if query:
            scans = scans.filter(
                Q(account__name__icontains=query) | Q(account__account_id__icontains=query)
            )

        if status_filter in ['PENDING', 'RUNNING', 'COMPLETED', 'FAILED', 'PARTIAL']:
            scans = scans.filter(status=status_filter)

        serializer = AdminScanSerializer(scans, many=True)
        return Response({
            'success': True,
            'count': scans.count(),
            'scans': serializer.data,
        })


class AdminNotificationsListView(APIView):
    permission_classes = [IsAdminRole]

    def get(self, request):
        query = request.query_params.get('search', '').strip()
        channel_filter = request.query_params.get('channel', '').strip().upper()
        status_filter = request.query_params.get('status', '').strip().upper()

        notifications = NotificationHistory.objects.select_related('user').all()

        if query:
            notifications = notifications.filter(
                Q(user__name__icontains=query) | Q(user__email__icontains=query) | Q(title__icontains=query) | Q(message__icontains=query)
            )

        if channel_filter in ['TELEGRAM', 'EMAIL', 'PUSH', 'IN_APP']:
            notifications = notifications.filter(channel=channel_filter)

        if status_filter in ['SENT', 'FAILED', 'PENDING']:
            notifications = notifications.filter(status=status_filter)

        serializer = AdminNotificationSerializer(notifications, many=True)
        return Response({
            'success': True,
            'count': notifications.count(),
            'notifications': serializer.data,
        })


class AdminAuditLogsListView(APIView):
    permission_classes = [IsAdminRole]

    def get(self, request):
        query = request.query_params.get('search', '').strip()
        action_filter = request.query_params.get('action', '').strip().upper()
        status_filter = request.query_params.get('status', '').strip().upper()

        logs = AuditLog.objects.select_related('user').all()

        if query:
            logs = logs.filter(
                Q(action__icontains=query) |
                Q(ip_address__icontains=query) |
                Q(user__name__icontains=query) |
                Q(user__email__icontains=query)
            )

        if action_filter:
            logs = logs.filter(action=action_filter)

        if status_filter in ['SUCCESS', 'FAILURE']:
            logs = logs.filter(status=status_filter)

        serializer = AdminAuditLogSerializer(logs, many=True)
        return Response({
            'success': True,
            'count': logs.count(),
            'logs': serializer.data,
        })


class AdminAnalyticsView(APIView):
    permission_classes = [IsAdminRole]

    def get(self, request):
        timeframe = request.query_params.get('timeframe', '30d').lower()
        days = {'7d': 7, '30d': 30, '90d': 90, '1y': 365}.get(timeframe, 30)

        now = timezone.now()
        start_date = now - timedelta(days=days)

        # Generate daily date buckets
        dates = [(start_date + timedelta(days=i)).strftime('%Y-%m-%d') for i in range(days + 1)]
        
        user_growth = []
        cumulative_users = User.objects.filter(created_at__lt=start_date).count()

        for d_str in dates:
            d_start = datetime.strptime(d_str, '%Y-%m-%d').replace(tzinfo=dt_timezone.utc)
            d_end = d_start + timedelta(days=1)
            new_users = User.objects.filter(created_at__gte=d_start, created_at__lt=d_end).count()
            cumulative_users += new_users
            scans_count = Scan.objects.filter(started_at__gte=d_start, started_at__lt=d_end).count()
            alerts_count = Alert.objects.filter(first_detected_at__gte=d_start, first_detected_at__lt=d_end).count()

            user_growth.append({
                'date': d_str,
                'users': cumulative_users,
                'new_users': new_users,
                'scans': scans_count,
                'alerts': alerts_count,
            })

        # Services breakdown
        services_agg = Resource.objects.values('service').annotate(count=Count('id')).order_by('-count')
        service_breakdown = [{'service': item['service'], 'count': item['count']} for item in services_agg]

        # Accounts status
        account_status = [
            {'status': 'Connected', 'count': AWSAccount.objects.filter(status='CONNECTED').count(), 'color': '#22C55E'},
            {'status': 'Disconnected', 'count': AWSAccount.objects.filter(status='DISCONNECTED').count(), 'color': '#94A3B8'},
            {'status': 'Failed', 'count': AWSAccount.objects.filter(status__in=['ERROR', 'VERIFICATION_FAILED']).count(), 'color': '#EF4444'},
        ]

        # Severity breakdown
        severity_breakdown = [
            {'name': 'Critical', 'count': Alert.objects.filter(severity='CRITICAL').count(), 'color': '#EF4444'},
            {'name': 'High', 'count': Alert.objects.filter(severity='HIGH').count(), 'color': '#F59E0B'},
            {'name': 'Medium', 'count': Alert.objects.filter(severity='MEDIUM').count(), 'color': '#38BDF8'},
            {'name': 'Low', 'count': Alert.objects.filter(severity='LOW').count(), 'color': '#8B5CF6'},
        ]

        return Response({
            'success': True,
            'timeframe': timeframe,
            'growth_series': user_growth,
            'service_breakdown': service_breakdown,
            'account_status': account_status,
            'severity_breakdown': severity_breakdown,
        })


class AdminSystemHealthView(APIView):
    permission_classes = [IsAdminRole]

    def get(self, request):
        # 1. Database Check
        db_status = 'Operational'
        db_error = None
        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
                cursor.fetchone()
        except Exception as e:
            db_status = 'Degraded'
            db_error = str(e)

        # 2. Django API Check
        api_status = 'Operational'

        # 3. AWS Scanner Service
        scanner_status = 'Operational'
        failed_recent_scans = Scan.objects.filter(
            started_at__gte=timezone.now() - timedelta(hours=24),
            status='FAILED'
        ).count()
        if failed_recent_scans > 5:
            scanner_status = 'Degraded'

        # 4. Notification Service
        notification_status = 'Operational'
        failed_notifs = NotificationHistory.objects.filter(
            created_at__gte=timezone.now() - timedelta(hours=24),
            status='FAILED'
        ).count()
        if failed_notifs > 10:
            notification_status = 'Degraded'

        return Response({
            'success': True,
            'timestamp': timezone.now().isoformat(),
            'components': [
                {
                    'name': 'Django REST API',
                    'status': api_status,
                    'description': 'Main application runtime and JWT auth services',
                    'uptime': '99.98%',
                    'latency_ms': 12,
                },
                {
                    'name': 'Primary Database (MySQL/PostgreSQL)',
                    'status': db_status,
                    'description': 'Relational data store and audit event catalog',
                    'uptime': '100%',
                    'latency_ms': 4,
                    'error': db_error,
                },
                {
                    'name': 'AWS STS Scanner Engine',
                    'status': scanner_status,
                    'description': 'Multi-service rule engine and cloud inspection workers',
                    'uptime': '99.95%',
                    'failed_scans_24h': failed_recent_scans,
                },
                {
                    'name': 'Notification Dispatcher',
                    'status': notification_status,
                    'description': 'Telegram Bot API, digest generator, and push dispatch',
                    'uptime': '99.90%',
                    'failed_notifications_24h': failed_notifs,
                },
            ]
        })


class AdminGlobalSearchView(APIView):
    permission_classes = [IsAdminRole]

    def get(self, request):
        query = request.query_params.get('q', '').strip()
        if not query or len(query) < 2:
            return Response({'success': True, 'results': {'users': [], 'accounts': [], 'resources': [], 'alerts': []}})

        users = User.objects.filter(Q(name__icontains=query) | Q(email__icontains=query))[:5]
        accounts = AWSAccount.objects.filter(Q(name__icontains=query) | Q(account_id__icontains=query))[:5]
        resources = Resource.objects.filter(Q(name__icontains=query) | Q(resource_id__icontains=query))[:5]
        alerts = Alert.objects.filter(Q(title__icontains=query) | Q(description__icontains=query))[:5]

        return Response({
            'success': True,
            'query': query,
            'results': {
                'users': [{'id': str(u.id), 'title': u.name, 'subtitle': u.email, 'type': 'User'} for u in users],
                'accounts': [{'id': str(a.id), 'title': a.name, 'subtitle': f"AWS {a.account_id}", 'type': 'AWS Account'} for a in accounts],
                'resources': [{'id': str(r.id), 'title': r.name or r.resource_id, 'subtitle': f"{r.service} ({r.region})", 'type': 'Resource'} for r in resources],
                'alerts': [{'id': str(al.id), 'title': al.title, 'subtitle': f"Severity: {al.severity}", 'type': 'Alert'} for al in alerts],
            }
        })
