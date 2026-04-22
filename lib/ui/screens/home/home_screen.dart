import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:people_desk/state/attendance_controller.dart';
import 'package:people_desk/state/auth_controller.dart';
import 'package:people_desk/state/leave_controller.dart';
import 'package:people_desk/state/notifications_controller.dart';
import 'package:people_desk/theme.dart';
import 'package:people_desk/ui/utils/formatters.dart';
import 'package:people_desk/ui/widgets/app_empty_state.dart';
import 'package:people_desk/ui/widgets/app_error_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _bootstrapped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final employeeId = context.read<AuthController>().user?.employeeId;
      context.read<AttendanceController>().refreshAll(employeeId);
      context.read<LeaveController>().refreshAll(employeeId);
      context.read<NotificationsController>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final attendance = context.watch<AttendanceController>();
    final leave = context.watch<LeaveController>();
    final notifications = context.watch<NotificationsController>();
    final today = attendance.today;

    final clockedIn = today?.clockInAt != null && (today?.clockOutAt == null);
    final canClockIn = today?.clockInAt == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              final employeeId = context.read<AuthController>().user?.employeeId;
              attendance.refreshAll(employeeId);
              leave.refreshAll(employeeId);
              notifications.refresh();
            },
            icon: Icon(Icons.refresh_rounded, color: cs.onSurface),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: ListView(
        padding: AppSpacing.paddingMd,
        children: [
          _HeroClockCard(
            status: today?.status ?? '—',
            clockInAt: today?.clockInAt,
            clockOutAt: today?.clockOutAt,
            primaryActionLabel: canClockIn ? 'Clock in' : (clockedIn ? 'Clock out' : 'Done'),
            onPrimaryAction: (attendance.isLoading)
                ? null
                : () {
                    final employeeId = context.read<AuthController>().user?.employeeId;
                    if (canClockIn) {
                      attendance.clockIn(employeeId);
                    } else if (clockedIn) {
                      attendance.clockOut(employeeId);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("You've completed today's attendance.")),
                      );
                    }
                  },
            isLoading: attendance.isLoading,
          ),
          const SizedBox(height: AppSpacing.md),

          if (attendance.error != null) ...[
            AppErrorState(title: 'Attendance', message: attendance.error!),
            const SizedBox(height: AppSpacing.md),
          ],

          _SectionHeader(title: 'Leave balance'),
          const SizedBox(height: AppSpacing.sm),
          if (leave.balances.isEmpty && leave.isLoading)
            const _LoadingCard()
          else if (leave.balances.isEmpty)
            const AppEmptyState(title: 'No leave data yet', message: 'Balances will appear here.')
          else
            _LeaveBalanceRow(balances: leave.balances),

          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(title: 'Recent alerts'),
          const SizedBox(height: AppSpacing.sm),
          if (notifications.items.isEmpty && notifications.isLoading)
            const _LoadingCard()
          else if (notifications.items.isEmpty)
            const AppEmptyState(title: 'All caught up', message: 'No recent notifications.')
          else
            ...notifications.items.take(3).map(
                  (n) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        side: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                      ),
                      tileColor: cs.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      leading: Icon(n.read ? Icons.notifications_none_rounded : Icons.notifications_active_rounded, color: cs.primary),
                      title: Text(n.title, style: context.textStyles.titleSmall?.semiBold),
                      subtitle: Text('${n.body}\n${formatRelativeTime(n.createdAt)}', style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant)),
                      isThreeLine: true,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(title, style: context.textStyles.titleMedium?.semiBold),
        ],
      );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _LeaveBalanceRow extends StatelessWidget {
  final List<LeaveBalance> balances;
  const _LeaveBalanceRow({required this.balances});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: balances
          .take(3)
          .map(
            (b) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.label, style: context.textStyles.labelLarge?.semiBold),
                    const SizedBox(height: AppSpacing.sm),
                    Text('${b.remaining.toStringAsFixed(0)} left', style: context.textStyles.headlineSmall?.bold),
                    const SizedBox(height: AppSpacing.xs),
                    Text('of ${b.total.toStringAsFixed(0)}', style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _HeroClockCard extends StatelessWidget {
  final String status;
  final String? clockInAt;
  final String? clockOutAt;
  final String primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final bool isLoading;

  const _HeroClockCard({
    required this.status,
    required this.clockInAt,
    required this.clockOutAt,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inTime = clockInAt != null ? formatTime(clockInAt!) : '—';
    final outTime = clockOutAt != null ? formatTime(clockOutAt!) : '—';

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primaryContainer, cs.primaryContainer.withValues(alpha: 0.55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time_rounded, color: cs.onPrimaryContainer),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('Today', style: context.textStyles.titleMedium?.semiBold.withColor(cs.onPrimaryContainer))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
                ),
                child: Text(status, style: context.textStyles.labelMedium?.withColor(cs.onSurface)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _TimeCell(label: 'Clock in', value: inTime),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _TimeCell(label: 'Clock out', value: outTime),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onPrimaryAction,
              child: isLoading
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                    )
                  : Text(primaryActionLabel, style: context.textStyles.labelLarge?.semiBold.withColor(cs.onPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeCell extends StatelessWidget {
  final String label;
  final String value;
  const _TimeCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.textStyles.labelMedium?.withColor(cs.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: context.textStyles.titleLarge?.bold),
        ],
      ),
    );
  }
}
