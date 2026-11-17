from datetime import datetime, timezone
import dateutil.parser
import logging

logger = logging.getLogger(__name__)

class RuleEvaluationResult:
    def __init__(self, risk_level='NONE', risk_reason='', title='', description='', rule_code='', cost_impact=0.0):
        self.risk_level = risk_level
        self.risk_reason = risk_reason
        self.title = title
        self.description = description
        self.rule_code = rule_code
        self.cost_impact = cost_impact

    @property
    def has_alert(self):
        return self.risk_level in ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')

def parse_iso_datetime(dt_str):
    if not dt_str:
        return None
    try:
        return dateutil.parser.isoparse(str(dt_str))
    except Exception:
        return None

def evaluate_resource_rules(resource, user_preferences=None):
    """
    Evaluates rules against a resource using configured user thresholds.
    """
    prefs = user_preferences or {}
    ec2_threshold_hours = prefs.get('ec2_threshold_hours', 24)
    ebs_threshold_hours = prefs.get('ebs_threshold_hours', 24)

    service = resource.service
    state = resource.state.lower()
    metadata = resource.metadata or {}

    now = datetime.now(timezone.utc)

    # 1. EC2 Instance Rules
    if service == 'EC2':
        launch_time_str = metadata.get('launch_time')
        launch_time = parse_iso_datetime(launch_time_str)
        
        if state == 'running' and launch_time:
            running_hours = (now - launch_time).total_seconds() / 3600.0
            if running_hours > (ec2_threshold_hours * 7):  # Running > 7x threshold (e.g. > 1 week)
                return RuleEvaluationResult(
                    risk_level='CRITICAL',
                    risk_reason=f"Instance running continuously for {int(running_hours)} hours (exceeds {ec2_threshold_hours * 7}h threshold). May require review.",
                    title="Long-Running EC2 Instance (>7 Days)",
                    description=f"EC2 Instance '{resource.name or resource.resource_id}' has been running for {int(running_hours // 24)} days. If this is a non-production test workload, stopping it when idle can prevent unexpected cloud spend.",
                    rule_code='EC2_RUNNING_LONG_TERM',
                    cost_impact=float(resource.estimated_hourly_cost) * 24 * 30
                )
            elif running_hours > ec2_threshold_hours:
                return RuleEvaluationResult(
                    risk_level='HIGH',
                    risk_reason=f"Instance running for {int(running_hours)} hours (exceeds configured {ec2_threshold_hours}h threshold). May require review.",
                    title="EC2 Instance Exceeds Runtime Threshold",
                    description=f"EC2 Instance '{resource.name or resource.resource_id}' has exceeded your test/idle runtime threshold of {ec2_threshold_hours} hours.",
                    rule_code='EC2_RUNNING_THRESHOLD_EXCEEDED',
                    cost_impact=float(resource.estimated_hourly_cost) * 24 * 30
                )
        return RuleEvaluationResult(risk_level='NONE', risk_reason="Instance state within normal operating parameters.")

    # 2. EBS Volume Rules
    elif service == 'EBS':
        # Unattached volume
        if state in ('available', 'unattached'):
            create_time_str = metadata.get('create_time')
            create_time = parse_iso_datetime(create_time_str)
            idle_hours = (now - create_time).total_seconds() / 3600.0 if create_time else 48.0
            
            if idle_hours > ebs_threshold_hours:
                return RuleEvaluationResult(
                    risk_level='HIGH',
                    risk_reason=f"EBS volume is detached/available and accumulating charges for {int(idle_hours)} hours. May require review.",
                    title="Unattached EBS Volume",
                    description=f"EBS volume '{resource.resource_id}' is not attached to any EC2 instance but incurs storage fees. Consider creating a snapshot and removing if unused.",
                    rule_code='EBS_UNATTACHED_VOLUME',
                    cost_impact=float(resource.estimated_hourly_cost) * 24 * 30
                )
        return RuleEvaluationResult(risk_level='NONE', risk_reason="EBS volume is attached and active.")

    # 3. Elastic IP (EIP) Rules
    elif service == 'EIP':
        is_associated = metadata.get('is_associated', False) or state in ('associated', 'in-use')
        if not is_associated or state in ('unassociated', 'available'):
            return RuleEvaluationResult(
                risk_level='HIGH',
                risk_reason="Unassociated Elastic IP address is accruing idle charges. May require review.",
                title="Unassociated Elastic IP",
                description=f"Elastic IP '{resource.name or resource.resource_id}' is reserved on your AWS account but not attached to an active instance or network interface.",
                rule_code='EIP_UNASSOCIATED',
                cost_impact=3.65  # ~$0.005/hr idle EIP charge
            )
        return RuleEvaluationResult(risk_level='NONE', risk_reason="Elastic IP is actively associated.")

    # 4. NAT Gateway Rules
    elif service == 'NAT':
        if state in ('available', 'active'):
            return RuleEvaluationResult(
                risk_level='MEDIUM',
                risk_reason="Active NAT Gateway incurs fixed base hourly pricing ($32+/mo) plus data transfer. May require review.",
                title="Active NAT Gateway Review",
                description=f"NAT Gateway '{resource.name or resource.resource_id}' is active in VPC {metadata.get('vpc_id', 'N/A')}. Verify if private subnet egress is still actively needed.",
                rule_code='NAT_ACTIVE_MONITORING',
                cost_impact=32.85
            )
        return RuleEvaluationResult(risk_level='NONE', risk_reason="NAT Gateway state is inactive.")

    # 5. RDS Database Rules
    elif service == 'RDS':
        create_time_str = metadata.get('instance_create_time')
        create_time = parse_iso_datetime(create_time_str)
        if state == 'available' and create_time:
            running_days = (now - create_time).total_seconds() / 86400.0
            if running_days > 30 and metadata.get('multi_az') is False and 'dev' in (resource.name or '').lower():
                return RuleEvaluationResult(
                    risk_level='HIGH',
                    risk_reason="Development RDS database running for over 30 days. May require review.",
                    title="Long-Running Dev RDS Database",
                    description=f"RDS instance '{resource.name or resource.resource_id}' appears to be a dev database running continuously for {int(running_days)} days.",
                    rule_code='RDS_DEV_LONG_RUNNING',
                    cost_impact=float(resource.estimated_hourly_cost) * 24 * 30
                )
            elif running_days > 14:
                return RuleEvaluationResult(
                    risk_level='MEDIUM',
                    risk_reason=f"RDS instance has been active for {int(running_days)} days. Periodic review recommended.",
                    title="RDS Instance Active Review",
                    description=f"RDS instance '{resource.name or resource.resource_id}' ({resource.resource_type}) has been running for {int(running_days)} days.",
                    rule_code='RDS_ACTIVE_MONITOR',
                    cost_impact=float(resource.estimated_hourly_cost) * 24 * 30
                )
        return RuleEvaluationResult(risk_level='NONE', risk_reason="RDS database operating normally.")

    # 6. S3 Bucket Rules
    elif service == 'S3':
        is_public = metadata.get('is_public', False)
        if is_public:
            return RuleEvaluationResult(
                risk_level='CRITICAL',
                risk_reason="S3 Bucket has public access enabled or missing block public access settings. Immediate review recommended.",
                title="S3 Bucket Public Access Enabled",
                description=f"Bucket '{resource.name or resource.resource_id}' has permissive public access policies enabled.",
                rule_code='S3_PUBLIC_ACCESS',
                cost_impact=0.0
            )
        return RuleEvaluationResult(
            risk_level='LOW',
            risk_reason="Standard S3 bucket storage configuration. Periodic review recommended.",
            title="S3 Bucket Configuration Review",
            description=f"Bucket '{resource.name or resource.resource_id}' in region {resource.region}.",
            rule_code='S3_STANDARD_REVIEW',
            cost_impact=0.0
        )

    # 7. ELB Load Balancer Rules
    elif service == 'ELB':
        active_target_count = metadata.get('target_count', 1)
        if active_target_count == 0 and state in ('active', 'provisioned'):
            return RuleEvaluationResult(
                risk_level='HIGH',
                risk_reason="Load Balancer has 0 registered healthy targets while active. May require review.",
                title="ELB With Zero Active Targets",
                description=f"Load balancer '{resource.name or resource.resource_id}' is active but routing traffic to 0 backend targets.",
                rule_code='ELB_NO_TARGETS',
                cost_impact=16.20
            )
        return RuleEvaluationResult(risk_level='NONE', risk_reason="ELB has active target group routing.")

    # 8. Security Group (SG) Rules
    elif service == 'SG':
        has_open_all = metadata.get('has_open_all', False)
        has_open_ssh = metadata.get('has_open_ssh', False)
        has_open_rdp = metadata.get('has_open_rdp', False)
        has_open_db = metadata.get('has_open_db', False)
        open_ports = metadata.get('open_ports', [])

        if has_open_all:
            return RuleEvaluationResult(
                risk_level='CRITICAL',
                risk_reason="Security Group allows ALL inbound traffic (all ports & protocols) from the public internet (0.0.0.0/0).",
                title="Security Group Open to All Traffic (0.0.0.0/0)",
                description=f"Security Group '{resource.name or resource.resource_id}' ({resource.resource_id}) contains an ingress rule permitting unrestricted 0.0.0.0/0 access on all ports.",
                rule_code='SG_ALL_TRAFFIC_OPEN',
                cost_impact=0.0
            )
        elif has_open_ssh:
            return RuleEvaluationResult(
                risk_level='CRITICAL',
                risk_reason="Security Group exposes SSH management port 22 directly to the public internet (0.0.0.0/0).",
                title="SSH Port 22 Open to Public Internet",
                description=f"Security Group '{resource.name or resource.resource_id}' ({resource.resource_id}) allows inbound SSH (port 22) from 0.0.0.0/0. Restrict to a known bastion or corporate IP CIDR.",
                rule_code='SG_SSH_OPEN_WORLD',
                cost_impact=0.0
            )
        elif has_open_rdp:
            return RuleEvaluationResult(
                risk_level='CRITICAL',
                risk_reason="Security Group exposes Windows RDP port 3389 directly to the public internet (0.0.0.0/0).",
                title="RDP Port 3389 Open to Public Internet",
                description=f"Security Group '{resource.name or resource.resource_id}' ({resource.resource_id}) allows inbound RDP (port 3389) from 0.0.0.0/0. Restrict access to prevent brute force attacks.",
                rule_code='SG_RDP_OPEN_WORLD',
                cost_impact=0.0
            )
        elif has_open_db:
            return RuleEvaluationResult(
                risk_level='HIGH',
                risk_reason=f"Security Group exposes database listening port(s) {', '.join(open_ports)} to the public internet (0.0.0.0/0).",
                title="Database Port Exposed to Public Internet",
                description=f"Security Group '{resource.name or resource.resource_id}' ({resource.resource_id}) allows direct 0.0.0.0/0 access to database services. Database instances should remain in private subnets.",
                rule_code='SG_DATABASE_PORT_OPEN',
                cost_impact=0.0
            )
        elif open_ports:
            return RuleEvaluationResult(
                risk_level='LOW',
                risk_reason=f"Security Group has public internet ingress rules on port(s): {', '.join(open_ports)}.",
                title="Public Web Ingress Rule Active",
                description=f"Security Group '{resource.name or resource.resource_id}' ({resource.resource_id}) allows inbound traffic on port(s) {', '.join(open_ports)} from 0.0.0.0/0.",
                rule_code='SG_PUBLIC_PORTS_REVIEW',
                cost_impact=0.0
            )
        return RuleEvaluationResult(risk_level='NONE', risk_reason="Security Group inbound rules are restricted.")

    return RuleEvaluationResult(risk_level='NONE', risk_reason="No idle or risk indicators detected.")
