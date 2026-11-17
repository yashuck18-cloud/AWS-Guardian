import logging
from datetime import datetime, timezone, timedelta
from .cost_service import AWS_SERVICE_HOURLY_RATES

logger = logging.getLogger(__name__)

def scan_s3_buckets(session):
    """
    Scans S3 buckets across the AWS account (global service) with authoritative pricing and storage metrics.
    """
    results = []
    try:
        s3 = session.client('s3')
        response = s3.list_buckets()
        
        for bucket in response.get('Buckets', []):
            bucket_name = bucket.get('Name', 'N/A')
            create_date = bucket.get('CreationDate')

            # Determine region (S3 is a global AWS service)
            region = 'global'
            try:
                loc_resp = s3.get_bucket_location(Bucket=bucket_name)
                loc_constraint = loc_resp.get('LocationConstraint')
                if loc_constraint:
                    # In AWS S3, EU location constraint is 'EU' which maps to 'eu-west-1'
                    region = 'eu-west-1' if loc_constraint == 'EU' else loc_constraint
                elif loc_constraint is None:
                    region = 'us-east-1'
            except Exception:
                region = 'global'

            # Check public access block
            is_public = False
            try:
                pab = s3.get_public_access_block(Bucket=bucket_name)
                config = pab.get('PublicAccessBlockConfiguration', {})
                if not (config.get('BlockPublicAcls') and config.get('BlockPublicPolicy')):
                    is_public = True
            except Exception:
                pass

            # Check versioning status
            versioning_status = 'Disabled'
            try:
                ver_resp = s3.get_bucket_versioning(Bucket=bucket_name)
                versioning_status = ver_resp.get('Status', 'Disabled')
            except Exception:
                pass

            # Check encryption
            encryption_type = 'None'
            try:
                enc_resp = s3.get_bucket_encryption(Bucket=bucket_name)
                rules = enc_resp.get('ServerSideEncryptionConfiguration', {}).get('Rules', [])
                if rules:
                    encryption_type = rules[0].get('ApplyServerSideEncryptionByDefault', {}).get('SSEAlgorithm', 'AES256')
            except Exception:
                pass

            # CloudWatch storage metrics (approximate bucket size & object count)
            storage_bytes = 0
            object_count = 0
            try:
                cw = session.client('cloudwatch', region_name=region if region != 'global' else 'us-east-1')
                now = datetime.now(timezone.utc)
                # S3 Daily storage metrics
                cw_resp = cw.get_metric_data(
                    MetricDataQueries=[
                        {
                            'Id': 'm1',
                            'MetricStat': {
                                'Metric': {
                                    'Namespace': 'AWS/S3',
                                    'MetricName': 'BucketSizeBytes',
                                    'Dimensions': [
                                        {'Name': 'BucketName', 'Value': bucket_name},
                                        {'Name': 'StorageType', 'Value': 'StandardStorage'}
                                    ]
                                },
                                'Period': 86400,
                                'Stat': 'Average',
                            },
                        },
                        {
                            'Id': 'm2',
                            'MetricStat': {
                                'Metric': {
                                    'Namespace': 'AWS/S3',
                                    'MetricName': 'NumberOfObjects',
                                    'Dimensions': [
                                        {'Name': 'BucketName', 'Value': bucket_name},
                                        {'Name': 'StorageType', 'Value': 'AllStorageTypes'}
                                    ]
                                },
                                'Period': 86400,
                                'Stat': 'Average',
                            },
                        }
                    ],
                    StartTime=now - timedelta(days=2),
                    EndTime=now
                )
                for res in cw_resp.get('MetricDataResults', []):
                    if res.get('Id') == 'm1' and res.get('Values'):
                        storage_bytes = int(res['Values'][0])
                    elif res.get('Id') == 'm2' and res.get('Values'):
                        object_count = int(res['Values'][0])
            except Exception:
                pass

            storage_gb = storage_bytes / (1024 ** 3)
            monthly_cost = storage_gb * AWS_SERVICE_HOURLY_RATES['S3_PER_GB']
            hourly_cost = round(monthly_cost / 730.0, 6)

            results.append({
                'service': 'S3',
                'resource_id': bucket_name,
                'name': bucket_name,
                'region': region,
                'state': 'active',
                'resource_type': 'S3 Standard Bucket',
                'estimated_hourly_cost': hourly_cost,
                'metadata': {
                    'bucket_name': bucket_name,
                    'region': region,
                    'creation_date': create_date.isoformat() if create_date else 'N/A',
                    'storage_size_bytes': storage_bytes,
                    'storage_size_formatted': f"{round(storage_gb, 2)} GB" if storage_gb >= 0.01 else f"{round(storage_bytes / 1024, 1)} KB" if storage_bytes > 0 else '0 B',
                    'object_count': object_count,
                    'storage_class': 'Standard',
                    'versioning': versioning_status,
                    'encryption': encryption_type,
                    'is_public': is_public,
                    'pricing_rate': AWS_SERVICE_HOURLY_RATES['S3_PER_GB'],
                    'pricing_unit': 'GB-Month',
                    'cost_source': 'AWS_PRICING',
                    'billing_status': 'PRICING_ESTIMATE',
                }
            })
    except Exception as e:
        logger.warning(f"S3 scan failed: {e}")
        raise e

    return results

