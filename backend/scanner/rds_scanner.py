import logging
from .cost_service import get_rds_hourly_pricing

logger = logging.getLogger(__name__)

def scan_rds_instances(session, region):
    """
    Scans RDS Database Instances in the given region with authoritative pricing and deep metadata.
    """
    results = []
    try:
        rds = session.client('rds', region_name=region)
        paginator = rds.get_paginator('describe_db_instances')
        
        for page in paginator.paginate():
            for db in page.get('DBInstances', []):
                db_id = db.get('DBInstanceIdentifier', 'N/A')
                engine = db.get('Engine', 'postgres')
                engine_ver = db.get('EngineVersion', 'N/A')
                db_class = db.get('DBInstanceClass', 'db.t3.micro')
                state = db.get('DBInstanceStatus', 'unknown')
                create_time = db.get('InstanceCreateTime')
                az = db.get('AvailabilityZone', f"{region}a")
                multi_az = db.get('MultiAZ', False)
                storage_gb = db.get('AllocatedStorage', 20)
                storage_type = db.get('StorageType', 'gp3')
                iops = db.get('Iops', 'N/A')
                
                # Backup & Network configuration
                backup_retention = db.get('BackupRetentionPeriod', 0)
                auto_minor_version_upgrade = db.get('AutoMinorVersionUpgrade', True)
                publicly_accessible = db.get('PubliclyAccessible', False)
                
                endpoint_obj = db.get('Endpoint', {})
                endpoint_addr = endpoint_obj.get('Address', 'N/A')
                endpoint_port = endpoint_obj.get('Port', 'N/A')
                
                # VPC & Security Groups
                db_subnet_group = db.get('DBSubnetGroup', {}).get('DBSubnetGroupName', 'N/A')
                vpc_id = db.get('DBSubnetGroup', {}).get('VpcId', 'N/A')
                vpc_sgs = [sg.get('VpcSecurityGroupId') for sg in db.get('VpcSecurityGroups', []) if sg.get('VpcSecurityGroupId')]
                
                tags = {t.get('Key'): t.get('Value') for t in db.get('TagList', [])}

                # Authoritative pricing calculation
                hourly_cost = get_rds_hourly_pricing(
                    instance_class=db_class,
                    region=region,
                    multi_az=multi_az,
                    storage_gb=storage_gb,
                    publicly_accessible=publicly_accessible
                )

                results.append({
                    'service': 'RDS',
                    'resource_id': db_id,
                    'name': db_id,
                    'region': region,
                    'state': state,
                    'resource_type': f"{engine} ({db_class})",
                    'estimated_hourly_cost': hourly_cost,
                    'metadata': {
                        'db_identifier': db_id,
                        'engine': engine,
                        'engine_version': engine_ver,
                        'db_instance_class': db_class,
                        'region': region,
                        'availability_zone': az,
                        'state': state,
                        'instance_create_time': create_time.isoformat() if create_time else 'N/A',
                        'multi_az': multi_az,
                        'storage_gb': storage_gb,
                        'storage_type': storage_type,
                        'iops': iops,
                        'backup_retention_days': backup_retention,
                        'auto_minor_version_upgrade': auto_minor_version_upgrade,
                        'publicly_accessible': publicly_accessible,
                        'endpoint': endpoint_addr,
                        'port': endpoint_port,
                        'vpc_id': vpc_id,
                        'db_subnet_group': db_subnet_group,
                        'security_groups': vpc_sgs,
                        'tags': tags,
                        'pricing_rate': hourly_cost,
                        'pricing_unit': 'Hrs',
                        'cost_source': 'AWS_PRICING',
                        'billing_status': 'PRICING_ESTIMATE',
                    }
                })
    except Exception as e:
        logger.warning(f"RDS scan failed in {region}: {e}")
        raise e

    return results

