import 'package:flutter/material.dart';
import 'package:people_desk/theme.dart';

class AppErrorState extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onRetry;

  const AppErrorState({super.key, required this.title, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: AppSpacing.paddingLg,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(Icons.error_outline, size: 28, color: cs.onErrorContainer),
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
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: Icon(Icons.refresh, color: cs.onPrimary),
                  label: Text('Retry', style: context.textStyles.labelLarge?.withColor(cs.onPrimary)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
