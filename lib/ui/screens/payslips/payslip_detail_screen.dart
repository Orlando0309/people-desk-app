import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:people_desk/state/payroll_controller.dart';
import 'package:people_desk/theme.dart';
import 'package:people_desk/ui/utils/formatters.dart';
import 'package:people_desk/ui/widgets/app_empty_state.dart';

class PayslipDetailScreen extends StatelessWidget {
  final String payslipId;
  const PayslipDetailScreen({super.key, required this.payslipId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ctrl = context.read<PayrollController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Payslip')),
      body: FutureBuilder<PayslipDetail?>(
        future: ctrl.fetchDetail(payslipId),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final detail = snap.data;
          if (detail == null) {
            return const Padding(
              padding: AppSpacing.paddingMd,
              child: AppEmptyState(title: 'Not found', message: 'Payslip details are unavailable.'),
            );
          }

          final net = detail.payslip.net;
          final totalEarnings = detail.earnings.fold<double>(0, (p, e) => p + e.amount);
          final totalDeductions = detail.deductions.fold<double>(0, (p, e) => p + e.amount);

          Widget section(String title, List<PayslipLine> lines) => Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.textStyles.titleMedium?.semiBold),
                    const SizedBox(height: AppSpacing.sm),
                    ...lines.map(
                      (l) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            Expanded(child: Text(l.label, style: context.textStyles.bodyMedium)),
                            Text(formatMoney(l.amount), style: context.textStyles.bodyMedium?.semiBold),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );

          return ListView(
            padding: AppSpacing.paddingMd,
            children: [
              Container(
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
                    Text(detail.payslip.label, style: context.textStyles.titleLarge?.bold.withColor(cs.onPrimaryContainer)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(formatMonthYear(detail.payslip.period), style: context.textStyles.bodySmall?.withColor(cs.onPrimaryContainer.withValues(alpha: 0.9))),
                    const SizedBox(height: AppSpacing.md),
                    Text('Net pay', style: context.textStyles.labelLarge?.withColor(cs.onPrimaryContainer)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(formatMoney(net), style: context.textStyles.headlineMedium?.bold.withColor(cs.onPrimaryContainer)),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(child: _MiniStat(label: 'Earnings', value: formatMoney(totalEarnings), tint: AppStatusColors.success)),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: _MiniStat(label: 'Deductions', value: formatMoney(totalDeductions), tint: AppStatusColors.danger)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              section('Earnings', detail.earnings),
              const SizedBox(height: AppSpacing.md),
              section('Deductions', detail.deductions),
            ],
          );
        },
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color tint;
  const _MiniStat({required this.label, required this.value, required this.tint});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: tint.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.textStyles.labelMedium?.withColor(cs.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: context.textStyles.titleMedium?.semiBold),
        ],
      ),
    );
  }
}
