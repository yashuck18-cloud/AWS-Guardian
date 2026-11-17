import logging
from .cost_service import AWS_SERVICE_HOURLY_RATES

logger = logging.getLogger(__name__)

def scan_elastic_ips(session, region):
    """
    Scans Elastic IP addresses in the given region with authoritative pricing and metadata.
    """
    results = []
    try:
        ec2 = session.client('ec2', region_name=region)
        response = ec2.describe_addresses()
        
        for addr in response.get('Addresses', []):
            alloc_id = addr.get('AllocationId') or addr.get('PublicIp') or 'N/A'
            public_ip = addr.get('PublicIp', 'N/A')
            private_ip = addr.get('PrivateIpAddress', 'N/A')
            association_id = addr.get('AssociationId', 'N/A')
            instance_id = addr.get('InstanceId', 'N/A')
            eni_id = addr.get('NetworkInterfaceId', 'N/A')
            domain = addr.get('Domain', 'vpc')
            ptr_record = addr.get('PublicIpv4Pool', 'amazon')
            
            tags = {t.get('Key'): t.get('Value') for t in addr.get('Tags', [])}
            name = tags.get('Name', public_ip)

            is_associated = bool(addr.get('AssociationId') or addr.get('InstanceId'))
            state = 'associated' if is_associated else 'unassociated'

            # AWS Public IPv4 addresses are billed at $0.005/hr
            hourly_cost = AWS_SERVICE_HOURLY_RATES['EIP']

            associated_resource = f"Instance: {instance_id}" if instance_id != 'N/A' else f"ENI: {eni_id}" if eni_id != 'N/A' else 'None'

            results.append({
                'service': 'EIP',
                'resource_id': alloc_id,
                'name': name,
                'region': region,
                'state': state,
                'resource_type': 'IPv4 Elastic IP',
                'estimated_hourly_cost': hourly_cost,
                'metadata': {
                    'allocation_id': alloc_id,
                    'public_ip': public_ip,
                    'private_ip': private_ip,
                    'region': region,
                    'state': state,
                    'is_associated': is_associated,
                    'associated_resource': associated_resource,
                    'association_id': association_id,
                    'instance_id': instance_id,
                    'network_interface_id': eni_id,
                    'domain': domain,
                    'public_ipv4_pool': ptr_record,
                    'tags': tags,
                    'pricing_rate': hourly_cost,
                    'pricing_unit': 'Hrs',
                    'cost_source': 'AWS_PRICING',
                    'billing_status': 'PRICING_ESTIMATE',
                }
            })
    except Exception as e:
        logger.warning(f"EIP scan failed in {region}: {e}")
        raise e

    return results

