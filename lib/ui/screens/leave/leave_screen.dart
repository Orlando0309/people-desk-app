import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:people_desk/state/auth_controller.dart';
import 'package:people_desk/state/leave_controller.dart';
import 'package:people_desk/theme.dart';
import 'package:people_desk/ui/utils/formatters.dart';
import 'package:people_desk/ui/widgets/app_empty_state.dart';
import 'package:people_desk/ui/widgets/app_error_state.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  bool _bootstrapped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final employeeId = context.read<AuthController>().user?.employeeId;
      context.read<LeaveController>().refreshAll(employeeId);
    });
  }

  void _openCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CreateLeaveSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ctrl = context.watch<LeaveController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave'),
        actions: [
          IconButton(
            onPressed: () {
              final employeeId = context.read<AuthController>().user?.employeeId;
              ctrl.refreshAll(employeeId);
            },
            icon: Icon(Icons.refresh_rounded, color: cs.onSurface),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: ctrl.isLoading ? null : _openCreateSheet,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Request'),
      ),
      body: ListView(
        padding: AppSpacing.paddingMd,
        children: [
          if (ctrl.error != null) ...[
            AppErrorState(title: 'Leave', message: ctrl.error!),
            const SizedBox(height: AppSpacing.md),
          ],
          Text('Balances', style: context.textStyles.titleMedium?.semiBold),
          const SizedBox(height: AppSpacing.sm),
          if (ctrl.balances.isEmpty && ctrl.isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: CircularProgressIndicator()))
          else if (ctrl.balances.isEmpty)
            const AppEmptyState(title: 'No balances yet', message: 'Your leave balances will show here.')
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: ctrl.balances
                  .map(
                    (b) => Container(
                      width: (MediaQuery.of(context).size.width - (AppSpacing.md * 2) - AppSpacing.sm) / 2,
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
                          Text('${b.remaining.toStringAsFixed(0)} / ${b.total.toStringAsFixed(0)}', style: context.textStyles.titleLarge?.bold),
                          const SizedBox(height: AppSpacing.xs),
                          LinearProgressIndicator(
                            value: (b.total <= 0) ? 0 : (b.remaining / b.total).clamp(0, 1),
                            backgroundColor: cs.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation(cs.primary),
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),

          const SizedBox(height: AppSpacing.lg),
          Text('Requests', style: context.textStyles.titleMedium?.semiBold),
          const SizedBox(height: AppSpacing.sm),
          if (ctrl.requests.isEmpty && ctrl.isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: CircularProgressIndicator()))
          else if (ctrl.requests.isEmpty)
            const AppEmptyState(title: 'No requests', message: 'Submit your first leave request.')
          else
            ...ctrl.requests.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    side: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                  ),
                  tileColor: cs.surface,
                  leading: Icon(Icons.event_note_rounded, color: cs.primary),
                  title: Text(r.type, style: context.textStyles.titleSmall?.semiBold),
                  subtitle: Text('${formatDate(r.start)} → ${formatDate(r.end)}', style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant)),
                  trailing: _StatusChip(status: r.status),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final color = s.contains('approve')
        ? AppStatusColors.success
        : s.contains('reject')
            ? AppStatusColors.danger
            : AppStatusColors.warning;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(status, style: context.textStyles.labelSmall?.semiBold.withColor(cs.onSurface)),
    );
  }
}

class _CreateLeaveSheet extends StatefulWidget {
  const _CreateLeaveSheet();

  @override
  State<_CreateLeaveSheet> createState() => _CreateLeaveSheetState();
}

class _CreateLeaveSheetState extends State<_CreateLeaveSheet> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'Annual';
  DateTime _start = DateTime.now().add(const Duration(days: 2));
  DateTime _end = DateTime.now().add(const Duration(days: 3));
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _start : _end;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ctrl = context.read<LeaveController>();
    final employeeId = context.read<AuthController>().user?.employeeId;
    await ctrl.createRequest(
      employeeId: employeeId,
      type: _type,
      start: _start,
      end: _end,
      reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
    );
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ctrl = context.watch<LeaveController>();
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
        top: AppSpacing.sm,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New request', style: context.textStyles.titleLarge?.bold),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              value: _type,
              items: const [
                DropdownMenuItem(value: 'Annual', child: Text('Annual')),
                DropdownMenuItem(value: 'Sick', child: Text('Sick')),
                DropdownMenuItem(value: 'Casual', child: Text('Casual')),
              ],
              onChanged: (v) => setState(() => _type = v ?? 'Annual'),
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isStart: true),
                    icon: Icon(Icons.event_rounded, color: cs.primary),
                    label: Text(formatDate(_start), style: context.textStyles.labelLarge?.withColor(cs.onSurface)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isStart: false),
                    icon: Icon(Icons.event_available_rounded, color: cs.primary),
                    label: Text(formatDate(_end), style: context.textStyles.labelLarge?.withColor(cs.onSurface)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _reason,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Reason (optional)'),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: ctrl.isLoading ? null : _submit,
                icon: const Icon(Icons.send_rounded),
                label: Text(ctrl.isLoading ? 'Submitting…' : 'Submit', style: context.textStyles.labelLarge?.semiBold),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
