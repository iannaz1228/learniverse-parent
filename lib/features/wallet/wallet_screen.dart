import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_router.dart';
import '../child_link/link_provider.dart';
import '../settings/settings_screen.dart' show showBuyMeCoffeeSheet;
import 'wallet_pin.dart';
import 'wallet_provider.dart';

// ── Avatar emoji map (mirrors child app AppConstants.avatarEmojis) ───────────

const _kWalletAvatarEmojis = {
  'fox_01': '🦊', 'bear_01': '🐻', 'bunny_01': '🐰',
  'cat_01': '🐱', 'dino_01': '🦕', 'owl_01': '🦉',
};

String _walletAvatarEmoji(child) {
  final emoji = _kWalletAvatarEmojis[child.avatarUrl] ??
      _kWalletAvatarEmojis[child.avatarId];
  if (emoji != null) return emoji;
  return child.nickname.isNotEmpty ? child.nickname[0].toUpperCase() : '?';
}

bool _walletAvatarIsEmoji(child) =>
    _kWalletAvatarEmojis.containsKey(child.avatarUrl) ||
    _kWalletAvatarEmojis.containsKey(child.avatarId);

// ── Coin image helper ─────────────────────────────────────────────────────────

Widget _coinImage({double size = 16}) => Image.asset(
      'assets/images/icons/coin-icon.png',
      width: size,
      height: size,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.monetization_on_rounded, color: const Color(0xFFFBBF24), size: size),
    );

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync  = ref.watch(parentWalletProvider);
    final childrenAsync = ref.watch(linkedChildrenProvider);

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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              // ── Header ──────────────────────────────────────────────────
              const Text(
                'My Wallet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Gift coins to your children',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.50),
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 20),

              // ── Balance card ─────────────────────────────────────────────
              _BalanceCard(coins: walletAsync.value ?? 0),

              const SizedBox(height: 20),

              // ── Add Coins section ────────────────────────────────────────
              Row(
                children: [
                  const _SectionHeader(icon: Icons.add_circle_rounded, title: 'Top Up Wallet', color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.30)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.lock_rounded, size: 10, color: Color(0xFF10B981)),
                        SizedBox(width: 4),
                        Text('PIN protected', style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Add coins directly to your wallet',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
              ),
              const SizedBox(height: 12),
              _AddCoinsSection(currentCoins: walletAsync.value ?? 0),

              const SizedBox(height: 16),

              // ── Supporters Wall link ─────────────────────────────────────
              GestureDetector(
                onTap: () => context.push(AppRoutes.supportersWall),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5A623).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF5A623).withValues(alpha: 0.30)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5A623).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(child: Text('☕', style: TextStyle(fontSize: 20))),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Supporters Wall',
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                            SizedBox(height: 2),
                            Text('See parents who love LearniVerse 💛',
                                style: TextStyle(color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── Buy Me a Coffee shortcut ─────────────────────────────────
              GestureDetector(
                onTap: () => showBuyMeCoffeeSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF5A623).withValues(alpha: 0.18),
                        const Color(0xFFF5A623).withValues(alpha: 0.06),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF5A623).withValues(alpha: 0.45)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5A623).withValues(alpha: 0.20),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(child: Text('☕', style: TextStyle(fontSize: 20))),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Buy Me a Coffee',
                                style: TextStyle(
                                  color: Color(0xFFF5A623),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                )),
                            SizedBox(height: 2),
                            Text('Support the developer & get coins 🪙',
                                style: TextStyle(color: Colors.white60, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.open_in_new_rounded,
                          color: Color(0xFFF5A623), size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Gift to Children section ─────────────────────────────────
              const _SectionHeader(icon: Icons.card_giftcard_rounded, title: 'Gift to Child', color: Color(0xFFF59E0B)),
              const SizedBox(height: 4),
              Text(
                'Send coins from your wallet to a linked child',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
              ),
              const SizedBox(height: 12),

              childrenAsync.when(
                loading: () => const CircularProgressIndicator(color: Color(0xFF7C3AED)),
                error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.white54)),
                data: (kids) => kids.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Text(
                          'No children linked yet.\nLink a child from the Children tab first.',
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Column(
                        children: kids
                            .map((child) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _GiftChildRow(
                                    child: child,
                                    parentCoins: walletAsync.value ?? 0,
                                  ),
                                ))
                            .toList(),
                      ),
              ),

            ],
          ),
        ),
      ),
    );
  }

}

// ── Balance Card ──────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B21B6), Color(0xFF7C3AED), Color(0xFF9333EA)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.40),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Parent Wallet',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$coins',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6, left: 8),
                      child: Text(
                        'coins',
                        style: TextStyle(color: Colors.white60, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Buy coins below, then gift them to your child',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          _coinImage(size: 64),
        ],
      ),
    );
  }
}

// ── Gift child row ────────────────────────────────────────────────────────────

class _GiftChildRow extends StatelessWidget {
  const _GiftChildRow({required this.child, required this.parentCoins});
  final LinkedChild child;
  final int parentCoins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.25),
            backgroundImage: (child.avatarUrl?.startsWith('http') == true)
                ? NetworkImage(child.avatarUrl!)
                : null,
            child: (child.avatarUrl?.startsWith('http') != true)
                ? Text(
                    _walletAvatarEmoji(child),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: _walletAvatarIsEmoji(child) ? 20 : 14,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(child.nickname,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                Row(
                  children: [
                    _coinImage(size: 13),
                    const SizedBox(width: 4),
                    Text('${child.coins} coins',
                        style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.card_giftcard_rounded, size: 16),
            label: const Text('Gift', style: TextStyle(fontWeight: FontWeight.w800)),
            onPressed: () => _showGiftSheet(context, child),
          ),
        ],
      ),
    );
  }

  void _showGiftSheet(BuildContext context, LinkedChild child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GiftSheet(child: child, parentCoins: parentCoins),
    );
  }
}

// ── Gift bottom sheet ─────────────────────────────────────────────────────────

class _GiftSheet extends ConsumerStatefulWidget {
  const _GiftSheet({required this.child, required this.parentCoins});
  final LinkedChild child;
  final int parentCoins;

  @override
  ConsumerState<_GiftSheet> createState() => _GiftSheetState();
}

class _GiftSheetState extends ConsumerState<_GiftSheet> {
  int _amount = 25;
  bool _loading = false;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl.text = '25';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canAfford = widget.parentCoins >= _amount && _amount > 0;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1040),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            )),
            const SizedBox(height: 18),
            Text(
              'Gift Coins to ${widget.child.nickname}',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text('Your wallet: ${widget.parentCoins} coins',
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 20),

            // Quick presets
            Wrap(
              spacing: 10,
              children: [10, 25, 50, 100].map((amt) {
                final sel = _amount == amt;
                return GestureDetector(
                  onTap: () => setState(() {
                    _amount = amt;
                    _ctrl.text = '$amt';
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFFF59E0B) : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: sel ? const Color(0xFFF59E0B) : Colors.white12),
                    ),
                    child: Text(
                      '$amt',
                      style: TextStyle(
                          color: sel ? Colors.white : Colors.white60,
                          fontWeight: FontWeight.w800,
                          fontSize: 15),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),

            // Custom amount
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Custom amount',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.07),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFF59E0B))),
              ),
              onChanged: (v) => setState(() => _amount = int.tryParse(v) ?? 0),
            ),

            const SizedBox(height: 20),

            if (!canAfford && _amount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  widget.parentCoins < _amount
                      ? 'Not enough coins in your wallet'
                      : '',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  disabledBackgroundColor: Colors.white12,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _loading
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.card_giftcard_rounded),
                label: Text(
                  _loading ? 'Sending…' : 'Gift $_amount Coins',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                onPressed: (!canAfford || _loading) ? null : _doGift,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _doGift() async {
    setState(() => _loading = true);
    final err = await ref.read(parentWalletProvider.notifier).giftToChild(widget.child.id, _amount);
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err == null
          ? '$_amount coins gifted to ${widget.child.nickname}! 🎁'
          : 'Error: $err'),
      backgroundColor: err == null ? const Color(0xFF059669) : Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}

// ── Add Coins section ─────────────────────────────────────────────────────────

class _AddCoinsSection extends ConsumerStatefulWidget {
  const _AddCoinsSection({required this.currentCoins});
  final int currentCoins;

  @override
  ConsumerState<_AddCoinsSection> createState() => _AddCoinsSectionState();
}

class _AddCoinsSectionState extends ConsumerState<_AddCoinsSection> {
  bool _loading = false;

  Future<bool> _requirePin() async {
    final hasPin = await WalletPin.isSet();
    if (!mounted) return false;
    if (!hasPin) {
      return await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const _SetPinSheet(),
          ) ??
          false;
    }
    return await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const _VerifyPinSheet(),
        ) ??
        false;
  }

  Future<void> _add(int amount) async {
    if (!await _requirePin()) return;
    setState(() => _loading = true);
    final err = await ref.read(parentWalletProvider.notifier).addCoins(amount);
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err == null ? '+$amount coins added! 🪙' : 'Error: $err'),
      backgroundColor: err == null ? const Color(0xFF059669) : Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _showCustomSheet() async {
    if (!await _requirePin()) return;
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomAddSheet(onAdd: _doAdd),
    );
  }

  Future<void> _doAdd(int amount) async {
    setState(() => _loading = true);
    final err = await ref.read(parentWalletProvider.notifier).addCoins(amount);
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err == null ? '+$amount coins added! 🪙' : 'Error: $err'),
      backgroundColor: err == null ? const Color(0xFF059669) : Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: [
            _CoinAddTile(amount: 100,  emoji: '🪙', loading: _loading, onTap: () async => _add(100)),
            _CoinAddTile(amount: 250,  emoji: '💰', loading: _loading, onTap: () async => _add(250)),
            _CoinAddTile(amount: 500,  emoji: '💎', loading: _loading, onTap: () async => _add(500)),
            _CoinAddTile(amount: 1000, emoji: '👑', loading: _loading, onTap: () async => _add(1000)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _loading ? null : _showCustomSheet,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white60,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: const Text('Custom Amount', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

class _CoinAddTile extends StatelessWidget {
  const _CoinAddTile({required this.amount, required this.emoji, required this.loading, required this.onTap});
  final int amount;
  final String emoji;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              '+$amount',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Custom add sheet ──────────────────────────────────────────────────────────

class _CustomAddSheet extends StatefulWidget {
  const _CustomAddSheet({required this.onAdd});
  final Future<void> Function(int) onAdd;

  @override
  State<_CustomAddSheet> createState() => _CustomAddSheetState();
}

class _CustomAddSheetState extends State<_CustomAddSheet> {
  final _ctrl = TextEditingController();
  int _amount = 0;
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1040),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 18),
            const Text(
              'Add Custom Coins',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text(
              'Enter any amount to add to your wallet',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 24),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.07),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF10B981))),
                suffixText: 'coins',
                suffixStyle: const TextStyle(color: Colors.white38, fontSize: 14),
              ),
              onChanged: (v) => setState(() => _amount = int.tryParse(v) ?? 0),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white12,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _loading
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.add_circle_rounded),
                label: Text(
                  _amount > 0 ? 'Add $_amount Coins' : 'Enter an amount',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                onPressed: (_amount <= 0 || _loading) ? null : () async {
                  setState(() => _loading = true);
                  Navigator.of(context).pop();
                  await widget.onAdd(_amount);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title, required this.color});
  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

// ── PIN: Set PIN sheet ────────────────────────────────────────────────────────

class _SetPinSheet extends StatefulWidget {
  const _SetPinSheet();

  @override
  State<_SetPinSheet> createState() => _SetPinSheetState();
}

class _SetPinSheetState extends State<_SetPinSheet> {
  String _pin = '';
  String? _firstPin;
  bool _confirming = false;
  String? _error;

  void _onDigit(String d) {
    if (_pin.length >= 4) return;
    setState(() { _pin += d; _error = null; });
    if (_pin.length == 4) _onComplete();
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _onComplete() async {
    if (!_confirming) {
      await Future.delayed(const Duration(milliseconds: 120));
      setState(() { _firstPin = _pin; _pin = ''; _confirming = true; });
    } else {
      if (_pin == _firstPin) {
        await WalletPin.save(_pin);
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        await Future.delayed(const Duration(milliseconds: 120));
        setState(() { _pin = ''; _firstPin = null; _confirming = false; _error = "PINs didn't match. Start over."; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PinSheetWrapper(
      title: _confirming ? 'Confirm PIN' : 'Create a PIN',
      subtitle: _confirming ? 'Re-enter your PIN to confirm' : 'Set a 4-digit PIN to protect coin top-ups',
      pin: _pin,
      error: _error,
      onDigit: _onDigit,
      onDelete: _onDelete,
      onCancel: () => Navigator.of(context).pop(false),
    );
  }
}

// ── PIN: Verify PIN sheet ─────────────────────────────────────────────────────

class _VerifyPinSheet extends StatefulWidget {
  const _VerifyPinSheet();

  @override
  State<_VerifyPinSheet> createState() => _VerifyPinSheetState();
}

class _VerifyPinSheetState extends State<_VerifyPinSheet> {
  String _pin = '';
  String? _error;
  bool _checking = false;

  void _onDigit(String d) {
    if (_pin.length >= 4 || _checking) return;
    setState(() { _pin += d; _error = null; });
    if (_pin.length == 4) _verify();
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verify() async {
    setState(() => _checking = true);
    final ok = await WalletPin.verify(_pin);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() { _pin = ''; _error = 'Wrong PIN. Try again.'; _checking = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PinSheetWrapper(
      title: 'Enter PIN',
      subtitle: 'Enter your PIN to add coins',
      pin: _pin,
      error: _error,
      onDigit: _onDigit,
      onDelete: _onDelete,
      onCancel: () => Navigator.of(context).pop(false),
    );
  }
}

// ── PIN: Shared sheet wrapper ─────────────────────────────────────────────────

class _PinSheetWrapper extends StatelessWidget {
  const _PinSheetWrapper({
    required this.title,
    required this.subtitle,
    required this.pin,
    required this.error,
    required this.onDigit,
    required this.onDelete,
    required this.onCancel,
  });

  final String title;
  final String subtitle;
  final String pin;
  final String? error;
  final void Function(String) onDigit;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0A1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 24),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),

            // Lock icon
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.40)),
              ),
              child: const Icon(Icons.lock_rounded, color: Color(0xFF7C3AED), size: 28),
            ),
            const SizedBox(height: 14),

            Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 28),

            // 4 dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < pin.length;
                final isError = error != null;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isError
                        ? Colors.redAccent.withValues(alpha: 0.30)
                        : filled
                            ? const Color(0xFF7C3AED)
                            : Colors.white.withValues(alpha: 0.15),
                    border: Border.all(
                      color: isError
                          ? Colors.redAccent
                          : filled
                              ? const Color(0xFF7C3AED)
                              : Colors.white.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),

            // Error text
            AnimatedOpacity(
              opacity: error != null ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  error ?? '',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Numpad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  for (final row in [['1','2','3'],['4','5','6'],['7','8','9'],['','0','⌫']])
                    Row(
                      children: row.map((k) {
                        if (k.isEmpty) return const Expanded(child: SizedBox.shrink());
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => k == '⌫' ? onDelete() : onDigit(k),
                            child: Container(
                              height: 64,
                              margin: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: k == '⌫'
                                    ? const Icon(Icons.backspace_outlined, color: Colors.white60, size: 22)
                                    : Text(k, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            TextButton(
              onPressed: onCancel,
              child: const Text('Cancel', style: TextStyle(color: Colors.white38, fontSize: 14)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
