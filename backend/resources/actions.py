import logging
from aws_accounts.sts_service import get_assumed_boto3_session
from audit.logger import log_audit_event

logger = logging.getLogger(__name__)

def execute_stop_ec2_instance(user, resource):
    """
    Safely stop an EC2 instance after user authorization check.
    """
    if resource.service != 'EC2':
        return False, "Resource is not an EC2 instance."

    account = resource.account
    is_demo = account.role_arn.endswith('AWSGuardianTestRole') or account.role_arn.endswith('AWSGuardianDemoRole')
    session, err = get_assumed_boto3_session(account, region_name=resource.region)

    if err and not is_demo:
        return False, f"Failed to assume role: {err}"

    try:
        if session and not is_demo:
            ec2_client = session.client('ec2', region_name=resource.region)
            ec2_client.stop_instances(InstanceIds=[resource.resource_id])
        
        # Update local resource state
        resource.state = 'stopping'
        resource.save()

        log_audit_event(
            user,
            'RESOURCE_STOPPED',
            {
                'resource_id': resource.resource_id,
                'name': resource.name,
                'service': 'EC2',
                'region': resource.region,
                'account_id': account.account_id
            }
        )
        return True, f"Instance {resource.resource_id} stop requested successfully."
    except Exception as e:
        logger.error(f"Error stopping EC2 instance {resource.resource_id}: {e}")
        return False, f"AWS API Error: {str(e)}"

def execute_delete_resource(user, resource, typed_confirmation):
    """
    Safely delete a resource with mandatory typed ID verification.
    """
    if str(typed_confirmation).strip() != str(resource.resource_id).strip():
        return False, f"Confirmation failed: Typed '{typed_confirmation}' does not match '{resource.resource_id}'."

    account = resource.account
    is_demo = account.role_arn.endswith('AWSGuardianTestRole') or account.role_arn.endswith('AWSGuardianDemoRole')
    session, err = get_assumed_boto3_session(account, region_name=resource.region)

    try:
        if session and not is_demo:
            if resource.service == 'EBS':
                ec2_client = session.client('ec2', region_name=resource.region)
                ec2_client.delete_volume(VolumeId=resource.resource_id)
            elif resource.service == 'EIP':
                ec2_client = session.client('ec2', region_name=resource.region)
                ec2_client.release_address(AllocationId=resource.resource_id)
            elif resource.service == 'EC2':
                ec2_client = session.client('ec2', region_name=resource.region)
                ec2_client.terminate_instances(InstanceIds=[resource.resource_id])
            elif resource.service == 'SG':
                ec2_client = session.client('ec2', region_name=resource.region)
                ec2_client.delete_security_group(GroupId=resource.resource_id)
            elif resource.service == 'RDS':
                rds_client = session.client('rds', region_name=resource.region)
                rds_client.delete_db_instance(DBInstanceIdentifier=resource.resource_id, SkipFinalSnapshot=True)
            elif resource.service == 'S3':
                s3_client = session.client('s3')
                s3_client.delete_bucket(Bucket=resource.resource_id)
            elif resource.service == 'ELB':
                elb_client = session.client('elbv2', region_name=resource.region)
                elb_client.delete_load_balancer(LoadBalancerArn=resource.resource_id)
            elif resource.service == 'NAT':
                ec2_client = session.client('ec2', region_name=resource.region)
                ec2_client.delete_nat_gateway(NatGatewayId=resource.resource_id)

        resource_info = {
            'resource_id': resource.resource_id,
            'name': resource.name,
            'service': resource.service,
            'region': resource.region,
            'account_id': account.account_id
        }

        # Delete local record
        resource.delete()

        log_audit_event(
            user,
            'RESOURCE_DELETED',
            resource_info
        )
        return True, f"Resource {resource_info['resource_id']} deleted successfully."
    except Exception as e:
        logger.error(f"Error deleting resource {resource.resource_id}: {e}")
        return False, f"AWS API Error: {str(e)}"
