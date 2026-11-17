import jwt
import uuid
from datetime import datetime, timezone
from django.conf import settings
import logging

logger = logging.getLogger(__name__)

def is_valid_uuid(val):
    if not val or str(val).strip() in ('null', 'undefined', 'None', ''):
        return False
    try:
        uuid.UUID(str(val).strip())
        return True
    except (ValueError, AttributeError, TypeError):
        return False

def generate_jwt_token(user):
    payload = {
        'user_id': str(user.id),
        'email': user.email,
        'name': user.name,
        'exp': datetime.now(timezone.utc) + settings.JWT_ACCESS_TOKEN_LIFETIME,
        'iat': datetime.now(timezone.utc),
    }
    return jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm='HS256')

def decode_jwt_token(token):
    try:
        payload = jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=['HS256'])
        return payload
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None

def custom_exception_handler(exc, context):
    from rest_framework.views import exception_handler
    from rest_framework.response import Response
    from rest_framework import status

    response = exception_handler(exc, context)

    if response is not None:
        error_msg = "An error occurred."
        if isinstance(response.data, dict):
            if 'detail' in response.data:
                error_msg = response.data['detail']
            elif 'non_field_errors' in response.data:
                error_msg = ' '.join(str(e) for e in response.data['non_field_errors'])
            else:
                first_key = next(iter(response.data))
                first_val = response.data[first_key]
                if isinstance(first_val, list):
                    error_msg = f"{first_key}: {' '.join(str(e) for e in first_val)}"
                else:
                    error_msg = f"{first_key}: {str(first_val)}"
        elif isinstance(response.data, list):
            error_msg = ' '.join(str(e) for e in response.data)

        response.data = {
            'success': False,
            'message': str(error_msg),
            'errors': response.data
        }
    else:
        logger.error(f"Unhandled Exception: {str(exc)}", exc_info=True)
        response = Response({
            'success': False,
            'message': 'Internal server error occurred. Please try again.',
            'errors': str(exc) if settings.DEBUG else 'Internal server error'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    return response
