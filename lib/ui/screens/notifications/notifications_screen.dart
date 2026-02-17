import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:people_desk/state/notifications_controller.dart';
import 'package:people_desk/theme.dart';
import 'package:people_desk/ui/utils/formatters.dart';
import 'package:people_desk/ui/widgets/app_empty_state.dart';
import 'package:people_desk/ui/widgets/app_error_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _bootstrapped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<NotificationsController>().refresh());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ctrl = context.watch<NotificationsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          IconButton(onPressed: ctrl.refresh, icon: Icon(Icons.refresh_rounded, color: cs.onSurface)),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: ListView(
        padding: AppSpacing.paddingMd,
        children: [
          if (ctrl.error != null) ...[
            AppErrorState(title: 'Notifications', message: ctrl.error!),
            const SizedBox(height: AppSpacing.md),
          ],
          if (ctrl.items.isEmpty && ctrl.isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: CircularProgressIndicator()))
          else if (ctrl.items.isEmpty)
            const AppEmptyState(title: 'No alerts', message: 'You’re all caught up.')
          else
            ...ctrl.items.map(
              (n) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  onTap: () => ctrl.markRead(n.id),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    side: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                  ),
                  tileColor: n.read ? cs.surface : cs.primaryContainer.withValues(alpha: 0.35),
                  leading: Icon(n.read ? Icons.notifications_none_rounded : Icons.notifications_active_rounded, color: cs.primary),
                  title: Text(n.title, style: context.textStyles.titleSmall?.semiBold),
                  subtitle: Text('${n.body}\n${formatRelativeTime(n.createdAt)}', style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant)),
                  isThreeLine: true,
                  trailing: n.read ? null : Icon(Icons.circle, size: 10, color: cs.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
