import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/toast.dart';
import '../../../core/utils/dialogs.dart';
import '../../../shared/widgets/guardian_card.dart';
import '../../../shared/widgets/guardian_badge.dart';
import '../../../shared/widgets/guardian_button.dart';
import '../../../shared/models/resource_model.dart';
import '../providers/resources_provider.dart';

class ResourceDetailsScreen extends ConsumerStatefulWidget {
  final String resourceId;
  const ResourceDetailsScreen({super.key, required this.resourceId});

  @override
  ConsumerState<ResourceDetailsScreen> createState() => _ResourceDetailsScreenState();
}

class _ResourceDetailsScreenState extends ConsumerState<ResourceDetailsScreen> {
  bool _isActionLoading = false;

  Future<void> _handleStopInstance(String id, String name) async {
    final confirmed = await DialogUtils.showConfirmDialog(
      context: context,
      title: 'Stop EC2 Instance?',
      message: 'Are you sure you want to stop $name ($id)? You can start it again anytime from the AWS Console.',
      confirmLabel: 'Stop Instance',
      isDanger: true,
      icon: Icons.stop_circle_outlined,
    );

    if (confirmed == true && mounted) {
      setState(() => _isActionLoading = true);
      final success = await ref.read(resourcesProvider.notifier).stopInstance(id);
      setState(() => _isActionLoading = false);

      if (!mounted) return;
      if (success) {
        Toast.showSuccess(context, 'Instance stop requested successfully.');
      } else {
        Toast.showError(context, 'Failed to stop instance.');
      }
    }
  }

  Future<void> _handleDeleteResource(String id, String resourceIdStr) async {
    final typedConfirm = await DialogUtils.showTypeToConfirmDeleteDialog(
      context: context,
      title: 'Delete Resource Permanently?',
      resourceId: resourceIdStr,
      description:
          'This action will permanently delete or release the AWS resource. This action cannot be undone.',
    );

    if (typedConfirm != null && mounted) {
      setState(() => _isActionLoading = true);
      final success = await ref.read(resourcesProvider.notifier).deleteResource(id, typedConfirm);
      setState(() => _isActionLoading = false);

      if (!mounted) return;
      if (success) {
        Toast.showSuccess(context, 'Resource removed successfully.');
        context.pop();
      } else {
        Toast.showError(context, 'Failed to delete resource.');
      }
    }
  }

  Future<void> _openAwsConsole(String service, String region, String resourceIdStr) async {
    String url = 'https://console.aws.amazon.com';
    final s = service.toUpperCase();
    final reg = region.isNotEmpty && region != 'global' ? region : 'us-east-1';

    if (s == 'EC2') {
      url = 'https://$reg.console.aws.amazon.com/ec2/home?region=$reg#Instances:instanceId=$resourceIdStr';
    } else if (s == 'EBS') {
      url = 'https://$reg.console.aws.amazon.com/ec2/home?region=$reg#Volumes:volumeId=$resourceIdStr';
    } else if (s == 'RDS') {
      url = 'https://$reg.console.aws.amazon.com/rds/home?region=$reg#database:id=$resourceIdStr';
    } else if (s == 'S3') {
      url = 'https://s3.console.aws.amazon.com/s3/buckets/$resourceIdStr';
    } else if (s == 'EIP') {
      url = 'https://$reg.console.aws.amazon.com/ec2/home?region=$reg#Addresses:';
    } else if (s == 'NAT') {
      url = 'https://$reg.console.aws.amazon.com/vpc/home?region=$reg#NatGateways:natGatewayId=$resourceIdStr';
    } else if (s == 'ELB') {
      url = 'https://$reg.console.aws.amazon.com/ec2/home?region=$reg#LoadBalancers:';
    } else if (s == 'SG') {
      url = 'https://$reg.console.aws.amazon.com/ec2/home?region=$reg#SecurityGroups:groupId=$resourceIdStr';
    }

    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        Toast.showInfo(context, 'AWS Console URL: $url');
      }
    } catch (_) {
      if (!mounted) return;
      Toast.showInfo(context, 'AWS Console URL: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final resourcesState = ref.watch(resourcesProvider);
    final resource = resourcesState.resources.firstWhere(
      (r) => r.id == widget.resourceId,
      orElse: () => resourcesState.resources.isNotEmpty
          ? resourcesState.resources.first
          : throw Exception('Resource not found'),
    );

    final meta = resource.metadata;
    final cost = resource.costInfo;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${resource.service} Details', style: AppTypography.headingMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Card
              GuardianCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GuardianBadge.service(resource.service),
                        GuardianBadge.status(resource.state),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      resource.displayName,
                      style: AppTypography.headingLarge,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            resource.resourceId,
                            style: AppTypography.code.copyWith(fontSize: 13),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primaryLight),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: resource.resourceId));
                            Toast.showSuccess(context, 'Resource ID copied');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 14),
                    _buildAttributeRow('Region', '${resource.region} (${Formatters.regionName(resource.region)})'),
                    const SizedBox(height: 10),
                    _buildAttributeRow('Type', resource.resourceType.isNotEmpty ? resource.resourceType : 'N/A'),
                    const SizedBox(height: 10),
                    _buildAttributeRow('AWS Account', resource.accountName.isNotEmpty ? '${resource.accountName} (${resource.accountNumber})' : 'Default'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Authoritative Cost & Billing Card
              Text('AWS Cost & Billing Attribution', style: AppTypography.sectionTitle),
              const SizedBox(height: 10),
              GuardianCard(
                padding: const EdgeInsets.all(18),
                backgroundColor: AppColors.surfaceElevated,
                borderColor: AppColors.primary.withValues(alpha: 0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GuardianBadge.costStatus(cost?.billingStatus ?? 'PRICING_ESTIMATE'),
                        GuardianBadge(label: cost?.costSourceDisplay ?? 'AWS Pricing API'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('October Month-to-Date', style: AppTypography.caption),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '\$${(cost != null && cost.monthToDateCost > 0 ? cost.monthToDateCost : (cost != null && cost.actualCost > 0 ? cost.actualCost : 0.0)).toStringAsFixed(2)} USD',
                                  style: AppTypography.headingLarge.copyWith(color: AppColors.primaryLight),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Oct 1–8 settled (so far)',
                                style: AppTypography.caption.copyWith(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Projected October Total', style: AppTypography.caption),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '\$${(cost != null && cost.projectedMonthlyCost > 0 ? cost.projectedMonthlyCost : (cost != null && cost.estimatedCost > 0 ? cost.estimatedCost : (resource.estimatedHourlyCost * 730.0))).toStringAsFixed(2)} USD',
                                  style: AppTypography.headingLarge.copyWith(color: AppColors.textPrimary),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Full month estimate',
                                style: AppTypography.caption.copyWith(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Daily Run Rate', style: AppTypography.caption.copyWith(fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(
                                  '\$${(cost != null && cost.dailyCost > 0 ? cost.dailyCost : ((cost?.pricingRate ?? resource.estimatedHourlyCost) * 24.0)).toStringAsFixed(2)} / day',
                                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 26, color: AppColors.border),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Hourly Rate', style: AppTypography.caption.copyWith(fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(
                                  '\$${(cost?.pricingRate ?? resource.estimatedHourlyCost).toStringAsFixed(4)} / ${cost?.pricingUnit ?? "hr"}',
                                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cost?.notes.isNotEmpty == true
                                ? cost!.notes
                                : 'Calculated from authoritative AWS on-demand pricing rates. Final AWS billing may differ.',
                            style: AppTypography.caption.copyWith(color: AppColors.textSecondary, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Risk Analysis Card (if flagged)
              if (resource.hasRisk) ...[
                Text('Guardian Risk Analysis', style: AppTypography.sectionTitle),
                const SizedBox(height: 10),
                GuardianCard(
                  padding: const EdgeInsets.all(18),
                  backgroundColor: AppColors.surfaceElevated,
                  borderColor: resource.isCritical ? AppColors.critical.withValues(alpha: 0.5) : AppColors.warning.withValues(alpha: 0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GuardianBadge.severity(resource.riskLevel),
                          const SizedBox(width: 10),
                          Text('Action Recommended', style: AppTypography.sectionTitle),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        resource.riskReason.isNotEmpty
                            ? resource.riskReason
                            : 'This resource may be idle, unattached, or forgotten and generating unnecessary AWS costs.',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 4. Service-Specific Configuration & Details
              ..._buildServiceSpecificSections(resource, meta),


              // 7. Tags Card (if present)
              if (meta['tags'] != null && meta['tags'] is Map && (meta['tags'] as Map).isNotEmpty) ...[
                Text('AWS Tags', style: AppTypography.sectionTitle),
                const SizedBox(height: 10),
                GuardianCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: (meta['tags'] as Map).entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: _buildAttributeRow(e.key.toString(), e.value.toString()),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 8. Actions
              if (resource.service == 'EC2' && resource.state.toLowerCase() == 'running') ...[
                GuardianButton(
                  label: 'Stop Instance',
                  variant: ButtonVariant.danger,
                  width: double.infinity,
                  isLoading: _isActionLoading,
                  icon: Icons.stop_circle_outlined,
                  onPressed: () => _handleStopInstance(resource.id, resource.displayName),
                ),
                const SizedBox(height: 12),
              ],

              GuardianButton(
                label: 'Delete Resource',
                variant: ButtonVariant.outlined,
                width: double.infinity,
                isLoading: _isActionLoading,
                icon: Icons.delete_outline_rounded,
                onPressed: () => _handleDeleteResource(resource.id, resource.resourceId),
              ),
              const SizedBox(height: 12),

              GuardianButton(
                label: 'Open AWS Console',
                variant: ButtonVariant.secondary,
                width: double.infinity,
                icon: Icons.open_in_new_rounded,
                onPressed: () => _openAwsConsole(resource.service, resource.region, resource.resourceId),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttributeRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value.isNotEmpty ? value : 'N/A',
            textAlign: TextAlign.end,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget? _row(String label, dynamic value, {Color? valueColor}) {
    if (value == null) return null;
    final str = value.toString().trim();
    if (str.isEmpty || str == 'N/A' || str == 'null' || str == 'None') return null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: _buildAttributeRow(label, str, valueColor: valueColor),
    );
  }

  Widget? _buildCard(String title, List<Widget?> rows) {
    final validRows = rows.whereType<Widget>().toList();
    if (validRows.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.sectionTitle),
        const SizedBox(height: 10),
        GuardianCard(
          padding: const EdgeInsets.all(16),
          child: Column(children: validRows),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  List<Widget> _buildServiceSpecificSections(ResourceModel resource, Map<String, dynamic> meta) {
    final service = resource.service.toUpperCase();
    switch (service) {
      case 'SG':
        return _buildSecurityGroupSections(resource, meta);
      case 'S3':
        return _buildS3Sections(resource, meta);
      case 'RDS':
        return _buildRdsSections(resource, meta);
      case 'EBS':
        return _buildEbsSections(resource, meta);
      case 'EIP':
        return _buildEipSections(resource, meta);
      case 'NAT':
        return _buildNatSections(resource, meta);
      case 'ELB':
        return _buildElbSections(resource, meta);
      case 'EC2':
        return _buildEc2Sections(resource, meta);
      default:
        return _buildGenericSections(resource, meta);
    }
  }

  List<Widget> _buildSecurityGroupSections(ResourceModel resource, Map<String, dynamic> meta) {
    final sections = <Widget>[];

    // 1. Security Group Configuration
    final configCard = _buildCard('Security Group Configuration', [
      _row('Group ID', meta['group_id'] ?? resource.resourceId),
      _row('Group Name', meta['group_name'] ?? resource.name),
      _row('Description', meta['description']),
      _row('VPC ID', meta['vpc_id']),
      _row('State', resource.state),
      _row('Total Inbound Rules', '${meta['inbound_rules_count'] ?? 0} rules'),
      _row('Total Outbound Rules', '${meta['outbound_rules_count'] ?? 0} rules'),
    ]);
    if (configCard != null) sections.add(configCard);

    // 2. Exposure & Risk Breakdown
    final openPortsList = meta['open_ports'] is List ? (meta['open_ports'] as List) : [];
    final openPortsStr = openPortsList.isNotEmpty
        ? openPortsList.join(', ')
        : 'None (No public open ports)';

    final exposureCard = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Public Exposure & Risk Assessment', style: AppTypography.sectionTitle),
        const SizedBox(height: 10),
        GuardianCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildAttributeRow(
                'Public Open Ports',
                openPortsStr,
                valueColor: openPortsList.isNotEmpty ? AppColors.warning : AppColors.success,
              ),
              const SizedBox(height: 12),
              _buildSecurityStatusRow('All Traffic (0.0.0.0/0)', meta['has_open_all'] == true, isCritical: true),
              const SizedBox(height: 10),
              _buildSecurityStatusRow('SSH Access (Port 22)', meta['has_open_ssh'] == true),
              const SizedBox(height: 10),
              _buildSecurityStatusRow('RDP Access (Port 3389)', meta['has_open_rdp'] == true),
              const SizedBox(height: 10),
              _buildSecurityStatusRow('Database Ports', meta['has_open_db'] == true),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
    sections.add(exposureCard);

    // 3. Inbound Rules
    final rules = meta['inbound_rules'] is List ? (meta['inbound_rules'] as List) : [];
    if (rules.isNotEmpty) {
      sections.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Inbound Firewall Rules (${rules.length})', style: AppTypography.sectionTitle),
            const SizedBox(height: 10),
            GuardianCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (int i = 0; i < rules.length; i++) ...[
                    if (i > 0) const Divider(height: 20),
                    _buildInboundRuleItem(rules[i]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    return sections;
  }

  Widget _buildSecurityStatusRow(String label, bool isRisk, {bool isCritical = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.caption),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isRisk
                ? (isCritical ? AppColors.critical.withValues(alpha: 0.15) : AppColors.warning.withValues(alpha: 0.15))
                : AppColors.success.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isRisk
                  ? (isCritical ? AppColors.critical : AppColors.warning)
                  : AppColors.success,
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isRisk ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                size: 12,
                color: isRisk
                    ? (isCritical ? AppColors.critical : AppColors.warning)
                    : AppColors.success,
              ),
              const SizedBox(width: 4),
              Text(
                isRisk ? (isCritical ? 'CRITICAL (0.0.0.0/0)' : 'OPEN TO WORLD') : 'PROTECTED',
                style: AppTypography.caption.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isRisk
                      ? (isCritical ? AppColors.critical : AppColors.warning)
                      : AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInboundRuleItem(dynamic ruleMap) {
    if (ruleMap is! Map) return const SizedBox.shrink();
    final protocol = (ruleMap['protocol']?.toString() ?? '-1').toUpperCase();
    final fromPort = ruleMap['from_port'];
    final toPort = ruleMap['to_port'];
    final isWorld = ruleMap['is_world_open'] == true;
    final ipRanges = ruleMap['ip_ranges'] is List ? (ruleMap['ip_ranges'] as List).join(', ') : '';
    final ipv6Ranges = ruleMap['ipv6_ranges'] is List ? (ruleMap['ipv6_ranges'] as List).join(', ') : '';

    final portLabel = protocol == '-1'
        ? 'All Traffic'
        : (fromPort != null && toPort != null)
            ? (fromPort == toPort ? 'Port $fromPort' : 'Ports $fromPort-$toPort')
            : 'All Ports';

    final cidrDisplay = [ipRanges, ipv6Ranges].where((s) => s.isNotEmpty).join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    protocol == '-1' ? 'ALL' : protocol,
                    style: AppTypography.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  portLabel,
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isWorld ? AppColors.critical.withValues(alpha: 0.15) : AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isWorld ? '0.0.0.0/0 (PUBLIC)' : 'RESTRICTED',
                style: AppTypography.caption.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isWorld ? AppColors.critical : AppColors.success,
                ),
              ),
            ),
          ],
        ),
        if (cidrDisplay.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Source: $cidrDisplay',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildEc2Sections(ResourceModel resource, Map<String, dynamic> meta) {
    final sections = <Widget>[];

    final configCard = _buildCard('Instance Configuration', [
      _row('Instance ID', meta['instance_id'] ?? resource.resourceId),
      _row('Instance Type', resource.resourceType),
      _row('State', resource.state),
      _row('Availability Zone', meta['availability_zone']),
      _row('Launch Time', meta['launch_time']),
      _row('Platform / OS', meta['platform']),
      _row('Architecture', meta['architecture']),
      _row('Tenancy', meta['tenancy']),
      _row('Key Pair', meta['key_pair_name']),
      _row('AMI ID', meta['ami_id']),
      _row('IAM Role Profile', meta['iam_instance_profile']),
      _row('Monitoring', meta['monitoring_status']),
    ]);
    if (configCard != null) sections.add(configCard);

    final netCard = _buildCard('Network Configuration', [
      _row('Public IPv4', meta['public_ip']),
      _row('Private IPv4', meta['private_ip']),
      _row('Public DNS', meta['public_dns']),
      _row('Private DNS', meta['private_dns']),
      _row('VPC ID', meta['vpc_id']),
      _row('Subnet ID', meta['subnet_id']),
      _row('Security Groups', meta['security_groups'] is List ? (meta['security_groups'] as List).join(', ') : meta['security_groups']?.toString()),
    ]);
    if (netCard != null) sections.add(netCard);

    final rootDev = meta['root_device'];
    final ebsVols = meta['ebs_volume_ids'] is List ? (meta['ebs_volume_ids'] as List) : [];
    if (rootDev != null || ebsVols.isNotEmpty) {
      final storageCard = _buildCard('Storage Configuration', [
        _row('Root Device', rootDev != null ? '$rootDev (${meta['root_device_type'] ?? "ebs"})' : null),
        _row('Attached Volumes', ebsVols.isNotEmpty ? ebsVols.join(', ') : null),
      ]);
      if (storageCard != null) sections.add(storageCard);
    }

    return sections;
  }

  List<Widget> _buildS3Sections(ResourceModel resource, Map<String, dynamic> meta) {
    final sections = <Widget>[];

    final configCard = _buildCard('Bucket Configuration', [
      _row('Bucket Name', meta['bucket_name'] ?? resource.resourceId),
      _row('Region', meta['region'] ?? resource.region),
      _row('Created Date', meta['creation_date']),
      _row('Storage Class', meta['storage_class'] ?? 'Standard'),
      _row('Versioning', meta['versioning'] ?? 'Disabled'),
      _row('Encryption', meta['encryption'] ?? 'None'),
    ]);
    if (configCard != null) sections.add(configCard);

    final metricsCard = _buildCard('Storage Metrics', [
      _row('Storage Size', meta['storage_size_formatted']),
      _row('Object Count', meta['object_count'] != null ? '${meta['object_count']} objects' : null),
    ]);
    if (metricsCard != null) sections.add(metricsCard);

    final isPublic = meta['is_public'] == true;
    final accessCard = _buildCard('Bucket Access & Security', [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: _buildAttributeRow(
          'Public Access',
          isPublic ? 'Public Access Detected (Warning)' : 'Blocked (Block Public Access ON)',
          valueColor: isPublic ? AppColors.critical : AppColors.success,
        ),
      ),
    ]);
    if (accessCard != null) sections.add(accessCard);

    return sections;
  }

  List<Widget> _buildRdsSections(ResourceModel resource, Map<String, dynamic> meta) {
    final sections = <Widget>[];

    final engine = meta['engine']?.toString() ?? '';
    final engineVer = meta['engine_version']?.toString() ?? '';
    final engineFull = [engine, engineVer].where((s) => s.isNotEmpty).join(' ');

    final configCard = _buildCard('Database Configuration', [
      _row('DB Identifier', meta['db_identifier'] ?? resource.resourceId),
      _row('Engine', engineFull.isNotEmpty ? engineFull : null),
      _row('Instance Class', meta['db_instance_class']),
      _row('Deployment', meta['multi_az'] == true ? 'Multi-AZ (High Availability)' : 'Single-AZ'),
      _row('State', resource.state),
      _row('Availability Zone', meta['availability_zone']),
      _row('Created Time', meta['instance_create_time']),
      _row('Backup Retention', meta['backup_retention_days'] != null ? '${meta['backup_retention_days']} days' : null),
      _row('Auto Minor Upgrade', meta['auto_minor_version_upgrade'] == true ? 'Enabled' : 'Disabled'),
    ]);
    if (configCard != null) sections.add(configCard);

    final endpoint = meta['endpoint']?.toString() ?? '';
    final port = meta['port']?.toString() ?? '';
    final endpointFull = endpoint.isNotEmpty ? (port.isNotEmpty ? '$endpoint:$port' : endpoint) : null;

    final isPublic = meta['publicly_accessible'] == true;
    final netCard = _buildCard('Connectivity & Network', [
      _row('Endpoint & Port', endpointFull),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: _buildAttributeRow(
          'Public Accessibility',
          isPublic ? 'Publicly Accessible (Warning)' : 'Private Only',
          valueColor: isPublic ? AppColors.warning : AppColors.success,
        ),
      ),
      _row('VPC ID', meta['vpc_id']),
      _row('DB Subnet Group', meta['db_subnet_group']),
      _row('Security Groups', meta['security_groups'] is List ? (meta['security_groups'] as List).join(', ') : meta['security_groups']?.toString()),
    ]);
    if (netCard != null) sections.add(netCard);

    final storageGb = meta['storage_gb'];
    final storageType = meta['storage_type'] ?? 'gp3';
    final iops = meta['iops'];
    final storageCard = _buildCard('Storage Configuration', [
      _row('Allocated Storage', storageGb != null ? '$storageGb GiB ($storageType)' : null),
      _row('IOPS', iops != null && iops > 0 ? '$iops IOPS' : null),
    ]);
    if (storageCard != null) sections.add(storageCard);

    return sections;
  }

  List<Widget> _buildEbsSections(ResourceModel resource, Map<String, dynamic> meta) {
    final sections = <Widget>[];

    final sizeGb = meta['size_gb'];
    final volType = meta['volume_type'] ?? 'gp3';
    final iops = meta['iops'];
    final throughput = meta['throughput_mbs'];

    final configCard = _buildCard('Volume Configuration', [
      _row('Volume ID', meta['volume_id'] ?? resource.resourceId),
      _row('Volume Name', meta['volume_name']),
      _row('Volume Type', volType),
      _row('Size', sizeGb != null ? '$sizeGb GiB' : null),
      _row('Performance', (iops != null || throughput != null) ? '${iops ?? 3000} IOPS / ${throughput ?? 125} MB/s' : null),
      _row('Availability Zone', meta['availability_zone']),
      _row('State', resource.state),
      _row('Created Time', meta['create_time']),
    ]);
    if (configCard != null) sections.add(configCard);

    final isAttached = meta['is_attached'] == true;
    final attachCard = _buildCard('Attachment Status', [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: _buildAttributeRow(
          'Attachment',
          isAttached ? 'Attached' : 'Unattached (Idle / Incurring Cost)',
          valueColor: isAttached ? AppColors.success : AppColors.warning,
        ),
      ),
      _row('Attached Instance', meta['attached_instance_id']),
      _row('Mount Device', meta['attached_device']),
      _row('Attached Time', meta['attach_time']),
    ]);
    if (attachCard != null) sections.add(attachCard);

    final enc = meta['encrypted'] == true;
    final encCard = _buildCard('Encryption & Snapshots', [
      _row('Encryption', enc ? 'Encrypted (${meta['kms_key_id'] ?? "KMS"})' : 'Disabled'),
      _row('Snapshot ID', meta['snapshot_id']),
    ]);
    if (encCard != null) sections.add(encCard);

    return sections;
  }

  List<Widget> _buildEipSections(ResourceModel resource, Map<String, dynamic> meta) {
    final sections = <Widget>[];

    final isAssociated = meta['is_associated'] == true;
    final card = _buildCard('Elastic IP Configuration', [
      _row('Public IPv4', meta['public_ip'] ?? resource.name),
      _row('Allocation ID', meta['allocation_id'] ?? resource.resourceId),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: _buildAttributeRow(
          'Association State',
          isAssociated ? 'Associated' : 'Unassociated (Idle Cost Incurred)',
          valueColor: isAssociated ? AppColors.success : AppColors.critical,
        ),
      ),
      _row('Associated Resource', meta['associated_resource']),
      _row('Private IPv4', meta['private_ip']),
      _row('Network Interface ID', meta['network_interface_id']),
      _row('Domain / Scope', meta['domain']),
      _row('IPv4 Pool', meta['public_ipv4_pool']),
    ]);
    if (card != null) sections.add(card);

    return sections;
  }

  List<Widget> _buildNatSections(ResourceModel resource, Map<String, dynamic> meta) {
    final sections = <Widget>[];

    final configCard = _buildCard('NAT Gateway Configuration', [
      _row('NAT Gateway ID', meta['nat_gateway_id'] ?? resource.resourceId),
      _row('State', resource.state),
      _row('Connectivity Type', meta['connectivity_type']),
      _row('Created Time', meta['create_time']),
    ]);
    if (configCard != null) sections.add(configCard);

    final netCard = _buildCard('Network & Elastic IP', [
      _row('Primary Public IP', meta['primary_public_ip']),
      _row('Primary Private IP', meta['primary_private_ip']),
      _row('Elastic IP Allocation', meta['elastic_ip_allocation']),
      _row('VPC ID', meta['vpc_id']),
      _row('Subnet ID', meta['subnet_id']),
    ]);
    if (netCard != null) sections.add(netCard);

    return sections;
  }

  List<Widget> _buildElbSections(ResourceModel resource, Map<String, dynamic> meta) {
    final sections = <Widget>[];

    final configCard = _buildCard('Load Balancer Configuration', [
      _row('Load Balancer Name', meta['load_balancer_name'] ?? resource.resourceId),
      _row('Type', meta['type']?.toString().toUpperCase()),
      _row('Scheme', meta['scheme']),
      _row('DNS Name', meta['dns_name']),
      _row('State', resource.state),
      _row('Registered Targets', meta['target_count'] != null ? '${meta['target_count']} targets' : null),
    ]);
    if (configCard != null) sections.add(configCard);

    final netCard = _buildCard('Network & Security', [
      _row('VPC ID', meta['vpc_id']),
      _row('Availability Zones', meta['availability_zones'] is List ? (meta['availability_zones'] as List).join(', ') : meta['availability_zones']?.toString()),
      _row('Security Groups', meta['security_groups'] is List ? (meta['security_groups'] as List).join(', ') : meta['security_groups']?.toString()),
    ]);
    if (netCard != null) sections.add(netCard);

    return sections;
  }

  List<Widget> _buildGenericSections(ResourceModel resource, Map<String, dynamic> meta) {
    final rows = <Widget?>[];
    rows.add(_row('Resource ID', resource.resourceId));
    rows.add(_row('Service', resource.service));
    rows.add(_row('State', resource.state));
    rows.add(_row('Region', resource.region));

    meta.forEach((key, val) {
      if (key == 'tags' || key == 'pricing_rate' || key == 'pricing_unit' || key == 'cost_source' || key == 'billing_status' || key == 'inbound_rules') {
        return;
      }
      final prettyKey = key.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
      rows.add(_row(prettyKey, val));
    });

    final card = _buildCard('${resource.service} Configuration', rows);
    return card != null ? [card] : [];
  }
}
