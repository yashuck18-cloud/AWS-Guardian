import logging
from .cost_service import AWS_SERVICE_HOURLY_RATES

logger = logging.getLogger(__name__)

def scan_load_balancers(session, region):
    """
    Scans Elastic Load Balancers (Application/Network) in the given region with authoritative pricing.
    """
    results = []
    try:
        elbv2 = session.client('elbv2', region_name=region)
        paginator = elbv2.get_paginator('describe_load_balancers')

        for page in paginator.paginate():
            for lb in page.get('LoadBalancers', []):
                lb_arn = lb.get('LoadBalancerArn', 'N/A')
                lb_name = lb.get('LoadBalancerName', 'N/A')
                dns_name = lb.get('DNSName', 'N/A')
                state = lb.get('State', {}).get('Code', 'active')
                lb_type = lb.get('Type', 'application')
                scheme = lb.get('Scheme', 'internet-facing')
                created_time = lb.get('CreatedTime')
                vpc_id = lb.get('VpcId', 'N/A')
                az_list = [az.get('ZoneName') for az in lb.get('AvailabilityZones', []) if az.get('ZoneName')]
                sg_list = lb.get('SecurityGroups', [])

                # Base ELB cost ~$0.0225/hr
                hourly_cost = AWS_SERVICE_HOURLY_RATES['ELB']

                # Query target groups to check target count
                target_count = 0
                try:
                    tg_resp = elbv2.describe_target_groups(LoadBalancerArn=lb_arn)
                    for tg in tg_resp.get('TargetGroups', []):
                        tg_arn = tg.get('TargetGroupArn')
                        th_resp = elbv2.describe_target_health(TargetGroupArn=tg_arn)
                        target_count += len(th_resp.get('TargetHealthDescriptions', []))
                except Exception:
                    pass

                results.append({
                    'service': 'ELB',
                    'resource_id': lb_name,
                    'name': lb_name,
                    'region': region,
                    'state': state,
                    'resource_type': f"{lb_type.title()} Load Balancer",
                    'estimated_hourly_cost': hourly_cost,
                    'metadata': {
                        'load_balancer_name': lb_name,
                        'arn': lb_arn,
                        'dns_name': dns_name,
                        'type': lb_type,
                        'scheme': scheme,
                        'state': state,
                        'region': region,
                        'vpc_id': vpc_id,
                        'availability_zones': az_list,
                        'security_groups': sg_list,
                        'created_time': created_time.isoformat() if created_time else 'N/A',
                        'target_count': target_count,
                        'pricing_rate': hourly_cost,
                        'pricing_unit': 'Hrs',
                        'cost_source': 'AWS_PRICING',
                        'billing_status': 'PRICING_ESTIMATE',
                    }
                })
    except Exception as e:
        logger.warning(f"ELB scan failed in {region}: {e}")
        raise e

    return results

