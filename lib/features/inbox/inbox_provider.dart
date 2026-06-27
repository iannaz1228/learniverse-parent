import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Message thread ─────────────────────────────────────────────────────────────

class MessageThread {
  final String id;
  final String subject;
  final String type;
  final bool userUnread;
  final DateTime lastMessageAt;

  const MessageThread({
    required this.id,
    required this.subject,
    required this.type,
    required this.userUnread,
    required this.lastMessageAt,
  });

  factory MessageThread.fromJson(Map<String, dynamic> j) => MessageThread(
        id: j['id'] as String,
        subject: j['subject'] as String? ?? '',
        type: j['type'] as String? ?? 'general',
        userUnread: j['user_unread'] as bool? ?? false,
        lastMessageAt: DateTime.tryParse(j['last_message_at'] as String? ?? '') ?? DateTime.now(),
      );
}

// ── Thread message ─────────────────────────────────────────────────────────────

class ThreadMessage {
  final String id;
  final String threadId;
  final String sender;
  final String body;
  final DateTime createdAt;

  const ThreadMessage({
    required this.id,
    required this.threadId,
    required this.sender,
    required this.body,
    required this.createdAt,
  });

  bool get isAdmin => sender == 'admin';

  factory ThreadMessage.fromJson(Map<String, dynamic> j) => ThreadMessage(
        id: j['id'] as String,
        threadId: j['thread_id'] as String,
        sender: j['sender'] as String? ?? 'user',
        body: j['body'] as String? ?? '',
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

// ── Feedback item ──────────────────────────────────────────────────────────────

class FeedbackItem {
  final String id;
  final String category;
  final String message;
  final String? adminReply;
  final bool resolved;
  final DateTime createdAt;

  const FeedbackItem({
    required this.id,
    required this.category,
    required this.message,
    this.adminReply,
    required this.resolved,
    required this.createdAt,
  });

  factory FeedbackItem.fromJson(Map<String, dynamic> j) => FeedbackItem(
        id: j['id'] as String,
        category: j['category'] as String? ?? 'general',
        message: j['message'] as String? ?? '',
        adminReply: j['admin_reply'] as String?,
        resolved: j['resolved'] as bool? ?? false,
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

// ── Providers ─────────────────────────────────────────────────────────────────

final messageThreadsProvider = FutureProvider<List<MessageThread>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];
  final data = await Supabase.instance.client
      .from('message_threads')
      .select()
      .eq('user_id', user.id)
      .order('last_message_at', ascending: false);
  return List<Map<String, dynamic>>.from(data)
      .map(MessageThread.fromJson)
      .toList();
});

final threadMessagesProvider =
    FutureProvider.family<List<ThreadMessage>, String>((ref, threadId) async {
  final data = await Supabase.instance.client
      .from('thread_messages')
      .select()
      .eq('thread_id', threadId)
      .order('created_at', ascending: true);
  return List<Map<String, dynamic>>.from(data)
      .map(ThreadMessage.fromJson)
      .toList();
});

final parentFeedbackProvider = FutureProvider<List<FeedbackItem>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];
  final data = await Supabase.instance.client
      .from('parent_feedback')
      .select()
      .eq('user_id', user.id)
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(data)
      .map(FeedbackItem.fromJson)
      .toList();
});

final hasUnreadAdminMessagesProvider = FutureProvider<bool>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return false;
  final data = await Supabase.instance.client
      .from('message_threads')
      .select('id')
      .eq('user_id', user.id)
      .eq('user_unread', true)
      .limit(1);
  return (data as List).isNotEmpty;
});
