import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_bootstrap.dart';
import '../auth/auth_notifier.dart';

class LinkedChild {
  final String id;
  final String nickname;
  final String? avatarUrl;
  final String avatarId;
  final int coins;
  final int xp;
  final int level;
  final bool isLocked;
  final int streakCurrent;
  final bool storyPack;

  const LinkedChild({
    required this.id,
    required this.nickname,
    this.avatarUrl,
    this.avatarId = '',
    required this.coins,
    required this.xp,
    required this.level,
    required this.isLocked,
    required this.streakCurrent,
    this.storyPack = false,
  });

  factory LinkedChild.fromMap(Map<String, dynamic> m) => LinkedChild(
        id: m['id'] as String,
        nickname: m['nickname'] as String? ?? 'Child',
        avatarUrl: m['avatar_url'] as String?,
        avatarId: m['avatar_id'] as String? ?? '',
        coins: (m['coins'] as num?)?.toInt() ?? 0,
        xp: (m['xp'] as num?)?.toInt() ?? 0,
        level: (m['level'] as num?)?.toInt() ?? 1,
        isLocked: m['is_locked'] as bool? ?? false,
        streakCurrent: (m['streak_current'] as num?)?.toInt() ?? 0,
        storyPack: m['story_pack'] as bool? ?? false,
      );
}

class LinkNotifier extends AsyncNotifier<List<LinkedChild>> {
  @override
  Future<List<LinkedChild>> build() async {
    return _fetchLinkedChildren();
  }

  Future<List<LinkedChild>> _fetchLinkedChildren() async {
    final client = ref.read(supabaseClientProvider);
    final parentId = ref.read(authProvider.notifier).currentUserId;
    if (client == null || parentId == null) return [];

    final rows = await client
        .from('profiles')
        .select('id, nickname, avatar_url, avatar_id, coins, xp, level, is_locked, streak_current, story_pack')
        .eq('parent_id', parentId)
        .order('nickname');
    return (rows as List).map((r) => LinkedChild.fromMap(r)).toList();
  }

  Future<String?> linkChildByCode(String inviteCode) async {
    final client = ref.read(supabaseClientProvider);
    final parentId = ref.read(authProvider.notifier).currentUserId;
    if (client == null || parentId == null) return 'Not signed in';

    final trimmed = inviteCode.trim().toUpperCase();
    final rows = await client
        .from('profiles')
        .select('id, nickname')
        .eq('invite_code', trimmed)
        .limit(1);

    if ((rows as List).isEmpty) return 'No child found with that code';

    final childId = rows.first['id'] as String;
    await client.from('profiles').update({'parent_id': parentId}).eq('id', childId);
    ref.invalidateSelf();
    return null;
  }

  Future<void> setLocked(String childId, {required bool locked}) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return;
    await client
        .from('profiles')
        .update({'is_locked': locked})
        .eq('id', childId);
    ref.invalidateSelf();
  }

  Future<void> setStoryPack(String childId, {required bool active}) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return;
    await client
        .from('profiles')
        .update({'story_pack': active})
        .eq('id', childId);
    ref.invalidateSelf();
  }

  Future<void> refresh() => _fetchLinkedChildren().then((v) => state = AsyncData(v));

  void subscribeRealtime(SupabaseClient client, String parentId) {
    client
        .channel('parent_children_$parentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'parent_id',
            value: parentId,
          ),
          callback: (_) => ref.invalidateSelf(),
        )
        .subscribe();
  }
}

final linkedChildrenProvider =
    AsyncNotifierProvider<LinkNotifier, List<LinkedChild>>(LinkNotifier.new);
