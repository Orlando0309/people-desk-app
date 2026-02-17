import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:people_desk/nav.dart';
import 'package:people_desk/state/payroll_controller.dart';
import 'package:people_desk/theme.dart';
import 'package:people_desk/ui/utils/formatters.dart';
import 'package:people_desk/ui/widgets/app_empty_state.dart';
import 'package:people_desk/ui/widgets/app_error_state.dart';

class PayslipsScreen extends StatefulWidget {
  const PayslipsScreen({super.key});

  @override
  State<PayslipsScreen> createState() => _PayslipsScreenState();
}

class _PayslipsScreenState extends State<PayslipsScreen> {
  bool _bootstrapped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<PayrollController>().refresh());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ctrl = context.watch<PayrollController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payslips'),
        actions: [
          IconButton(onPressed: ctrl.refresh, icon: Icon(Icons.refresh_rounded, color: cs.onSurface)),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: ListView(
        padding: AppSpacing.paddingMd,
        children: [
          if (ctrl.error != null) ...[
            AppErrorState(title: 'Payroll', message: ctrl.error!),
            const SizedBox(height: AppSpacing.md),
          ],
          if (ctrl.payslips.isEmpty && ctrl.isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: CircularProgressIndicator()))
          else if (ctrl.payslips.isEmpty)
            const AppEmptyState(title: 'No payslips yet', message: 'Your payslips will appear here.')
          else
            ...ctrl.payslips.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  onTap: () => context.push('${AppRoutes.payslips}/${p.id}'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    side: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                  ),
                  tileColor: cs.surface,
                  leading: Icon(Icons.receipt_long_rounded, color: cs.primary),
                  title: Text(p.label, style: context.textStyles.titleSmall?.semiBold),
                  subtitle: Text(formatMonthYear(p.period), style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant)),
                  trailing: Text(formatMoney(p.net), style: context.textStyles.labelLarge?.semiBold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
