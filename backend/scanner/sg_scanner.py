import logging
import ipaddress

logger = logging.getLogger(__name__)

def is_cidr_open_to_world(ip_ranges, ipv6_ranges):
    """
    Checks if any CIDR range permits ingress from the public internet (0.0.0.0/0 or any non-private IP).
    """
    for r in ip_ranges:
        cidr = r.get('CidrIp')
        if not cidr:
            continue
        if cidr == '0.0.0.0/0':
            return True
        try:
            net = ipaddress.ip_network(cidr, strict=False)
            if not net.is_private and not net.is_loopback and not net.is_link_local:
                return True
        except Exception:
            pass

    for r in ipv6_ranges:
        cidr = r.get('CidrIpv6')
        if not cidr:
            continue
        if cidr == '::/0':
            return True
        try:
            net = ipaddress.ip_network(cidr, strict=False)
            if not net.is_private and not net.is_loopback and not net.is_link_local:
                return True
        except Exception:
            pass

    return False

def scan_security_groups(session, region):
    """
    Scans EC2 Security Groups in the given AWS region and checks for overly permissive inbound rules.
    """
    results = []
    try:
        ec2 = session.client('ec2', region_name=region)
        paginator = ec2.get_paginator('describe_security_groups')

        for page in paginator.paginate():
            for group in page.get('SecurityGroups', []):
                group_id = group.get('GroupId')
                group_name = group.get('GroupName', '')
                description = group.get('Description', '')
                vpc_id = group.get('VpcId', '')
                tags = {t.get('Key'): t.get('Value') for t in group.get('Tags', [])}
                name = tags.get('Name') or group_name

                ip_permissions = group.get('IpPermissions', [])
                ip_permissions_egress = group.get('IpPermissionsEgress', [])

                has_open_ssh = False
                has_open_rdp = False
                has_open_all = False
                has_open_db = False
                open_ports = []

                db_ports = {3306, 5432, 27017, 6379, 1433, 1521, 9200}

                parsed_ingress = []
                for perm in ip_permissions:
                    ip_protocol = perm.get('IpProtocol', '-1')
                    from_port = perm.get('FromPort')
                    to_port = perm.get('ToPort')
                    ip_ranges = perm.get('IpRanges', [])
                    ipv6_ranges = perm.get('Ipv6Ranges', [])

                    is_world = is_cidr_open_to_world(ip_ranges, ipv6_ranges)

                    if is_world:
                        if ip_protocol == '-1':
                            has_open_all = True
                            open_ports.append('ALL')
                        elif from_port is not None and to_port is not None:
                            if from_port <= 22 <= to_port:
                                has_open_ssh = True
                            if from_port <= 3389 <= to_port:
                                has_open_rdp = True
                            for db_p in db_ports:
                                if from_port <= db_p <= to_port:
                                    has_open_db = True
                            if from_port == to_port:
                                open_ports.append(str(from_port))
                            else:
                                open_ports.append(f"{from_port}-{to_port}")

                    parsed_ingress.append({
                        'protocol': ip_protocol,
                        'from_port': from_port,
                        'to_port': to_port,
                        'is_world_open': is_world,
                        'ip_ranges': [r.get('CidrIp') for r in ip_ranges if r.get('CidrIp')],
                        'ipv6_ranges': [r.get('CidrIpv6') for r in ipv6_ranges if r.get('CidrIpv6')],
                    })

                results.append({
                    'service': 'SG',
                    'resource_id': group_id,
                    'name': name,
                    'region': region,
                    'state': 'active',
                    'resource_type': f"Security Group ({len(ip_permissions)} Ingress Rules)",
                    'estimated_hourly_cost': 0.0,
                    'metadata': {
                        'group_id': group_id,
                        'group_name': group_name,
                        'description': description,
                        'vpc_id': vpc_id,
                        'tags': tags,
                        'inbound_rules_count': len(ip_permissions),
                        'outbound_rules_count': len(ip_permissions_egress),
                        'inbound_rules': parsed_ingress,
                        'has_open_ssh': has_open_ssh,
                        'has_open_rdp': has_open_rdp,
                        'has_open_all': has_open_all,
                        'has_open_db': has_open_db,
                        'open_ports': list(set(open_ports)),
                    }
                })

    except Exception as e:
        logger.warning(f"Security Group scan failed in {region}: {e}")
        raise e

    return results
