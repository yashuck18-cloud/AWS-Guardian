from datetime import datetime, timezone
from .models import Alert
from audit.logger import log_audit_event
import logging

logger = logging.getLogger(__name__)

def sync_resource_alerts(account, resource, eval_result):
    """
    Synchronizes rule evaluation result with database alerts using deduplication logic.
    Returns: (created_alert, updated_alert, resolved_alert)
    """
    now = datetime.now(timezone.utc)
    user = account.user

    active_alerts = Alert.objects.filter(
        account=account,
        resource=resource,
        status__in=['ACTIVE', 'ACKNOWLEDGED']
    )

    if eval_result.has_alert:
        # Check if an alert for this rule_code already exists
        existing_alert = active_alerts.filter(rule_code=eval_result.rule_code).first()

        if existing_alert:
            # Update existing active alert without creating a duplicate
            existing_alert.severity = eval_result.risk_level
            existing_alert.title = eval_result.title
            existing_alert.description = eval_result.description
            existing_alert.estimated_cost_impact = eval_result.cost_impact
            existing_alert.last_detected_at = now
            existing_alert.save()
            return None, existing_alert, None
        else:
            # Create a brand new alert
            new_alert = Alert.objects.create(
                account=account,
                resource=resource,
                rule_code=eval_result.rule_code,
                title=eval_result.title,
                description=eval_result.description,
                severity=eval_result.risk_level,
                status='ACTIVE',
                estimated_cost_impact=eval_result.cost_impact,
                first_detected_at=now,
                last_detected_at=now
            )
            log_audit_event(
                user,
                'ALERT_CREATED',
                {
                    'alert_id': str(new_alert.id),
                    'title': new_alert.title,
                    'severity': new_alert.severity,
                    'resource_id': resource.resource_id,
                    'service': resource.service
                }
            )
            return new_alert, None, None
    else:
        # If no alert condition holds now, resolve any lingering active alerts for this resource
        resolved = []
        for alert in active_alerts:
            alert.status = 'RESOLVED'
            alert.resolved_at = now
            alert.save()
            resolved.append(alert)
            log_audit_event(
                user,
                'ALERT_RESOLVED',
                {
                    'alert_id': str(alert.id),
                    'title': alert.title,
                    'resource_id': resource.resource_id,
                    'reason': 'Condition cleared during scan'
                }
            )
        return None, None, resolved
