import 'package:flutter/material.dart';
import '../../core/constants/aws_regions.dart';

class AwsRegionPickerModal extends StatefulWidget {
  final String currentRegion;
  final ValueChanged<String> onRegionSelected;

  const AwsRegionPickerModal({
    super.key,
    required this.currentRegion,
    required this.onRegionSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required String currentRegion,
    required ValueChanged<String> onRegionSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131924),
      barrierColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AwsRegionPickerModal(
        currentRegion: currentRegion,
        onRegionSelected: onRegionSelected,
      ),
    );
  }

  @override
  State<AwsRegionPickerModal> createState() => _AwsRegionPickerModalState();
}

class _AwsRegionPickerModalState extends State<AwsRegionPickerModal> {
  String _searchQuery = '';
  int _selectedTab = 0; // 0 = Regions, 1 = Local Zones
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentCode = widget.currentRegion.trim().toLowerCase();
    final maxHeight = MediaQuery.of(context).size.height * 0.82;

    // Filter groups based on search query
    final filteredGroups = AwsRegions.groups.map((group) {
      if (_searchQuery.isEmpty) return group;
      final query = _searchQuery.toLowerCase();
      final matching = group.regions.where((r) {
        return r.name.toLowerCase().contains(query) ||
            r.code.toLowerCase().contains(query) ||
            group.groupName.toLowerCase().contains(query);
      }).toList();
      return AwsRegionGroup(groupName: group.groupName, regions: matching);
    }).where((group) => group.regions.isNotEmpty).toList();

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Color(0xFF131924),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // AWS Console Style Pills: Regions | Local Zones
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF334155), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0 ? const Color(0xFF00A4E4) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Regions',
                            style: TextStyle(
                              color: _selectedTab == 0 ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1 ? const Color(0xFF00A4E4) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Local Zones',
                            style: TextStyle(
                              color: _selectedTab == 1 ? Colors.black : const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search AWS regions by city or code...',
                hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8), size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF0F172A),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1E293B)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1E293B)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF00A4E4)),
                ),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.trim());
              },
            ),
          ),

          const Divider(color: Color(0xFF1E293B), height: 16),

          // Main Content
          Expanded(
            child: _selectedTab == 1
                ? _buildLocalZonesTab()
                : _buildRegionsList(filteredGroups, currentCode),
          ),

          // Bottom Footer matching AWS console
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0B101B),
              border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'There are 16 Regions that are not enabled for this account',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.dotted,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        widget.onRegionSelected('all');
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Enable All Regions',
                        style: TextStyle(
                          color: Color(0xFF00A4E4),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Text(
                      '  |  ',
                      style: TextStyle(color: Color(0xFF475569), fontSize: 12),
                    ),
                    const Text(
                      'Manage local zones',
                      style: TextStyle(
                        color: Color(0xFF00A4E4),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionsList(List<AwsRegionGroup> groups, String currentCode) {
    if (groups.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No matching AWS regions found',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: groups.length,
      itemBuilder: (context, groupIndex) {
        final group = groups[groupIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Header (e.g. United States, Asia Pacific)
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 6),
              child: Text(
                group.groupName,
                style: const TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const Divider(color: Color(0xFF1E293B), height: 1),

            // Region Item Rows
            ...group.regions.map((region) {
              final isSelected = currentCode == region.code.toLowerCase();
              return InkWell(
                onTap: () {
                  widget.onRegionSelected(region.code);
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF00A4E4).withValues(alpha: 0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // City / Region Name
                      Expanded(
                        child: Text(
                          region.name,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF00A4E4) : const Color(0xFFF1F5F9),
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),

                      // Code (e.g. ap-south-1, us-east-1)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            region.code,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF00A4E4) : const Color(0xFF94A3B8),
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontFamily: 'monospace',
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF00A4E4),
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildLocalZonesTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF00A4E4), size: 20),
                  SizedBox(width: 10),
                  Text(
                    'AWS Local Zones',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'AWS Local Zones place compute, storage, and database services closer to large population and industry centers. Parent region monitoring in AWS Guardian automatically covers resources in attached Local Zones.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A4E4),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Back to Regions', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  setState(() => _selectedTab = 0);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
