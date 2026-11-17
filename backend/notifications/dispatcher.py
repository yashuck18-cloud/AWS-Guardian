import os
import sys
import logging
from pathlib import Path

# Ensure backend directory is in sys.path and Django is configured when run directly
backend_dir = Path(__file__).resolve().parent.parent
if str(backend_dir) not in sys.path:
    sys.path.insert(0, str(backend_dir))

if not os.getenv('DJANGO_SETTINGS_MODULE'):
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
    try:
        import django
        django.setup()
    except Exception:
        pass

from alerts.models import Alert
from notifications.models import NotificationSettings, NotificationHistory
from notifications.telegram_service import send_telegram_message
from notifications.firebase_service import send_fcm_to_user
from audit.logger import log_audit_event

logger = logging.getLogger(__name__)

def generate_user_alert_summary(user, summary_type="Morning"):
    """
    Generates a structured summary of active alerts for the user's AWS accounts.
    """
    active_alerts = Alert.objects.filter(account__user=user, status='ACTIVE')
    total_count = active_alerts.count()

    ec2_count = active_alerts.filter(resource__service='EC2').count()
    ebs_count = active_alerts.filter(resource__service='EBS').count()
    eip_count = active_alerts.filter(resource__service='EIP').count()
    rds_count = active_alerts.filter(resource__service='RDS').count()
    s3_count = active_alerts.filter(resource__service='S3').count()
    nat_count = active_alerts.filter(resource__service='NAT').count()

    lines = [
        f"🛡️ *AWS GUARDIAN — {summary_type.upper()} SUMMARY*",
        "",
    ]

    if total_count == 0:
        lines.append("🎉 All clear! No active resource alerts detected on your connected AWS accounts.")
    else:
        lines.append(f"⚠️ *{total_count} resources require attention.*")
        lines.append("")
        if ec2_count > 0:
            lines.append(f"• EC2: {ec2_count}")
        if ebs_count > 0:
            lines.append(f"• EBS: {ebs_count}")
        if eip_count > 0:
            lines.append(f"• Elastic IP: {eip_count}")
        if rds_count > 0:
            lines.append(f"• RDS: {rds_count}")
        if s3_count > 0:
            lines.append(f"• S3: {s3_count}")
        if nat_count > 0:
            lines.append(f"• NAT Gateway: {nat_count}")
        lines.append("")
        lines.append("Review these resources in AWS Guardian mobile app.")

    return "\n".join(lines), total_count


def dispatch_summary_notification(user, summary_type="Morning"):
    """
    Dispatches summary notification to configured channels (FCM Push / Telegram / In-App).
    """
    settings, _ = NotificationSettings.objects.get_or_create(user=user)
    message_text, total_count = generate_user_alert_summary(user, summary_type)
    title = f"{summary_type} Summary: {total_count} Alerts" if total_count > 0 else f"{summary_type} Summary: All Clear"

    # Always record In-App notification
    NotificationHistory.objects.create(
        user=user,
        title=title,
        message=message_text,
        channel='IN_APP',
        status='SENT'
    )

    # 1. FCM Push Notification
    fcm_title = f"🛡️ AWS Guardian {summary_type} Summary"
    fcm_body = f"{total_count} active alert(s) require your attention." if total_count > 0 else "All clear! No active AWS resource waste detected."
    fcm_data = {
        'type': 'summary',
        'summary_type': summary_type,
        'alerts_count': str(total_count),
        'route': '/notifications',
        'action': 'open_notifications'
    }
    send_fcm_to_user(
        user=user,
        title=fcm_title,
        body=fcm_body,
        data=fcm_data,
        notification_type="summary"
    )

    # 2. Telegram Dispatch if enabled
    if settings.telegram_enabled and settings.telegram_chat_id:
        success, err = send_telegram_message(settings.telegram_chat_id, message_text)
        NotificationHistory.objects.create(
            user=user,
            title=title,
            message=message_text,
            channel='TELEGRAM',
            status='SENT' if success else 'FAILED',
            error_details='' if success else err
        )

    log_audit_event(
        user,
        'NOTIFICATION_SENT',
        {
            'summary_type': summary_type,
            'alerts_count': total_count,
            'telegram_enabled': settings.telegram_enabled
        }
    )

    return True, message_text


def dispatch_urgent_alert_notification(user, alert):
    """
    Dispatches immediate FCM push notification when an urgent or high-severity alert is detected.
    """
    settings, _ = NotificationSettings.objects.get_or_create(user=user)
    if not settings.urgent_alerts_enabled:
        return False, "Urgent alerts disabled in user settings"

    title = f"🚨 [{alert.severity}] {alert.title}"
    body = alert.description[:140] + ("..." if len(alert.description) > 140 else "")
    
    data = {
        'type': 'urgent_alert',
        'alert_id': str(alert.id),
        'resource_id': str(alert.resource.id) if alert.resource else '',
        'aws_resource_id': alert.resource.resource_id if alert.resource else '',
        'service': alert.resource.service if alert.resource else '',
        'severity': alert.severity,
        'route': f"/alerts/{alert.id}",
        'action': 'open_alert'
    }

    send_fcm_to_user(
        user=user,
        title=title,
        body=body,
        data=data,
        notification_type="urgent_alert"
    )

    # If Telegram enabled, also send instant Telegram message
    if settings.telegram_enabled and settings.telegram_chat_id:
        tg_text = f"🚨 *AWS GUARDIAN ALERT [{alert.severity}]*\n\n*{alert.title}*\n{alert.description}"
        send_telegram_message(settings.telegram_chat_id, tg_text)

    return True, "Dispatched"


def scan_and_evaluate_account(
    account,
    trigger_source='SCHEDULED_MORNING',
    summary_type='Morning',
    force_notification=False,
    simulate_clear=False,
    mock_fcm=False,
    allow_duplicate=False
):
    """
    Executes AWS resource scan via Boto3 and evaluates attention-requiring resources.
    Dispatches FCM push notifications ONLY when one or more resources require attention.
    If no resources require attention, records the scan result and suppresses notifications.
    """
    from datetime import timedelta
    from django.utils import timezone as dj_timezone
    from scanner.runner import execute_account_scan
    from alerts.models import Alert
    from notifications.models import NotificationHistory

    user = account.user

    logger.info(f"Starting {summary_type} scan for AWS account {account.account_id} ({account.name})")

    # 1. Trigger the AWS scan using existing account/role connection via Boto3
    scan = execute_account_scan(account.id, trigger_source=trigger_source)
    if not scan:
        logger.error(f"Failed to initiate scan for account {account.account_id}")
        return {
            'success': False,
            'account': account.account_id,
            'message': 'Failed to execute AWS scan',
            'notification_sent': False
        }

    # 2. Detect resources that require attention
    if simulate_clear:
        # Simulation override for no-resource test case
        attention_alerts = Alert.objects.none()
    else:
        attention_alerts = Alert.objects.filter(account=account, status='ACTIVE').select_related('resource')

    attention_count = attention_alerts.count()

    # Breakdown by AWS service
    service_breakdown = {}
    for a in attention_alerts[:15]:
        svc = a.resource.service if a.resource else 'AWS'
        service_breakdown[svc] = service_breakdown.get(svc, 0) + 1

    svc_summary = ", ".join([f"{count} {svc}" for svc, count in service_breakdown.items()]) if service_breakdown else "resources"

    scan.trigger_source = trigger_source

    # 3. Decision Logic: Attention Needed vs Normal
    if attention_count > 0 or force_notification:
        # Duplicate Prevention:
        # Prevent duplicate notifications from being generated by the same scheduler execution window
        # (suppress if an identical summary was dispatched within the last 2 hours unless forced)
        two_hours_ago = dj_timezone.now() - timedelta(hours=2)
        duplicate_exists = NotificationHistory.objects.filter(
            user=user,
            channel='FCM',
            status='SENT',
            created_at__gte=two_hours_ago,
            title__icontains=summary_type
        ).exists()

        if duplicate_exists and not force_notification and not allow_duplicate:
            logger.info(f"Duplicate {summary_type} notification suppressed for {user.email}")
            scan.notification_sent = False
            scan.notification_status = 'SKIPPED_DUPLICATE'
            scan.notification_title = f"{summary_type}: {attention_count} Resources Require Attention"
            scan.notification_message = f"Duplicate notification suppressed. {attention_count} items require attention."
            scan.save()
            return {
                'success': True,
                'account': account.account_id,
                'attention_count': attention_count,
                'notification_sent': False,
                'notification_status': 'SKIPPED_DUPLICATE',
                'reason': 'Duplicate notification prevented within schedule window'
            }

        title = f"⚠️ [{summary_type}] {attention_count} AWS Resources Need Attention"
        body = (
            f"[{account.name}] {attention_count} resource(s) require attention ({svc_summary}). "
            f"Review now to avoid unnecessary cloud cost or security risks."
        )

        first_alert = attention_alerts.first() if attention_alerts.exists() else None
        first_alert_id = str(first_alert.id) if first_alert else ''

        fcm_data = {
            'type': 'attention_alert',
            'summary_type': summary_type,
            'account_id': str(account.id),
            'account_aws_id': account.account_id,
            'alerts_count': str(attention_count),
            'alert_id': first_alert_id,
            'route': '/alerts',
            'action': 'open_alerts'
        }

        # 4. Send the notification through Firebase Cloud Messaging
        success_count, failure_count = send_fcm_to_user(
            user=user,
            title=title,
            body=body,
            data=fcm_data,
            notification_type='scheduled_attention',
            allow_mock=mock_fcm
        )

        # Record in-app notification history
        NotificationHistory.objects.create(
            user=user,
            title=title,
            message=body,
            channel='IN_APP',
            status='SENT' if success_count > 0 else 'FAILED',
            error_details='' if success_count > 0 else 'FCM dispatch failed or no active devices registered'
        )

        # Store notification and scan result in Database
        scan.notification_sent = (success_count > 0)
        scan.notification_status = 'SENT' if success_count > 0 else 'FAILED'
        scan.notification_title = title
        scan.notification_message = body
        scan.save()

        log_audit_event(
            user,
            'SCHEDULED_SCAN_NOTIFICATION_SENT',
            {
                'account_id': account.account_id,
                'summary_type': summary_type,
                'attention_count': attention_count,
                'success_count': success_count,
                'failure_count': failure_count
            }
        )

        return {
            'success': True,
            'account': account.account_id,
            'attention_count': attention_count,
            'notification_sent': (success_count > 0),
            'notification_status': 'SENT' if success_count > 0 else 'FAILED',
            'devices_notified': success_count,
            'title': title,
            'message': body
        }

    else:
        # 5. NO resources require attention:
        # Do NOT send any notification!
        # Still record the scan result for audit/history
        logger.info(f"All clear for account {account.account_id} ({account.name}). No notification sent.")

        scan.notification_sent = False
        scan.notification_status = 'SKIPPED_NO_RESOURCES'
        scan.notification_title = f"{summary_type}: All Clear"
        scan.notification_message = "All resources operating normally within policy. No notification dispatched."
        scan.save()

        log_audit_event(
            user,
            'SCHEDULED_SCAN_COMPLETED_NO_ALERT',
            {
                'account_id': account.account_id,
                'summary_type': summary_type,
                'resources_found': scan.resources_found,
                'alerts_created': 0
            }
        )

        return {
            'success': True,
            'account': account.account_id,
            'attention_count': 0,
            'notification_sent': False,
            'notification_status': 'SKIPPED_NO_RESOURCES',
            'message': 'No resources require attention. Notification suppressed.'
        }


if __name__ == '__main__':
    print("AWS Guardian Notification Dispatcher loaded successfully.")
