import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:people_desk/state/support_controller.dart';
import 'package:people_desk/theme.dart';
import 'package:people_desk/ui/utils/formatters.dart';
import 'package:people_desk/ui/widgets/app_empty_state.dart';
import 'package:people_desk/ui/widgets/app_error_state.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  bool _bootstrapped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<SupportController>().refresh());
  }

  void _openCreateTicketSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CreateTicketSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ctrl = context.watch<SupportController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
        actions: [
          IconButton(onPressed: ctrl.refresh, icon: Icon(Icons.refresh_rounded, color: cs.onSurface)),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: ctrl.isLoading ? null : _openCreateTicketSheet,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('New ticket'),
      ),
      body: ListView(
        padding: AppSpacing.paddingMd,
        children: [
          if (ctrl.error != null) ...[
            AppErrorState(title: 'Support', message: ctrl.error!),
            const SizedBox(height: AppSpacing.md),
          ],
          if (ctrl.tickets.isEmpty && ctrl.isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: CircularProgressIndicator()))
          else if (ctrl.tickets.isEmpty)
            const AppEmptyState(title: 'No tickets', message: 'Create a ticket if you need help.')
          else
            ...ctrl.tickets.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    side: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                  ),
                  tileColor: cs.surface,
                  leading: Icon(Icons.support_agent_rounded, color: cs.primary),
                  title: Text(t.subject, style: context.textStyles.titleSmall?.semiBold),
                  subtitle: Text(
                    '${t.status.toUpperCase()} · ${formatRelativeTime(t.createdAt)}',
                    style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openTicketDetail(t.id),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openTicketDetail(String id) async {
    final ctrl = context.read<SupportController>();
    final detail = await ctrl.fetchDetail(id);
    if (!mounted) return;
    if (detail == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _TicketDetailSheet(ticketId: id, initial: detail),
    );
  }
}

class _CreateTicketSheet extends StatefulWidget {
  const _CreateTicketSheet();

  @override
  State<_CreateTicketSheet> createState() => _CreateTicketSheetState();
}

class _CreateTicketSheetState extends State<_CreateTicketSheet> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _message = TextEditingController();

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ctrl = context.read<SupportController>();
    await ctrl.createTicket(subject: _subject.text.trim(), message: _message.text.trim());
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SupportController>();
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
            Text('New ticket', style: context.textStyles.titleLarge?.bold),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _subject,
              decoration: const InputDecoration(labelText: 'Subject'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a subject' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _message,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Message'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a message' : null,
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

class _TicketDetailSheet extends StatefulWidget {
  final String ticketId;
  final TicketDetail initial;
  const _TicketDetailSheet({required this.ticketId, required this.initial});

  @override
  State<_TicketDetailSheet> createState() => _TicketDetailSheetState();
}

class _TicketDetailSheetState extends State<_TicketDetailSheet> {
  late TicketDetail _detail;
  final _reply = TextEditingController();

  @override
  void initState() {
    super.initState();
    _detail = widget.initial;
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final text = _reply.text.trim();
    if (text.isEmpty) return;
    _reply.clear();
    await context.read<SupportController>().replyToTicket(widget.ticketId, message: text);
    final updated = await context.read<SupportController>().fetchDetail(widget.ticketId);
    if (!mounted) return;
    if (updated != null) setState(() => _detail = updated);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
          top: AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_detail.ticket.subject, style: context.textStyles.titleLarge?.bold),
            const SizedBox(height: AppSpacing.xs),
            Text('Status: ${_detail.ticket.status}', style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 320,
              child: ListView.builder(
                itemCount: _detail.replies.length,
                itemBuilder: (context, i) {
                  final r = _detail.replies[i];
                  final bubbleColor = r.fromStaff ? cs.surfaceContainerHighest : cs.primaryContainer;
                  final textColor = r.fromStaff ? cs.onSurface : cs.onPrimaryContainer;
                  final align = r.fromStaff ? Alignment.centerLeft : Alignment.centerRight;
                  return Align(
                    alignment: align,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      constraints: const BoxConstraints(maxWidth: 560),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.message, style: context.textStyles.bodyMedium?.withColor(textColor)),
                          const SizedBox(height: AppSpacing.xs),
                          Text(formatRelativeTime(r.createdAt), style: context.textStyles.labelSmall?.withColor(textColor.withValues(alpha: 0.8))),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _reply,
                    decoration: const InputDecoration(hintText: 'Write a reply…'),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendReply(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: _sendReply,
                  child: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
