import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase_bootstrap.dart';
import '../auth/auth_notifier.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class ParentReward {
  const ParentReward({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.coinPrice,
    required this.isActive,
  });
  final String id;
  final String name;
  final String emoji;
  final String description;
  final int coinPrice;
  final bool isActive;

  factory ParentReward.fromMap(Map<String, dynamic> m) => ParentReward(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        emoji: m['emoji'] as String? ?? '🎁',
        description: m['description'] as String? ?? '',
        coinPrice: (m['coin_price'] as num?)?.toInt() ?? 10,
        isActive: m['is_active'] as bool? ?? true,
      );
}

class RewardRequest {
  const RewardRequest({
    required this.id,
    required this.rewardId,
    required this.childId,
    required this.childNickname,
    required this.rewardName,
    required this.rewardEmoji,
    required this.coinPrice,
    required this.status,
    required this.createdAt,
  });
  final String id;
  final String rewardId;
  final String childId;
  final String childNickname;
  final String rewardName;
  final String rewardEmoji;
  final int coinPrice;
  final String status; // pending | approved | denied
  final DateTime createdAt;

  factory RewardRequest.fromMap(Map<String, dynamic> m) => RewardRequest(
        id: m['id'] as String,
        rewardId: m['reward_id'] as String? ?? '',
        childId: m['child_id'] as String? ?? '',
        childNickname: (m['profiles'] as Map?)?['nickname'] as String? ?? 'Child',
        rewardName: (m['parent_rewards'] as Map?)?['name'] as String? ?? '',
        rewardEmoji: (m['parent_rewards'] as Map?)?['emoji'] as String? ?? '🎁',
        coinPrice: (m['coin_price_at_request'] as num?)?.toInt() ?? 0,
        status: m['status'] as String? ?? 'pending',
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

// ── Rewards notifier ──────────────────────────────────────────────────────────

class ParentShopNotifier extends AsyncNotifier<List<ParentReward>> {
  @override
  Future<List<ParentReward>> build() => _fetch();

  Future<List<ParentReward>> _fetch() async {
    final client = ref.read(supabaseClientProvider);
    final parentId = ref.read(authProvider.notifier).currentUserId;
    if (client == null || parentId == null) return [];
    final rows = await client
        .from('parent_rewards')
        .select()
        .eq('parent_id', parentId)
        .order('created_at', ascending: false);
    return (rows as List).map((r) => ParentReward.fromMap(r)).toList();
  }

  Future<String?> addReward({
    required String name,
    required String emoji,
    required String description,
    required int coinPrice,
  }) async {
    final client = ref.read(supabaseClientProvider);
    final parentId = ref.read(authProvider.notifier).currentUserId;
    if (client == null || parentId == null) return 'Not signed in';
    try {
      await client.from('parent_rewards').insert({
        'parent_id': parentId,
        'name': name.trim(),
        'emoji': emoji,
        'description': description.trim(),
        'coin_price': coinPrice,
        'is_active': true,
      });
      ref.invalidateSelf();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateReward({
    required String id,
    required String name,
    required String emoji,
    required String description,
    required int coinPrice,
  }) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return 'Not signed in';
    try {
      await client.from('parent_rewards').update({
        'name': name.trim(),
        'emoji': emoji,
        'description': description.trim(),
        'coin_price': coinPrice,
      }).eq('id', id);
      ref.invalidateSelf();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> toggleActive(String id, {required bool active}) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return;
    await client.from('parent_rewards').update({'is_active': active}).eq('id', id);
    ref.invalidateSelf();
  }

  Future<String?> deleteReward(String id) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return 'Not signed in';
    try {
      await client.from('parent_rewards').delete().eq('id', id);
      ref.invalidateSelf();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final parentShopProvider =
    AsyncNotifierProvider<ParentShopNotifier, List<ParentReward>>(
        ParentShopNotifier.new);

// ── Pending requests provider ─────────────────────────────────────────────────

final pendingRequestsProvider =
    FutureProvider<List<RewardRequest>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final parentId = ref.read(authProvider.notifier).currentUserId;
  if (client == null || parentId == null) return [];

  final rows = await client
      .from('reward_requests')
      .select('*, profiles(nickname), parent_rewards(name, emoji)')
      .eq('parent_id', parentId)
      .eq('status', 'pending')
      .order('created_at', ascending: false);

  return (rows as List).map((r) => RewardRequest.fromMap(r)).toList();
});

// ── Request actions ───────────────────────────────────────────────────────────

final requestActionsProvider = Provider((ref) => _RequestActions(ref));

class _RequestActions {
  const _RequestActions(this._ref);
  final Ref _ref;

  Future<void> approve(String requestId, String childId, int coinPrice) async {
    final client = _ref.read(supabaseClientProvider);
    if (client == null) return;
    // Mark approved
    await client
        .from('reward_requests')
        .update({'status': 'approved'})
        .eq('id', requestId);
    // Deduct coins from child
    await client.rpc('deduct_child_coins',
        params: {'child_id': childId, 'amount': coinPrice});
    _ref.invalidate(pendingRequestsProvider);
  }

  Future<void> deny(String requestId) async {
    final client = _ref.read(supabaseClientProvider);
    if (client == null) return;
    await client
        .from('reward_requests')
        .update({'status': 'denied'})
        .eq('id', requestId);
    _ref.invalidate(pendingRequestsProvider);
  }
}
