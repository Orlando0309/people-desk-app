import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:people_desk/state/attendance_controller.dart';
import 'package:people_desk/theme.dart';
import 'package:people_desk/ui/utils/formatters.dart';
import 'package:people_desk/ui/widgets/app_empty_state.dart';
import 'package:people_desk/ui/widgets/app_error_state.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _bootstrapped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AttendanceController>().refreshAll());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ctrl = context.watch<AttendanceController>();

    // Calculate attendance statistics
    int present = 0;
    int absent = 0;
    int late = 0;
    
    for (var record in ctrl.history) {
      final status = record.status.toLowerCase();
      if (status.contains('present')) present++;
      else if (status.contains('absent')) absent++;
      else if (status.contains('late')) late++;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(onPressed: ctrl.refreshAll, icon: Icon(Icons.refresh_rounded, color: cs.onSurface)),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: ListView(
        padding: AppSpacing.paddingMd,
        children: [
          if (ctrl.error != null) ...[
            AppErrorState(title: 'Attendance', message: ctrl.error!),
            const SizedBox(height: AppSpacing.md),
          ],
          // Statistics Summary Cards
          if (ctrl.history.isNotEmpty && !ctrl.isLoading) ...[
            Text('Summary', style: context.textStyles.titleMedium?.semiBold),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Present',
                    count: present,
                    icon: Icons.check_circle_rounded,
                    color: AppStatusColors.success,
                    bgColor: AppStatusColors.success.withValues(alpha: 0.1),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatCard(
                    title: 'Late',
                    count: late,
                    icon: Icons.schedule_rounded,
                    color: AppStatusColors.warning,
                    bgColor: AppStatusColors.warning.withValues(alpha: 0.1),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatCard(
                    title: 'Absent',
                    count: absent,
                    icon: Icons.cancel_rounded,
                    color: AppStatusColors.danger,
                    bgColor: AppStatusColors.danger.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          
          // History Section
          Text('History', style: context.textStyles.titleMedium?.semiBold),
          const SizedBox(height: AppSpacing.sm),
          if (ctrl.history.isEmpty && ctrl.isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: CircularProgressIndicator()))
          else if (ctrl.history.isEmpty)
            const AppEmptyState(title: 'No history yet', message: 'Your recent attendance will show here.')
          else
            ...ctrl.history.map(
              (d) {
                final present = d.status.toLowerCase().contains('present');
                final late = d.status.toLowerCase().contains('late');
                final statusColor = present 
                    ? AppStatusColors.success 
                    : late 
                        ? AppStatusColors.warning 
                        : AppStatusColors.danger;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: cs.outline.withValues(alpha: 0.1)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                formatDate(d.date),
                                style: context.textStyles.titleSmall?.semiBold,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  d.status,
                                  style: context.textStyles.labelSmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: _TimeChip(
                                  label: 'Check In',
                                  time: d.clockInAt != null ? formatTime(d.clockInAt!) : '—',
                                  icon: Icons.login_rounded,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _TimeChip(
                                  label: 'Check Out',
                                  time: d.clockOutAt != null ? formatTime(d.clockOutAt!) : '—',
                                  icon: Icons.logout_rounded,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$count',
            style: context.textStyles.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: context.textStyles.labelSmall?.withColor(color),
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final String time;
  final IconData icon;

  const _TimeChip({
    required this.label,
    required this.time,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                label,
                style: context.textStyles.labelSmall?.withColor(cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            time,
            style: context.textStyles.bodySmall?.semiBold,
          ),
        ],
      ),
    );
  }
}
