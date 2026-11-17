import os
import json
import logging
from typing import Dict, Any, Tuple, Optional, List
import firebase_admin
from firebase_admin import credentials, messaging
from django.conf import settings
from audit.logger import log_audit_event
from notifications.models import FCMDevice, NotificationHistory

logger = logging.getLogger(__name__)

_firebase_initialized = False

def get_firebase_app():
    """
    Initializes and returns the Firebase Admin SDK application instance.
    Supports file path (FIREBASE_CREDENTIALS_PATH), raw JSON string (FIREBASE_CREDENTIALS_JSON),
    or common local filenames.
    """
    global _firebase_initialized
    if _firebase_initialized and firebase_admin._apps:
        return firebase_admin.get_app()

    cred_path = os.getenv('FIREBASE_CREDENTIALS_PATH')
    cred_json = os.getenv('FIREBASE_CREDENTIALS_JSON')

    # Common search paths if not specified in environment
    candidate_paths = [
        cred_path,
        os.path.join(settings.BASE_DIR, 'firebase-service-account.json'),
        os.path.join(settings.BASE_DIR, 'firebase-admin-key.json'),
        os.path.join(settings.BASE_DIR, 'config', 'firebase-service-account.json'),
    ]

    cred = None

    if cred_json:
        try:
            cred_dict = json.loads(cred_json)
            cred = credentials.Certificate(cred_dict)
            logger.info("Loaded Firebase credentials from FIREBASE_CREDENTIALS_JSON environment variable.")
        except Exception as e:
            logger.error(f"Failed to parse FIREBASE_CREDENTIALS_JSON: {e}")

    if not cred:
        for p in candidate_paths:
            if p and os.path.isfile(p):
                try:
                    cred = credentials.Certificate(p)
                    logger.info(f"Loaded Firebase credentials from file: {p}")
                    break
                except Exception as e:
                    logger.error(f"Failed to load Firebase credentials from {p}: {e}")

    if not cred:
        gac_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
        if gac_path and os.path.isfile(gac_path):
            try:
                cred = credentials.Certificate(gac_path)
                logger.info(f"Loaded Firebase credentials from GOOGLE_APPLICATION_CREDENTIALS: {gac_path}")
            except Exception as e:
                logger.error(f"Failed to load GOOGLE_APPLICATION_CREDENTIALS from {gac_path}: {e}")

    if not cred:
        logger.warning(
            "No valid Firebase Admin credentials found. "
            "Set FIREBASE_CREDENTIALS_PATH or place firebase-service-account.json in backend directory."
        )
        return None

    project_id = os.getenv('FIREBASE_PROJECT_ID') or os.getenv('GOOGLE_CLOUD_PROJECT') or 'aws-guardian'

    try:
        app = firebase_admin.initialize_app(cred, options={'projectId': project_id})
        _firebase_initialized = True
        return app
    except Exception as e:
        logger.exception(f"Error initializing Firebase Admin SDK: {e}")
        return None


def send_fcm_notification(
    device: FCMDevice,
    title: str,
    body: str,
    data: Optional[Dict[str, Any]] = None,
    allow_mock: bool = False
) -> Tuple[bool, str]:
    """
    Sends a high-priority FCM notification to a specific registered device.
    Automatically handles and deactivates unregistered/stale tokens.
    Supports mock/dry-run mode when Firebase credentials are not yet configured.
    """
    app = get_firebase_app()
    is_mock = allow_mock or os.getenv('MOCK_FCM', 'false').lower() in ('true', '1', 'yes')

    if not app:
        if is_mock:
            device_str_id = str(device.id)[:8] if device.id else 'simulated'
            mock_id = f"mock-msg-{device_str_id}"
            logger.info(f"[MOCK FCM] Simulated push notification to device {device.id} ({device.user.email}): '{title}'")
            NotificationHistory.objects.create(
                user=device.user,
                device=device,
                title=title,
                message=body,
                channel='FCM',
                status='SENT',
                error_details='[SIMULATED] Delivered in MOCK mode (No Firebase service account configured)'
            )
            return True, mock_id

        error_msg = (
            "Firebase Admin credentials not found. Place 'firebase-service-account.json' "
            "in the backend directory or set FIREBASE_CREDENTIALS_PATH in backend/.env. "
            "(Or run with --mock-fcm / set MOCK_FCM=True in .env for development testing)."
        )
        logger.error(error_msg)
        NotificationHistory.objects.create(
            user=device.user,
            device=device,
            title=title,
            message=body,
            channel='FCM',
            status='FAILED',
            error_details=error_msg
        )
        return False, error_msg

    str_data = {}
    if data:
        str_data = {str(k): str(v) for k, v in data.items() if v is not None}

    # Android high-importance notification config
    android_config = messaging.AndroidConfig(
        priority='high',
        notification=messaging.AndroidNotification(
            channel_id='aws_guardian_alerts_channel',
            priority='high',
            sound='default',
            default_sound=True,
            default_vibrate_timings=True,
            visibility='public',
        ),
        data=str_data,
    )

    # iOS APNs config
    apns_config = messaging.APNSConfig(
        payload=messaging.APNSPayload(
            aps=messaging.Aps(
                alert=messaging.ApsAlert(
                    title=title,
                    body=body,
                ),
                sound='default',
                badge=1,
            )
        )
    )

    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        data=str_data,
        android=android_config,
        apns=apns_config,
        token=device.fcm_token,
    )

    try:
        response = messaging.send(message)
        logger.info(f"FCM message successfully sent to device {device.id}: {response}")
        
        NotificationHistory.objects.create(
            user=device.user,
            device=device,
            title=title,
            message=body,
            channel='FCM',
            status='SENT',
            error_details=''
        )
        return True, response

    except messaging.UnregisteredError:
        logger.warning(f"FCM Token unregistered for device {device.id}. Marking device inactive.")
        device.is_active = False
        device.save(update_fields=['is_active', 'updated_at'])
        err = "Device token is no longer registered. Device marked inactive."
        NotificationHistory.objects.create(
            user=device.user,
            device=device,
            title=title,
            message=body,
            channel='FCM',
            status='FAILED',
            error_details=err
        )
        return False, err

    except messaging.SenderIdMismatchError:
        logger.warning(f"FCM SenderId mismatch for device {device.id}. Marking device inactive.")
        device.is_active = False
        device.save(update_fields=['is_active', 'updated_at'])
        err = "Sender ID mismatch. Device marked inactive."
        NotificationHistory.objects.create(
            user=device.user,
            device=device,
            title=title,
            message=body,
            channel='FCM',
            status='FAILED',
            error_details=err
        )
        return False, err

    except Exception as e:
        err = str(e)
        if "DefaultCredentialsError" in type(e).__name__ or "credentials" in err.lower():
            logger.error(
                f"FCM authentication failed for device {device.id}: {err}. "
                "Ensure 'firebase-service-account.json' is placed in backend/ directory."
            )
        else:
            logger.exception(f"Failed to send FCM message to device {device.id}: {e}")

        NotificationHistory.objects.create(
            user=device.user,
            device=device,
            title=title,
            message=body,
            channel='FCM',
            status='FAILED',
            error_details=err
        )
        return False, err


def send_fcm_to_user(
    user,
    title: str,
    body: str,
    data: Optional[Dict[str, Any]] = None,
    notification_type: str = "alert",
    allow_mock: bool = False
) -> Tuple[int, int]:
    """
    Sends an FCM notification to all active registered devices of a given user.
    Returns (success_count, failure_count).
    """
    devices = FCMDevice.objects.filter(user=user, is_active=True)
    if not devices.exists():
        logger.info(f"No active FCM devices found for user {user.email}.")
        return 0, 0

    payload = dict(data or {})
    payload.setdefault('type', notification_type)

    success_count = 0
    failure_count = 0

    for device in devices:
        success, _ = send_fcm_notification(
            device=device,
            title=title,
            body=body,
            data=payload,
            allow_mock=allow_mock
        )
        if success:
            success_count += 1
        else:
            failure_count += 1

    log_audit_event(
        user,
        'FCM_NOTIFICATION_SENT',
        {
            'title': title,
            'type': notification_type,
            'success_count': success_count,
            'failure_count': failure_count,
            'devices_count': len(devices)
        }
    )

    return success_count, failure_count
