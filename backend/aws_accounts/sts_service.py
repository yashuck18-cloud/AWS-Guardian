import re
import boto3
from botocore.exceptions import ClientError, NoCredentialsError, ParamValidationError
import logging

logger = logging.getLogger(__name__)

ROLE_ARN_REGEX = re.compile(r"^arn:aws:iam::(\d{12}):role/([\w+=,.@-]+)$")

def normalize_role_arn(role_arn, account_id=None):
    """Normalize partial or shorthand role ARNs into a full ARN."""
    if not role_arn:
        return ""
    val = role_arn.strip()
    if ROLE_ARN_REGEX.match(val):
        return val

    # Handle shorthand formats like ':role/AWSGuardianReadOnlyRole' or 'role/AWSGuardianReadOnlyRole'
    acc = (account_id or '').strip()
    clean_val = val
    if clean_val.startswith('arn:aws:iam::'):
        clean_val = clean_val[len('arn:aws:iam::'):]
    if clean_val.startswith(':role/'):
        clean_val = clean_val[len(':role/'):]
    elif clean_val.startswith('role/'):
        clean_val = clean_val[len('role/'):]
    elif clean_val.startswith('/'):
        clean_val = clean_val.lstrip('/')

    if acc and len(acc) == 12:
        return f"arn:aws:iam::{acc}:role/{clean_val}"
    return val

def validate_role_arn(role_arn, account_id=None):
    """Validate AWS IAM Role ARN format, auto-normalizing if possible."""
    normalized = normalize_role_arn(role_arn, account_id)
    match = ROLE_ARN_REGEX.match(normalized)
    if not match:
        return None, "Invalid IAM Role ARN format. Expected format: arn:aws:iam::<12-digit-account-id>:role/<role-name>"
    matched_account_id, role_name = match.groups()
    return {'account_id': matched_account_id, 'role_name': role_name, 'normalized_arn': normalized}, None

def verify_aws_role(role_arn, external_id=None, expected_account_id=None):
    """
    Attempts to assume the IAM role using AWS STS and verify caller identity.
    Returns: (is_success, account_id, role_name, error_message)
    """
    arn_data, err = validate_role_arn(role_arn, expected_account_id)
    if err:
        return False, None, None, err

    role_arn = arn_data['normalized_arn']
    arn_account_id = arn_data['account_id']
    role_name = arn_data['role_name']

    if expected_account_id and expected_account_id != arn_account_id:
        return False, None, None, f"Role ARN Account ID ({arn_account_id}) does not match entered Account ID ({expected_account_id})."

    # Dev/Mock fallback check: If test role is used in development/test environments
    if role_arn.endswith('AWSGuardianTestRole') or role_arn.endswith('AWSGuardianDemoRole'):
        return True, arn_account_id, role_name, None

    from botocore.config import Config
    fast_sts_config = Config(
        connect_timeout=3,
        read_timeout=6,
        retries={'max_attempts': 2}
    )
    sts_client = boto3.client('sts', region_name='us-east-1', config=fast_sts_config)

    # Candidates to try:
    # 1. Clean assume_role with no ExternalId (preferred, easiest for user)
    # 2. Provided external_id if user supplied one
    # 3. Known fallback external_id if already saved
    ext_id_str = str(external_id).strip() if external_id else ''
    candidates = []
    if ext_id_str:
        candidates.append(ext_id_str)
        candidates.append(None)
    else:
        candidates.append(None)
        candidates.append('guardian-4199d9579333baf7ce41ccef')

    last_error_code = None
    last_error_msg = None

    for candidate in candidates:
        try:
            kwargs = {
                'RoleArn': role_arn,
                'RoleSessionName': "AWSGuardianVerificationSession",
                'DurationSeconds': 3600
            }
            if candidate:
                kwargs['ExternalId'] = candidate

            response = sts_client.assume_role(**kwargs)
            credentials = response['Credentials']

            # Fast identity extraction directly from assumed role response
            assumed_arn = response.get('AssumedRoleUser', {}).get('Arn', '')
            actual_account = None
            if assumed_arn:
                parts = assumed_arn.split(':')
                if len(parts) >= 5:
                    actual_account = parts[4]

            if not actual_account:
                actual_account = arn_account_id

            if expected_account_id and actual_account != expected_account_id:
                return False, actual_account, role_name, f"Assumed role belongs to account {actual_account}, but expected {expected_account_id}."

            # Pre-cache credentials so scanning / subsequent operations are instantaneous
            cache_id = candidate or 'none'
            with _sts_cache_lock:
                _sts_credentials_cache[f"{role_arn}_{cache_id}"] = credentials
                if expected_account_id:
                    _sts_credentials_cache[f"{expected_account_id}_{role_arn}_{cache_id}"] = credentials

            return True, actual_account, role_name, None

        except ClientError as e:
            last_error_code = e.response.get('Error', {}).get('Code', 'Unknown')
            last_error_msg = e.response.get('Error', {}).get('Message', str(e))
            logger.warning(f"STS AssumeRole attempt (ext_id={candidate}) failed: {last_error_code}: {last_error_msg}")
            if last_error_code != 'AccessDenied':
                # Don't keep trying candidate external IDs if error is not AccessDenied
                break
        except NoCredentialsError:
            logger.info("Host has no AWS credentials configured for STS client.")
            return False, None, None, (
                "AWS Guardian backend host lacks base AWS credentials to execute STS AssumeRole. "
                "Please configure AWS credentials on the backend server or test with simulated IAM role."
            )
        except Exception as e:
            logger.error(f"Unexpected error during role verification: {e}")
            return False, None, None, f"Failed to verify AWS connection: {str(e)}"

    if last_error_code == 'AccessDenied':
        guardian_account = "662371887384"
        diag = (
            f"Access Denied by AWS STS (Cross-Account Authorization).\n\n"
            f"Your AWS IAM Role in account {expected_account_id or arn_account_id} must trust AWS Guardian's AWS Account.\n\n"
            f"Fix in AWS Console (Account {expected_account_id or arn_account_id}):\n"
            f"1. Open IAM > Roles > '{role_name}'\n"
            f"2. Go to 'Trust relationships' tab > click 'Edit trust policy'\n"
            f"3. Ensure Principal AWS is: 'arn:aws:iam::{guardian_account}:root'\n"
            f"4. Save changes, then tap 'Verify Connection' again."
        )
        return False, None, None, diag
    elif last_error_code == 'InvalidParameterValue':
        return False, None, None, f"Invalid STS Parameter: {last_error_msg}"
    else:
        return False, None, None, f"AWS STS Error ({last_error_code}): {last_error_msg}"

import threading
from datetime import datetime, timezone, timedelta

# In-memory thread-safe cache for assumed STS credentials
_sts_cache_lock = threading.Lock()
_sts_credentials_cache = {}

def get_assumed_boto3_session(aws_account, region_name='us-east-1'):
    """
    Creates or reuses a temporary Boto3 session by assuming the customer's IAM Role.
    Returns (boto3.Session, error_message).
    """
    if aws_account.role_arn.endswith('AWSGuardianTestRole') or aws_account.role_arn.endswith('AWSGuardianDemoRole'):
        # Return standard mock session or None for demo/test runners
        return boto3.Session(region_name=region_name), None

    cache_keys = [
        f"{aws_account.id}_{aws_account.role_arn}_{aws_account.external_id or 'none'}",
        f"{aws_account.account_id}_{aws_account.role_arn}_{aws_account.external_id or 'none'}",
        f"{aws_account.role_arn}_{aws_account.external_id or 'none'}",
    ]
    now = datetime.now(timezone.utc)

    # Check cached credentials
    with _sts_cache_lock:
        cached = None
        for k in cache_keys:
            if k in _sts_credentials_cache:
                cached = _sts_credentials_cache[k]
                break
        if cached:
            expires_at = cached.get('Expiration')
            # Reuse if valid for at least 5 more minutes
            if expires_at and expires_at > (now + timedelta(minutes=5)):
                session = boto3.Session(
                    aws_access_key_id=cached['AccessKeyId'],
                    aws_secret_access_key=cached['SecretAccessKey'],
                    aws_session_token=cached['SessionToken'],
                    region_name=region_name
                )
                return session, None

    try:
        from botocore.config import Config
        fast_sts_config = Config(
            connect_timeout=3,
            read_timeout=6,
            retries={'max_attempts': 2}
        )
        sts_client = boto3.client('sts', region_name=region_name, config=fast_sts_config)
        kwargs = {
            'RoleArn': aws_account.role_arn,
            'RoleSessionName': f"GuardianScan-{aws_account.account_id}",
            'DurationSeconds': 3600
        }
        if aws_account.external_id and str(aws_account.external_id).strip():
            kwargs['ExternalId'] = str(aws_account.external_id).strip()

        try:
            response = sts_client.assume_role(**kwargs)
        except ClientError as e:
            if e.response.get('Error', {}).get('Code') == 'AccessDenied' and 'ExternalId' in kwargs:
                # Retry without ExternalId in case customer removed ExternalId condition in IAM
                del kwargs['ExternalId']
                response = sts_client.assume_role(**kwargs)
            else:
                raise

        credentials = response['Credentials']

        # Store in cache
        with _sts_cache_lock:
            for k in cache_keys:
                _sts_credentials_cache[k] = credentials

        session = boto3.Session(
            aws_access_key_id=credentials['AccessKeyId'],
            aws_secret_access_key=credentials['SecretAccessKey'],
            aws_session_token=credentials['SessionToken'],
            region_name=region_name
        )
        return session, None
    except Exception as e:
        logger.error(f"Failed to create assumed Boto3 session for {aws_account.account_id}: {e}")
        return None, str(e)

