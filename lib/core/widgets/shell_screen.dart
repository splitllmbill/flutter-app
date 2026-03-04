import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_theme.dart';

/// App shell with responsive navigation (side nav on desktop, bottom nav on mobile).
class ShellScreen extends StatelessWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/event') || location.startsWith('/create-event')) {
      return 1;
    }
    if (location.startsWith('/friend') || location.startsWith('/add-friend')) {
      return 2;
    }
    if (location.startsWith('/personal-expenses')) return 3;
    if (location.startsWith('/user-account')) return 4;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/events');
      case 2:
        context.go('/friends');
      case 3:
        context.go('/personal-expenses');
      case 4:
        context.go('/user-account');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);
    final isWideScreen = MediaQuery.of(context).size.width >= 800;

    if (isWideScreen) {
      return Scaffold(
        body: Row(
          children: [
            _SideNavBar(
              selectedIndex: selectedIndex,
              onItemTapped: (index) => _onItemTapped(context, index),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: selectedIndex,
        onItemTapped: (index) => _onItemTapped(context, index),
      ),
    );
  }
}

class _SideNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const _SideNavBar({
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onItemTapped,
      backgroundColor: AppTheme.surfaceColor,
      indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'SplitLLM',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      extended: MediaQuery.of(context).size.width >= 1200,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.event_outlined),
          selectedIcon: Icon(Icons.event_rounded),
          label: Text('Events'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people_rounded),
          label: Text('Friends'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet_rounded),
          label: Text('Expenses'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person_rounded),
          label: Text('Account'),
        ),
      ],
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const _BottomNavBar({
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onItemTapped,
        backgroundColor: Colors.transparent,
        indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.2),
        height: 65,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event_rounded),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Friends',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
