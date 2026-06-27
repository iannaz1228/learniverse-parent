import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase_bootstrap.dart';
import '../child_link/link_provider.dart';

// ── Coin pack catalogue ───────────────────────────────────────────────────────

class ParentCoinPack {
  const ParentCoinPack({
    required this.label,
    required this.emoji,
    required this.priceLabel,
    required this.coins,
    required this.productId,
    this.tag,
  });
  final String label, emoji, priceLabel, productId;
  final int coins;
  final String? tag;
}

const kParentCoinPacks = [
  ParentCoinPack(label: 'Starter', emoji: '🪙', priceLabel: '\$0.99', coins: 100,  productId: 'coins_100'),
  ParentCoinPack(label: 'Popular', emoji: '💰', priceLabel: '\$2.99', coins: 350,  productId: 'coins_350',  tag: 'POPULAR'),
  ParentCoinPack(label: 'Value',   emoji: '💎', priceLabel: '\$4.99', coins: 700,  productId: 'coins_700',  tag: 'BEST VALUE'),
  ParentCoinPack(label: 'Mega',    emoji: '👑', priceLabel: '\$9.99', coins: 1500, productId: 'coins_1500', tag: 'MEGA'),
];

// ── Wallet notifier ───────────────────────────────────────────────────────────

class ParentWalletNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final client = ref.read(supabaseClientProvider);
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return 0;

    try {
      final data = await client
          .from('parent_wallets')
          .select('coins')
          .eq('parent_id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 6));

      if (data == null) {
        client
            .from('parent_wallets')
            .insert({'parent_id': userId, 'coins': 0})
            .catchError((_) {});
        return 0;
      }
      return (data['coins'] as num).toInt();
    } catch (_) {
      return 0;
    }
  }

  /// Returns null on success, error string on failure.
  Future<String?> addCoins(int amount) async {
    final client = ref.read(supabaseClientProvider);
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return 'Not signed in';
    final newBalance = (state.value ?? 0) + amount;
    try {
      await client.from('parent_wallets').upsert({
        'parent_id': userId,
        'coins': newBalance,
        'updated_at': DateTime.now().toIso8601String(),
      });
      state = AsyncData(newBalance);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Transfers coins from parent wallet to child. Returns null on success, error string on failure.
  Future<String?> giftToChild(String childId, int amount) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return 'Not connected';
    try {
      final result = await client.rpc('transfer_coins_to_child', params: {
        'p_child_id': childId,
        'p_amount': amount,
      }) as String;
      if (result == 'ok') {
        state = AsyncData((state.value ?? 0) - amount);
        ref.invalidate(linkedChildrenProvider);
        return null;
      }
      switch (result) {
        case 'insufficient_funds': return 'Not enough coins in your wallet.';
        case 'no_wallet':          return 'Your wallet hasn\'t been created yet.';
        case 'not_your_child':     return 'This child is not linked to your account.';
        default:                   return result;
      }
    } catch (e) {
      return e.toString();
    }
  }
}

final parentWalletProvider =
    AsyncNotifierProvider<ParentWalletNotifier, int>(ParentWalletNotifier.new);
