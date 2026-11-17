import logging
from .cost_service import AWS_SERVICE_HOURLY_RATES

logger = logging.getLogger(__name__)

def scan_nat_gateways(session, region):
    """
    Scans NAT Gateways in the given region with authoritative pricing and deep metadata.
    """
    results = []
    try:
        ec2 = session.client('ec2', region_name=region)
        paginator = ec2.get_paginator('describe_nat_gateways')
        
        for page in paginator.paginate():
            for nat in page.get('NatGateways', []):
                nat_id = nat.get('NatGatewayId', 'N/A')
                state = nat.get('State', 'unknown')
                vpc_id = nat.get('VpcId', 'N/A')
                subnet_id = nat.get('SubnetId', 'N/A')
                create_time = nat.get('CreateTime')
                conn_type = nat.get('ConnectivityType', 'public')
                
                tags = {t.get('Key'): t.get('Value') for t in nat.get('Tags', [])}
                name = tags.get('Name', nat_id)

                addresses = nat.get('NatGatewayAddresses', [])
                public_ips = [a.get('PublicIp') for a in addresses if a.get('PublicIp')]
                private_ips = [a.get('PrivateIp') for a in addresses if a.get('PrivateIp')]
                allocation_ids = [a.get('AllocationId') for a in addresses if a.get('AllocationId')]
                eni_ids = [a.get('NetworkInterfaceId') for a in addresses if a.get('NetworkInterfaceId')]

                # Base NAT Gateway cost ~$0.045/hr
                hourly_cost = AWS_SERVICE_HOURLY_RATES['NAT'] if state == 'available' else 0.000

                results.append({
                    'service': 'NAT',
                    'resource_id': nat_id,
                    'name': name,
                    'region': region,
                    'state': state,
                    'resource_type': 'VPC NAT Gateway',
                    'estimated_hourly_cost': hourly_cost,
                    'metadata': {
                        'nat_gateway_id': nat_id,
                        'state': state,
                        'region': region,
                        'vpc_id': vpc_id,
                        'subnet_id': subnet_id,
                        'connectivity_type': conn_type,
                        'public_ips': public_ips,
                        'primary_public_ip': public_ips[0] if public_ips else 'N/A',
                        'private_ips': private_ips,
                        'primary_private_ip': private_ips[0] if private_ips else 'N/A',
                        'allocation_ids': allocation_ids,
                        'elastic_ip_allocation': allocation_ids[0] if allocation_ids else 'N/A',
                        'network_interface_ids': eni_ids,
                        'create_time': create_time.isoformat() if create_time else 'N/A',
                        'tags': tags,
                        'pricing_rate': hourly_cost,
                        'pricing_unit': 'Hrs',
                        'cost_source': 'AWS_PRICING',
                        'billing_status': 'PRICING_ESTIMATE',
                    }
                })
    except Exception as e:
        logger.warning(f"NAT scan failed in {region}: {e}")
        raise e

    return results

