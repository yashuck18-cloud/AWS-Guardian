import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/guardian_card.dart';
import '../../../shared/widgets/guardian_badge.dart';
import '../../../shared/widgets/guardian_text_field.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/aws_region_picker_modal.dart';
import '../../../shared/models/aws_account_model.dart';
import '../../aws_accounts/providers/aws_accounts_provider.dart';
import '../providers/resources_provider.dart';

class ResourcesScreen extends ConsumerStatefulWidget {
  const ResourcesScreen({super.key});

  @override
  ConsumerState<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends ConsumerState<ResourcesScreen> {
  final _searchController = TextEditingController();
  final List<String> _services = ['ALL', 'EC2', 'EBS', 'SG', 'RDS', 'S3', 'ELB', 'EIP', 'NAT'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selected = ref.read(awsAccountsProvider).selectedAccount;
      if (selected != null) {
        final reg = (selected.enabledRegions.isNotEmpty && selected.enabledRegions.length == 1)
            ? selected.enabledRegions.first
            : 'all';
        ref.read(resourcesProvider.notifier).setAccount(selected.id, forceReload: true, region: reg);
      } else {
        ref.read(resourcesProvider.notifier).fetchResources(forceReload: true);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    final currentFilter = ref.read(resourcesProvider).filter;
    String selectedRisk = currentFilter.risk;
    String selectedState = currentFilter.state;
    String selectedRegion = currentFilter.region;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Filter Resources', style: AppTypography.headingMedium),
                        TextButton(
                          onPressed: () {
                            ref.read(resourcesProvider.notifier).setFilter(
                                  ResourcesFilter(service: currentFilter.service, search: currentFilter.search),
                                );
                            Navigator.of(ctx).pop();
                          },
                          child: Text('Reset', style: AppTypography.bodyMedium.copyWith(color: AppColors.primaryLight)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('AWS Region', style: AppTypography.sectionTitle),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...[
                          {'key': 'all', 'label': 'All Regions'},
                          {'key': 'ap-south-1', 'label': 'Mumbai (ap-south-1)'},
                          {'key': 'us-east-1', 'label': 'N. Virginia (us-east-1)'},
                          {'key': 'us-west-2', 'label': 'Oregon (us-west-2)'},
                          {'key': 'eu-west-1', 'label': 'Ireland (eu-west-1)'},
                        ].map((reg) {
                          final isSelected = selectedRegion.toLowerCase() == reg['key']!.toLowerCase();
                          return ChoiceChip(
                            label: Text(reg['label']!),
                            selected: isSelected,
                            selectedColor: const Color(0xFF00A4E4),
                            backgroundColor: AppColors.surface,
                            labelStyle: AppTypography.label.copyWith(
                              color: isSelected ? Colors.black : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (val) {
                              setSheetState(() => selectedRegion = reg['key']!);
                            },
                          );
                        }),
                        ActionChip(
                          avatar: const Icon(Icons.public_rounded, size: 16, color: Color(0xFF00A4E4)),
                          label: Text(
                            selectedRegion != 'all' &&
                                    !['ap-south-1', 'us-east-1', 'us-west-2', 'eu-west-1']
                                        .contains(selectedRegion.toLowerCase())
                                ? Formatters.regionName(selectedRegion)
                                : 'All AWS Regions...',
                            style: TextStyle(
                              color: selectedRegion != 'all' &&
                                      !['ap-south-1', 'us-east-1', 'us-west-2', 'eu-west-1']
                                          .contains(selectedRegion.toLowerCase())
                                  ? const Color(0xFF00A4E4)
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: AppColors.surface,
                          onPressed: () {
                            AwsRegionPickerModal.show(
                              context,
                              currentRegion: selectedRegion,
                              onRegionSelected: (code) {
                                setSheetState(() => selectedRegion = code);
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Risk Severity', style: AppTypography.sectionTitle),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['ALL', 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW', 'NONE'].map((risk) {
                        final isSelected = selectedRisk == risk;
                        return ChoiceChip(
                          label: Text(risk),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          labelStyle: AppTypography.label.copyWith(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                          onSelected: (val) {
                            setSheetState(() => selectedRisk = risk);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Text('State', style: AppTypography.sectionTitle),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['all', 'running', 'stopped', 'available', 'active'].map((st) {
                        final isSelected = selectedState == st;
                        return ChoiceChip(
                          label: Text(st.toUpperCase()),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          labelStyle: AppTypography.label.copyWith(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                          onSelected: (val) {
                            setSheetState(() => selectedState = st);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(resourcesProvider.notifier).setFilter(
                                currentFilter.copyWith(
                                  risk: selectedRisk,
                                  state: selectedState,
                                  region: selectedRegion,
                                ),
                              );
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Apply Filters'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final resourcesState = ref.watch(resourcesProvider);
    final selectedAccount = ref.watch(awsAccountsProvider.select((s) => s.selectedAccount));
    final currentService = resourcesState.filter.service;

    // Reactively switch resources whenever the user changes selected account or its enabled regions
    ref.listen<AWSAccountModel?>(
      awsAccountsProvider.select((s) => s.selectedAccount),
      (prev, next) {
        if (next?.id != prev?.id ||
            next?.enabledRegions.join(',') != prev?.enabledRegions.join(',')) {
          final reg = (next != null && next.enabledRegions.isNotEmpty && next.enabledRegions.length == 1)
              ? next.enabledRegions.first
              : 'all';
          ref.read(resourcesProvider.notifier).setAccount(next?.id, forceReload: true, region: reg);
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Resources', style: AppTypography.headingMedium),
            if (selectedAccount != null)
              Text(
                '${selectedAccount.name} • ${Formatters.maskAccountId(selectedAccount.accountId)}',
                style: AppTypography.caption.copyWith(color: AppColors.primaryLight, fontSize: 11),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: GuardianTextField(
                controller: _searchController,
                hintText: 'Search by name, ID, region...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(resourcesProvider.notifier).updateSearch('');
                        },
                      )
                    : null,
                onChanged: (val) {
                  ref.read(resourcesProvider.notifier).updateSearch(val);
                },
              ),
            ),

            // Service Filter Horizontal Chips
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _services.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final service = _services[index];
                  final isSelected = currentService == service;

                  return GestureDetector(
                    onTap: () {
                      ref.read(resourcesProvider.notifier).updateServiceFilter(service);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryLight : AppColors.border,
                        ),
                      ),
                      child: Text(
                        service,
                        style: AppTypography.label.copyWith(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Subtle Background Refresh Indicator
            if (resourcesState.isRefreshing)
              const LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
              ),

            // Resources List
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryLight,
                backgroundColor: AppColors.surfaceElevated,
                onRefresh: () => ref.read(resourcesProvider.notifier).fetchResources(forceReload: true),
                child: resourcesState.isLoading && resourcesState.resources.isEmpty
                    ? const ListSkeletonLoader(count: 5)
                    : resourcesState.resources.isEmpty
                        ? const EmptyState(
                            icon: Icons.inventory_2_outlined,
                            title: 'No resources found',
                            description: 'Run a scan after connecting AWS or clear your search filters.',
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.all(16),
                            itemCount: resourcesState.resources.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final resource = resourcesState.resources[index];
                              return GuardianCard(
                                onTap: () => context.push('/resources/${resource.id}'),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        GuardianBadge.service(resource.service),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            resource.displayName,
                                            style: AppTypography.sectionTitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (resource.hasRisk)
                                          GuardianBadge.severity(resource.riskLevel),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      resource.resourceId,
                                      style: AppTypography.code.copyWith(fontSize: 12),
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.public_rounded, size: 14, color: AppColors.textMuted),
                                            const SizedBox(width: 4),
                                            Text(
                                              Formatters.regionName(resource.region),
                                              style: AppTypography.caption,
                                            ),
                                          ],
                                        ),
                                        GuardianBadge.status(resource.state),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
