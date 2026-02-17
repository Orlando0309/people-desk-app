import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:people_desk/nav.dart';
import 'package:people_desk/state/auth_controller.dart';
import 'package:people_desk/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'demo@peopledesk.app');
  final _password = TextEditingController(text: 'password');

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthController>();
    final ok = await auth.login(email: _email.text.trim(), password: _password.text);
    if (!mounted) return;
    if (ok) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = context.watch<AuthController>();
    final isBusy = auth.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('PeopleDesk', style: context.textStyles.headlineMedium?.bold),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Sign in to continue', style: context.textStyles.bodyMedium?.withColor(cs.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.lg),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.username, AutofillHints.email],
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your email' : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          autofillHints: const [AutofillHints.password],
                          decoration: const InputDecoration(labelText: 'Password'),
                          validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: isBusy ? null : _submit,
                            icon: const Icon(Icons.lock_rounded),
                            label: Text(isBusy ? 'Signing in…' : 'Sign in', style: context.textStyles.labelLarge?.semiBold),
                          ),
                        ),
                        if (auth.error != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(auth.error!, style: context.textStyles.bodySmall?.withColor(cs.error)),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Mock mode is enabled by default (no network calls).',
                          textAlign: TextAlign.center,
                          style: context.textStyles.labelSmall?.withColor(cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
