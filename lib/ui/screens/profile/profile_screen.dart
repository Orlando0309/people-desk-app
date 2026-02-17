import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:people_desk/state/auth_controller.dart';
import 'package:people_desk/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = context.watch<AuthController>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: AppSpacing.paddingMd,
        children: [
          Container(
            padding: AppSpacing.paddingLg,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: cs.primaryContainer,
                  child: Icon(Icons.person_rounded, color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.fullName ?? 'Employee', style: context.textStyles.titleLarge?.bold),
                      const SizedBox(height: AppSpacing.xs),
                      Text(user?.email ?? '—', style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: auth.isLoading ? null : auth.logout,
              icon: Icon(Icons.logout_rounded, color: cs.primary),
              label: Text('Sign out', style: context.textStyles.labelLarge?.semiBold.withColor(cs.onSurface)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Tip: when you’re ready to switch to the real API, set `PEOPLE_DESK_USE_MOCK=false` and provide `PEOPLE_DESK_API_BASE_URL`.',
            style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
