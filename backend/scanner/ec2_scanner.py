import logging
from .cost_service import get_ec2_hourly_pricing

logger = logging.getLogger(__name__)

def scan_ec2_instances(session, region):
    """
    Scans EC2 instances in the given region using the assumed session.
    Retrieves full authoritative configuration, network, storage, tags, and pricing rates.
    """
    results = []
    try:
        ec2 = session.client('ec2', region_name=region)
        paginator = ec2.get_paginator('describe_instances')
        
        for page in paginator.paginate():
            for reservation in page.get('Reservations', []):
                for instance in reservation.get('Instances', []):
                    instance_id = instance.get('InstanceId', 'N/A')
                    state = instance.get('State', {}).get('Name', 'unknown')
                    instance_type = instance.get('InstanceType', 'N/A')
                    launch_time = instance.get('LaunchTime')
                    
                    # Tags
                    tags = {t.get('Key'): t.get('Value') for t in instance.get('Tags', [])}
                    name = tags.get('Name', '')

                    # Platform / OS
                    platform = instance.get('Platform') or instance.get('PlatformDetails') or 'Linux/UNIX'
                    arch = instance.get('Architecture', 'x86_64')

                    # Placement & Network
                    placement = instance.get('Placement', {})
                    az = placement.get('AvailabilityZone', f"{region}a")
                    tenancy = placement.get('Tenancy', 'default')

                    pub_ip = instance.get('PublicIpAddress') or 'N/A'
                    priv_ip = instance.get('PrivateIpAddress') or 'N/A'
                    pub_dns = instance.get('PublicDnsName') or 'N/A'
                    priv_dns = instance.get('PrivateDnsName') or 'N/A'
                    vpc_id = instance.get('VpcId') or 'N/A'
                    subnet_id = instance.get('SubnetId') or 'N/A'

                    # Security Groups & Keys
                    sg_list = [f"{sg.get('GroupId')} ({sg.get('GroupName')})" for sg in instance.get('SecurityGroups', [])]
                    sg_ids = [sg.get('GroupId') for sg in instance.get('SecurityGroups', []) if sg.get('GroupId')]
                    key_name = instance.get('KeyName') or 'N/A'
                    ami_id = instance.get('ImageId') or 'N/A'

                    # Storage & Monitoring
                    root_device_name = instance.get('RootDeviceName') or 'N/A'
                    root_device_type = instance.get('RootDeviceType') or 'ebs'
                    block_devices = instance.get('BlockDeviceMappings', [])
                    ebs_vol_ids = [bd.get('Ebs', {}).get('VolumeId') for bd in block_devices if bd.get('Ebs', {}).get('VolumeId')]

                    monitoring_state = instance.get('Monitoring', {}).get('State', 'disabled')
                    iam_profile = instance.get('IamInstanceProfile', {}).get('Arn', 'N/A')
                    cpu_options = instance.get('CpuOptions', {})
                    cpu_cores = cpu_options.get('CoreCount', 'N/A')
                    threads_per_core = cpu_options.get('ThreadsPerCore', 'N/A')

                    # Authoritative Hourly Pricing
                    hourly_cost = get_ec2_hourly_pricing(
                        instance_type=instance_type,
                        region=region,
                        os_platform=platform
                    )

                    results.append({
                        'service': 'EC2',
                        'resource_id': instance_id,
                        'name': name,
                        'region': region,
                        'state': state,
                        'resource_type': instance_type,
                        'estimated_hourly_cost': hourly_cost,
                        'metadata': {
                            'instance_id': instance_id,
                            'instance_name': name or 'N/A',
                            'instance_type': instance_type,
                            'region': region,
                            'availability_zone': az,
                            'state': state,
                            'launch_time': launch_time.isoformat() if launch_time else 'N/A',
                            'platform': platform,
                            'architecture': arch,
                            'private_ip': priv_ip,
                            'public_ip': pub_ip,
                            'private_dns': priv_dns,
                            'public_dns': pub_dns,
                            'vpc_id': vpc_id,
                            'subnet_id': subnet_id,
                            'security_groups': sg_list,
                            'security_group_ids': sg_ids,
                            'key_pair_name': key_name,
                            'ami_id': ami_id,
                            'root_device': root_device_name,
                            'root_device_type': root_device_type,
                            'ebs_volume_ids': ebs_vol_ids,
                            'monitoring_status': monitoring_state,
                            'iam_instance_profile': iam_profile,
                            'tenancy': tenancy,
                            'cpu_cores': cpu_cores,
                            'threads_per_core': threads_per_core,
                            'tags': tags,
                            'pricing_rate': hourly_cost,
                            'pricing_unit': 'Hrs',
                            'cost_source': 'AWS_PRICING',
                            'billing_status': 'PRICING_ESTIMATE',
                        }
                    })
    except Exception as e:
        logger.warning(f"EC2 scan failed in {region}: {e}")
        raise e
        
    return results

