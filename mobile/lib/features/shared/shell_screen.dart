import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../dashboard/screens/dashboard_screen.dart';
import '../resources/screens/resources_screen.dart';
import '../alerts/screens/alerts_screen.dart';
import '../aws_accounts/screens/aws_accounts_screen.dart';
import '../more/screens/more_screen.dart';

class ShellScreen extends StatefulWidget {
  final Widget? child;
  const ShellScreen({super.key, this.child});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _KeepAlivePage(child: DashboardScreen()),
    _KeepAlivePage(child: ResourcesScreen()),
    _KeepAlivePage(child: AlertsScreen()),
    _KeepAlivePage(child: AWSAccountsScreen()),
    _KeepAlivePage(child: MoreScreen()),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final index = _calculateSelectedIndex(context);
    if (index != _currentIndex) {
      _currentIndex = index;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(index);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(index);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/resources')) return 1;
    if (location.startsWith('/alerts')) return 2;
    if (location.startsWith('/aws-accounts') || location.startsWith('/accounts')) return 3;
    if (location.startsWith('/more')) return 4;
    return 0;
  }

  void _syncLocationForIndex(int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/resources');
        break;
      case 2:
        context.go('/alerts');
        break;
      case 3:
        context.go('/aws-accounts');
        break;
      case 4:
        context.go('/more');
        break;
    }
  }

  void _onPageChanged(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
    _syncLocationForIndex(index);
  }

  void _onItemTapped(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
    );
    _syncLocationForIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primaryLight,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: AppTypography.label.copyWith(fontSize: 10.5, fontWeight: FontWeight.w700),
          unselectedLabelStyle: AppTypography.label.copyWith(fontSize: 10, fontWeight: FontWeight.w500),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined, size: 22),
              activeIcon: Icon(Icons.dashboard_rounded, size: 22),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.layers_outlined, size: 22),
              activeIcon: Icon(Icons.layers_rounded, size: 22),
              label: 'Resources',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.warning_amber_rounded, size: 22),
              activeIcon: Icon(Icons.warning_rounded, size: 22),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.cloud_outlined, size: 22),
              activeIcon: Icon(Icons.cloud_done_rounded, size: 22),
              label: 'Accounts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined, size: 22),
              activeIcon: Icon(Icons.grid_view_rounded, size: 22),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  final Widget child;
  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
