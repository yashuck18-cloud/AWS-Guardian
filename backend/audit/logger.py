import logging
from .models import AuditLog

logger = logging.getLogger(__name__)

# Sensitive keys that MUST NEVER be logged in audit details
SENSITIVE_KEYS = {
    'password', 'secret', 'token', 'key', 'access_key', 'secret_key',
    'session_token', 'credentials', 'bot_token'
}

def sanitize_details(details):
    if not isinstance(details, dict):
        return details
    clean = {}
    for k, v in details.items():
        if any(sens in k.lower() for sens in SENSITIVE_KEYS):
            clean[k] = '[REDACTED]'
        elif isinstance(v, dict):
            clean[k] = sanitize_details(v)
        else:
            clean[k] = v
    return clean

def log_audit_event(user, action, details=None, ip_address=None):
    try:
        clean_details = sanitize_details(details or {})
        AuditLog.objects.create(
            user=user,
            action=action,
            details=clean_details,
            ip_address=ip_address
        )
    except Exception as e:
        logger.error(f"Failed to write audit log event {action}: {e}")
