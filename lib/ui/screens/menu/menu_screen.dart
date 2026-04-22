import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = [
      _MenuItem(icon: Icons.calendar_today, label: 'Attendance', route: '/attendance'),
      _MenuItem(icon: Icons.beach_access, label: 'Leave', route: '/leave'),
      _MenuItem(icon: Icons.payment, label: 'Payslips', route: '/payslips'),
      _MenuItem(icon: Icons.folder, label: 'Documents', route: '/menu/documents'),
      _MenuItem(icon: Icons.receipt_long, label: 'Expenses', route: '/menu/expenses'),
      _MenuItem(icon: Icons.school, label: 'Training', route: '/menu/training'),
      _MenuItem(icon: Icons.favorite, label: 'Benefits', route: '/menu/benefits'),
      _MenuItem(icon: Icons.work_outline, label: 'Recruitment', route: '/menu/recruitment'),
      _MenuItem(icon: Icons.person_remove, label: 'Offboarding', route: '/menu/offboarding'),
      _MenuItem(icon: Icons.support_agent, label: 'Support', route: '/support'),
      _MenuItem(icon: Icons.notifications, label: 'Notifications', route: '/notifications'),
    ];

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: modules.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = modules[index];
          return ListTile(
            leading: Icon(item.icon, color: theme.colorScheme.primary),
            title: Text(item.label),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () => context.push(item.route),
          );
        },
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String route;
  _MenuItem({required this.icon, required this.label, required this.route});
}
