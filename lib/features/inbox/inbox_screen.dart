import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'inbox_provider.dart';

// ── Colors ────────────────────────────────────────────────────────────────────

const _purple  = Color(0xFF7C3AED);
const _card    = Color(0xFF1A1040);
const _surface = Color(0xFF120C30);
const _textSub = Color(0xFF9CA3AF);

// ── Inbox Screen ──────────────────────────────────────────────────────────────

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0A1E), Color(0xFF1A1040), Color(0xFF2D1B69)],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            // ── AppBar ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Expanded(
                  child: Text('Inbox',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                ),
              ]),
            ),

            // ── Tab bar ───────────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabs,
                indicator: BoxDecoration(
                  color: _purple.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _purple.withValues(alpha: 0.5)),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: _textSub,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'Messages'),
                  Tab(text: 'My Feedback'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Tab views ─────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _MessagesTab(onRefresh: () => ref.refresh(messageThreadsProvider)),
                  _FeedbackTab(onRefresh: () => ref.refresh(parentFeedbackProvider)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Messages tab ──────────────────────────────────────────────────────────────

class _MessagesTab extends ConsumerWidget {
  final VoidCallback onRefresh;
  const _MessagesTab({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(messageThreadsProvider);

    return threadsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _purple)),
      error: (e, _) => _ErrorState(message: e.toString(), onRetry: onRefresh),
      data: (threads) => threads.isEmpty
          ? const _EmptyState(
              icon: Icons.inbox_rounded,
              title: 'No messages yet',
              subtitle: 'Admin messages will appear here.',
            )
          : RefreshIndicator(
              onRefresh: () async => onRefresh(),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                itemCount: threads.length,
                itemBuilder: (_, i) => _ThreadCard(thread: threads[i]),
              ),
            ),
    );
  }
}

class _ThreadCard extends StatelessWidget {
  final MessageThread thread;
  const _ThreadCard({required this.thread});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => _ThreadDetailScreen(thread: thread)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: thread.userUnread
              ? _purple.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: thread.userUnread
                ? _purple.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.07),
          ),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: _purple.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFAB8FE8), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('Admin',
                    style: TextStyle(fontSize: 12, color: Color(0xFFAB8FE8), fontWeight: FontWeight.w700)),
                if (thread.userUnread) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 7, height: 7,
                    decoration: const BoxDecoration(color: _purple, shape: BoxShape.circle),
                  ),
                ],
              ]),
              const SizedBox(height: 2),
              Text(thread.subject,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: thread.userUnread ? FontWeight.w800 : FontWeight.w600,
                      color: Colors.white)),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: _textSub, size: 18),
        ]),
      ),
    );
  }
}

// ── Thread detail screen ───────────────────────────────────────────────────────

class _ThreadDetailScreen extends ConsumerStatefulWidget {
  final MessageThread thread;
  const _ThreadDetailScreen({required this.thread});

  @override
  ConsumerState<_ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends ConsumerState<_ThreadDetailScreen> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    if (!widget.thread.userUnread) return;
    try {
      await Supabase.instance.client
          .from('message_threads')
          .update({'user_unread': false})
          .eq('id', widget.thread.id);
    } catch (_) {}
  }

  Future<void> _sendReply() async {
    final body = _ctrl.text.trim();
    if (body.isEmpty) return;
    setState(() => _sending = true);
    try {
      await Supabase.instance.client.from('thread_messages').insert({
        'thread_id': widget.thread.id,
        'sender': 'user',
        'body': body,
      });
      await Supabase.instance.client.from('message_threads').update({
        'admin_unread': true,
        'last_message_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', widget.thread.id);
      _ctrl.clear();
      if (mounted) {
        ref.refresh(threadMessagesProvider(widget.thread.id));
        setState(() => _sending = false);
      }
    } catch (_) {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(threadMessagesProvider(widget.thread.id));

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _card,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.thread.subject,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
          const Text('from Admin',
              style: TextStyle(color: _textSub, fontSize: 11)),
        ]),
        elevation: 0,
      ),
      body: Column(children: [
        Expanded(
          child: messagesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: _purple)),
            error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: _textSub))),
            data: (messages) => ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: messages.length,
              itemBuilder: (_, i) => _MessageBubble(msg: messages[i]),
            ),
          ),
        ),

        // Reply bar
        Container(
          padding: EdgeInsets.fromLTRB(12, 10, 12,
              10 + MediaQuery.of(context).viewInsets.bottom),
          color: _card,
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Reply…',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13),
                  filled: true,
                  fillColor: _surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sending ? null : _sendReply,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _sending ? Colors.grey : _purple,
                  shape: BoxShape.circle,
                ),
                child: _sending
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ThreadMessage msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isAdmin = msg.isAdmin;
    return Align(
      alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isAdmin
              ? _purple.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.09),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isAdmin ? 4 : 16),
            bottomRight: Radius.circular(isAdmin ? 16 : 4),
          ),
          border: Border.all(
            color: isAdmin
                ? _purple.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (isAdmin)
            const Text('Admin',
                style: TextStyle(fontSize: 10, color: Color(0xFFAB8FE8), fontWeight: FontWeight.w700)),
          Text(msg.body, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
        ]),
      ),
    );
  }
}

// ── Feedback tab ──────────────────────────────────────────────────────────────

class _FeedbackTab extends ConsumerWidget {
  final VoidCallback onRefresh;
  const _FeedbackTab({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackAsync = ref.watch(parentFeedbackProvider);

    return feedbackAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _purple)),
      error: (e, _) => _ErrorState(message: e.toString(), onRetry: onRefresh),
      data: (items) => items.isEmpty
          ? const _EmptyState(
              icon: Icons.feedback_rounded,
              title: 'No feedback submitted yet',
              subtitle: 'Send feedback from Settings → Feedback & Bug Report.',
            )
          : RefreshIndicator(
              onRefresh: () async => onRefresh(),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                itemCount: items.length,
                itemBuilder: (_, i) => _FeedbackCard(item: items[i]),
              ),
            ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final FeedbackItem item;
  const _FeedbackCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final catColor = item.category == 'bug'
        ? Colors.red
        : item.category == 'suggestion'
            ? const Color(0xFFF59E0B)
            : const Color(0xFF3B82F6);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.resolved
            ? Colors.green.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.resolved
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(item.category.toUpperCase(),
                style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w800, color: catColor, letterSpacing: 0.8)),
          ),
          const SizedBox(width: 8),
          Text(
            '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}',
            style: const TextStyle(fontSize: 10, color: _textSub),
          ),
          const Spacer(),
          if (item.resolved)
            const Row(children: [
              Icon(Icons.check_circle_rounded, size: 13, color: Colors.green),
              SizedBox(width: 4),
              Text('Resolved', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w700)),
            ]),
        ]),
        const SizedBox(height: 8),
        Text(item.message, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
        if (item.adminReply != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _purple.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _purple.withValues(alpha: 0.2)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.admin_panel_settings_rounded, size: 13, color: Color(0xFFAB8FE8)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Admin reply',
                      style: TextStyle(fontSize: 10, color: Color(0xFFAB8FE8), fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(item.adminReply!,
                      style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4)),
                ]),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: _purple.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFAB8FE8), size: 36),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13, height: 1.5)),
          ]),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 36),
          const SizedBox(height: 10),
          Text('Error: $message',
              style: const TextStyle(color: _textSub, fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: _purple),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ]),
      );
}
