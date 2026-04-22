import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:people_desk/nav.dart';
import 'package:people_desk/state/auth_controller.dart';
import 'package:people_desk/state/notifications_controller.dart';
import 'package:people_desk/state/theme_controller.dart';
import 'package:people_desk/theme.dart';

class TabShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const TabShell({super.key, required this.navigationShell});

  @override
  State<TabShell> createState() => _TabShellState();
}

class _TabShellState extends State<TabShell> {
  void _onTap(int index) {
    widget.navigationShell.goBranch(index, initialLocation: index == widget.navigationShell.currentIndex);
  }

  void _navigateTo(String route) {
    Navigator.pop(context); // Close drawer
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unread = context.watch<NotificationsController>().unreadCount;
    final currentIndex = widget.navigationShell.currentIndex;

    // Map current index to main tabs: 0=Home, 1=Menu, 2=Profile
    int _mapToMainIndex(int currentIdx) {
      if (currentIdx == 0) return 0; // Home
      if (currentIdx == 1) return 1; // Menu
      if (currentIdx == 2) return 2; // Profile
      return 0;
    }

    final mainIndex = _mapToMainIndex(currentIndex);

    // Skip showing appBar for menu sub-routes to avoid double AppBars
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    final isSubRoute = currentRoute.contains('/menu/');

    return Scaffold(
      appBar: isSubRoute ? null : AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('PeopleDesk'),
        actions: [
          // Theme toggle button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark 
                    ? Icons.light_mode_rounded 
                    : Icons.dark_mode_rounded,
                color: cs.onSurface,
              ),
              onPressed: () => context.read<ThemeController>().toggleTheme(),
              tooltip: 'Toggle theme',
            ),
          ),
          // Notifications icon with badge
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_rounded, color: cs.onSurface),
                  onPressed: () => context.go(AppRoutes.notifications),
                ),
                if (unread > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: cs.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        style: context.textStyles.labelSmall?.withColor(cs.onError),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Profile button
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: CircleAvatar(
                backgroundColor: cs.primary,
                child: Icon(Icons.person_rounded, color: cs.onPrimary, size: 20),
              ),
              onPressed: () => context.go(AppRoutes.profile),
            ),
          ),
        ],
      ),
      drawer: isSubRoute ? null : Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: cs.primary),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: cs.onPrimary,
                    radius: 32,
                    child: Icon(Icons.person_rounded, color: cs.primary, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Employee',
                    style: context.textStyles.titleMedium?.withColor(cs.onPrimary),
                  ),
                  Text(
                    'emp@company.com',
                    style: context.textStyles.bodySmall?.withColor(cs.onPrimary.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.receipt_long_rounded, color: cs.primary),
              title: const Text('Payslips'),
              onTap: () => _navigateTo(AppRoutes.payslips),
            ),
            ListTile(
              leading: Icon(Icons.support_agent_rounded, color: cs.primary),
              title: const Text('Support'),
              onTap: () => _navigateTo(AppRoutes.support),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout_rounded, color: cs.error),
              title: Text('Logout', style: TextStyle(color: cs.error)),
              onTap: () async {
                Navigator.pop(context);
                await context.read<AuthController>().logout();
                if (context.mounted) context.go(AppRoutes.login);
              },
            ),
          ],
        ),
      ),
      body: widget.navigationShell,
      extendBody: false,
      bottomNavigationBar: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(
              top: BorderSide(
                color: cs.outline.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Menu (Left)
                _bottomNavItem(
                  context,
                  Icons.menu_rounded,
                  'Menu',
                  isSelected: mainIndex == 1,
                  onTap: () => _onTap(1),
                ),
                // Home (Center)
                _bottomNavItem(
                  context,
                  Icons.home_rounded,
                  'Home',
                  isSelected: mainIndex == 0,
                  onTap: () => _onTap(0),
                ),
                // Profile (Right)
                _bottomNavItem(
                  context,
                  Icons.person_rounded,
                  'Profile',
                  isSelected: mainIndex == 2,
                  onTap: () => _onTap(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomNavItem(
    BuildContext context,
    IconData icon,
    String label, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final color = isSelected ? cs.primary : cs.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: context.textStyles.labelSmall?.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
