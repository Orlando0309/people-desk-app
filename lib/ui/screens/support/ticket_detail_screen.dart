import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:people_desk/state/support_controller.dart';
import 'package:people_desk/theme.dart';
import 'package:people_desk/ui/utils/formatters.dart';
import 'package:people_desk/ui/widgets/app_error_state.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  TicketDetail? _detail;
  bool _loading = true;
  final _replyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final detail = await context.read<SupportController>().fetchDetail(widget.ticketId);
    if (!mounted) return;
    setState(() {
      _detail = detail;
      _loading = false;
    });
  }

  Future<void> _sendReply() async {
    final msg = _replyCtrl.text.trim();
    if (msg.isEmpty) return;
    _replyCtrl.clear();
    await context.read<SupportController>().replyToTicket(widget.ticketId, message: msg);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket', style: context.textStyles.titleLarge?.semiBold),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_detail == null)
              ? AppErrorState(title: 'Could not load ticket', onRetry: _load)
              : Column(
                  children: [
                    Padding(
                      padding: AppSpacing.paddingMd,
                      child: Container(
                        width: double.infinity,
                        padding: AppSpacing.paddingMd,
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_detail!.ticket.subject, style: context.textStyles.titleMedium?.semiBold),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${_detail!.ticket.status} • ${AppFormatters.date(_detail!.ticket.createdAt)}',
                              style: context.textStyles.bodyMedium?.withColor(cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: AppSpacing.horizontalMd,
                        itemCount: _detail!.replies.length,
                        itemBuilder: (context, i) {
                          final r = _detail!.replies[i];
                          final isStaff = r.fromStaff;
                          final align = isStaff ? CrossAxisAlignment.start : CrossAxisAlignment.end;
                          final bubbleColor = isStaff ? cs.surface : cs.primaryContainer;
                          final bubbleText = isStaff ? cs.onSurface : cs.onPrimaryContainer;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              crossAxisAlignment: align,
                              children: [
                                Container(
                                  constraints: const BoxConstraints(maxWidth: 520),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: bubbleColor,
                                    borderRadius: BorderRadius.circular(AppRadius.lg),
                                    border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
                                  ),
                                  child: Text(r.message, style: context.textStyles.bodyMedium?.withColor(bubbleText)),
                                ),
                                const SizedBox(height: 4),
                                Text(AppFormatters.time(r.createdAt), style: context.textStyles.labelSmall?.withColor(cs.onSurfaceVariant)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: AppSpacing.paddingMd,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _replyCtrl,
                              decoration: const InputDecoration(hintText: 'Write a reply…', prefixIcon: Icon(Icons.chat_rounded)),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          FilledButton(
                            onPressed: _sendReply,
                            child: Icon(Icons.send_rounded, color: cs.onPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
