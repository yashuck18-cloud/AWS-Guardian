import logging
from .cost_service import get_ebs_hourly_pricing

logger = logging.getLogger(__name__)

def scan_ebs_volumes(session, region):
    """
    Scans EBS volumes in the given region with authoritative pricing and deep metadata.
    """
    results = []
    try:
        ec2 = session.client('ec2', region_name=region)
        paginator = ec2.get_paginator('describe_volumes')
        
        for page in paginator.paginate():
            for volume in page.get('Volumes', []):
                vol_id = volume.get('VolumeId', 'N/A')
                state = volume.get('State', 'unknown')
                size_gb = volume.get('Size', 8)
                vol_type = volume.get('VolumeType', 'gp3')
                create_time = volume.get('CreateTime')
                az = volume.get('AvailabilityZone', f"{region}a")
                iops = volume.get('Iops', 3000 if vol_type == 'gp3' else 0)
                throughput = volume.get('Throughput', 125 if vol_type == 'gp3' else 0)
                encrypted = volume.get('Encrypted', False)
                kms_key_id = volume.get('KmsKeyId', 'N/A')
                snapshot_id = volume.get('SnapshotId', 'N/A')
                
                attachments = volume.get('Attachments', [])
                is_attached = len(attachments) > 0
                attached_instance_id = attachments[0].get('InstanceId') if is_attached else 'N/A'
                attached_device = attachments[0].get('Device') if is_attached else 'N/A'
                attach_time = attachments[0].get('AttachTime') if is_attached else None
                
                tags = {t.get('Key'): t.get('Value') for t in volume.get('Tags', [])}
                name = tags.get('Name', '')

                # Hourly pricing using authoritative rates
                hourly_cost = get_ebs_hourly_pricing(
                    volume_type=vol_type,
                    size_gb=size_gb,
                    iops=iops,
                    throughput_mbs=throughput
                )

                results.append({
                    'service': 'EBS',
                    'resource_id': vol_id,
                    'name': name,
                    'region': region,
                    'state': state,
                    'resource_type': f"{vol_type} ({size_gb} GB)",
                    'estimated_hourly_cost': hourly_cost,
                    'metadata': {
                        'volume_id': vol_id,
                        'volume_name': name or 'N/A',
                        'volume_type': vol_type,
                        'size_gb': size_gb,
                        'iops': iops,
                        'throughput_mbs': throughput,
                        'availability_zone': az,
                        'state': state,
                        'is_attached': is_attached,
                        'attached_instance_id': attached_instance_id,
                        'attached_device': attached_device,
                        'attach_time': attach_time.isoformat() if attach_time else 'N/A',
                        'create_time': create_time.isoformat() if create_time else 'N/A',
                        'encrypted': encrypted,
                        'kms_key_id': kms_key_id,
                        'snapshot_id': snapshot_id,
                        'tags': tags,
                        'pricing_rate': hourly_cost,
                        'pricing_unit': 'Hrs',
                        'cost_source': 'AWS_PRICING',
                        'billing_status': 'PRICING_ESTIMATE',
                    }
                })
    except Exception as e:
        logger.warning(f"EBS scan failed in {region}: {e}")
        raise e

    return results

