class AwsRegionItem {
  final String name;
  final String code;
  final String group;

  const AwsRegionItem({
    required this.name,
    required this.code,
    required this.group,
  });
}

class AwsRegionGroup {
  final String groupName;
  final List<AwsRegionItem> regions;

  const AwsRegionGroup({
    required this.groupName,
    required this.regions,
  });
}

class AwsRegions {
  static const List<AwsRegionGroup> groups = [
    AwsRegionGroup(
      groupName: 'United States',
      regions: [
        AwsRegionItem(name: 'N. Virginia', code: 'us-east-1', group: 'United States'),
        AwsRegionItem(name: 'Ohio', code: 'us-east-2', group: 'United States'),
        AwsRegionItem(name: 'N. California', code: 'us-west-1', group: 'United States'),
        AwsRegionItem(name: 'Oregon', code: 'us-west-2', group: 'United States'),
      ],
    ),
    AwsRegionGroup(
      groupName: 'Asia Pacific',
      regions: [
        AwsRegionItem(name: 'Hyderabad', code: 'ap-south-2', group: 'Asia Pacific'),
        AwsRegionItem(name: 'Mumbai', code: 'ap-south-1', group: 'Asia Pacific'),
        AwsRegionItem(name: 'Osaka', code: 'ap-northeast-3', group: 'Asia Pacific'),
        AwsRegionItem(name: 'Seoul', code: 'ap-northeast-2', group: 'Asia Pacific'),
        AwsRegionItem(name: 'Singapore', code: 'ap-southeast-1', group: 'Asia Pacific'),
        AwsRegionItem(name: 'Sydney', code: 'ap-southeast-2', group: 'Asia Pacific'),
        AwsRegionItem(name: 'Tokyo', code: 'ap-northeast-1', group: 'Asia Pacific'),
      ],
    ),
    AwsRegionGroup(
      groupName: 'Canada',
      regions: [
        AwsRegionItem(name: 'Central', code: 'ca-central-1', group: 'Canada'),
      ],
    ),
    AwsRegionGroup(
      groupName: 'Europe',
      regions: [
        AwsRegionItem(name: 'Frankfurt', code: 'eu-central-1', group: 'Europe'),
        AwsRegionItem(name: 'Ireland', code: 'eu-west-1', group: 'Europe'),
        AwsRegionItem(name: 'London', code: 'eu-west-2', group: 'Europe'),
        AwsRegionItem(name: 'Paris', code: 'eu-west-3', group: 'Europe'),
        AwsRegionItem(name: 'Stockholm', code: 'eu-north-1', group: 'Europe'),
      ],
    ),
    AwsRegionGroup(
      groupName: 'South America',
      regions: [
        AwsRegionItem(name: 'São Paulo', code: 'sa-east-1', group: 'South America'),
      ],
    ),
    AwsRegionGroup(
      groupName: 'Global',
      regions: [
        AwsRegionItem(name: 'All Supported Regions', code: 'all', group: 'Global'),
      ],
    ),
  ];

  static List<AwsRegionItem> get allRegions {
    return groups.expand((g) => g.regions).toList();
  }

  static String getName(String code) {
    final lower = code.toLowerCase().trim();
    for (final group in groups) {
      for (final r in group.regions) {
        if (r.code.toLowerCase() == lower) {
          return r.name;
        }
      }
    }
    return code;
  }

  static String getFormattedLabel(String code) {
    final lower = code.toLowerCase().trim();
    if (lower == 'all') return 'All Supported Regions';
    final name = getName(lower);
    if (name != lower) {
      return '$name ($lower)';
    }
    return lower;
  }
}
