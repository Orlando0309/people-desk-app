import 'package:flutter/material.dart';
import 'package:people_desk/theme.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const AppEmptyState({
    super.key,
    this.icon = Icons.inbox_rounded,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: AppSpacing.paddingLg,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(icon, size: 28, color: cs.primary),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: context.textStyles.titleMedium?.semiBold, textAlign: TextAlign.center),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message!,
                  style: context.textStyles.bodyMedium?.withColor(cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: AppSpacing.lg),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
