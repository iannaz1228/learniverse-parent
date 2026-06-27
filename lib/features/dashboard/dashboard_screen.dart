import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_bootstrap.dart';
import '../../routes/app_router.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../auth/auth_notifier.dart';
import '../child_link/link_provider.dart';
import '../inbox/inbox_provider.dart';
import '../wallet/wallet_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _setupRealtime();
  }

  void _setupRealtime() {
    final client = ref.read(supabaseClientProvider);
    final parentId = ref.read(authProvider.notifier).currentUserId;
    if (client != null && parentId != null) {
      ref.read(linkedChildrenProvider.notifier).subscribeRealtime(client, parentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = ref.watch(linkedChildrenProvider);
    final email = ref.read(authProvider.notifier).currentUserEmail ?? '';

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
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Parent Zone',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            email,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.50),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Inbox icon with unread badge
                    _InboxBadgeButton(),
                    IconButton(
                      icon: const Icon(Icons.settings_rounded, color: Colors.white70),
                      tooltip: 'Settings',
                      onPressed: () => context.push(AppRoutes.settings),
                    ),
                  ],
                ),
              ),

              // ── Announcements banner ──────────────────────────────────────
              const _AnnouncementsBanner(),

              // ── Body ────────────────────────────────────────────────────
              Expanded(
                child: children.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                  ),
                  error: (e, _) => Center(
                    child: Text('Error: $e',
                        style: const TextStyle(color: Colors.white70)),
                  ),
                  data: (kids) => kids.isEmpty
                      ? _EmptyState(onLink: () => context.push(AppRoutes.linkChild))
                      : _ChildList(children: kids),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.linkChild),
        backgroundColor: const Color(0xFF7C3AED),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Link Child'),
      ),
    );
  }
}

// ── Inbox badge button ─────────────────────────────────────────────────────────

class _InboxBadgeButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUnread = ref.watch(hasUnreadAdminMessagesProvider);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Inbox',
          onPressed: () => context.push(AppRoutes.inbox),
          icon: Image.asset(
            'assets/images/messageicon.png',
            width: 26, height: 26,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.inbox_rounded, color: Colors.white70, size: 26),
          ),
        ),
        if (hasUnread.value == true)
          Positioned(
            top: 8, right: 8,
            child: Container(
              width: 9, height: 9,
              decoration: const BoxDecoration(
                color: Color(0xFFEC4899),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Announcements banner ───────────────────────────────────────────────────────

class _AnnouncementsBanner extends StatefulWidget {
  const _AnnouncementsBanner();

  @override
  State<_AnnouncementsBanner> createState() => _AnnouncementsBannerState();
}

class _AnnouncementsBannerState extends State<_AnnouncementsBanner> {
  List<Map<String, dynamic>> _items = [];
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await Supabase.instance.client
          .from('announcements')
          .select('id, title, body')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(3);
      if (mounted) setState(() => _items = List<Map<String, dynamic>>.from(data));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed || _items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF1A2D50)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.campaign_rounded, color: Color(0xFF60A5FA), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_items.first['title'] as String? ?? '',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
              if (_items.first['body'] != null)
                Text(_items.first['body'] as String,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65), fontSize: 11, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _dismissed = true),
          child: Container(
            padding: const EdgeInsets.all(4),
            child: const Icon(Icons.close_rounded, color: Colors.white38, size: 16),
          ),
        ),
      ]),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onLink});
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.child_friendly_rounded,
                  color: Color(0xFF7C3AED), size: 50),
            ),
            const SizedBox(height: 24),
            const Text(
              'No children linked yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask your child to find their invite code in the child app under Settings → Link to Parent',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onLink,
              icon: const Icon(Icons.link_rounded),
              label: const Text('Link a Child'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Child list ─────────────────────────────────────────────────────────────────

class _ChildList extends ConsumerWidget {
  const _ChildList({required this.children});
  final List<LinkedChild> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: children.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _ChildCard(child: children[i]),
    );
  }
}

class _ChildCard extends ConsumerWidget {
  const _ChildCard({required this.child});
  final LinkedChild child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocked = child.isLocked;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLocked
              ? [const Color(0xFF3B1A1A), const Color(0xFF2D0F0F)]
              : [const Color(0xFF1E1060), const Color(0xFF2D1B69)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLocked
              ? Colors.red.withValues(alpha: 0.40)
              : const Color(0xFF7C3AED).withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: (isLocked ? Colors.red : const Color(0xFF7C3AED))
                .withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: avatar + name + lock toggle ──
            Row(
              children: [
                _Avatar(child: child),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              child.nickname,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (isLocked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.50)),
                              ),
                              child: const Text(
                                'LOCKED',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _StatChip(
                              icon: Icons.star_rounded,
                              value: 'Lv ${child.level}',
                              color: Colors.amber),
                          const SizedBox(width: 8),
                          _StatChip(
                              icon: Icons.local_fire_department_rounded,
                              value: '${child.streakCurrent}d',
                              color: const Color(0xFFF97316)),
                          const SizedBox(width: 8),
                          _StatChip(
                              icon: Icons.monetization_on_rounded,
                              value: '${child.coins}',
                              color: const Color(0xFFEAB308)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 14),

            // ── Action buttons row 1 ──
            Row(
              children: [
                _ActionBtn(
                  icon: Icons.bar_chart_rounded,
                  label: 'Activity',
                  onTap: () => context.push(AppRoutes.activity, extra: child.id),
                ),
                const SizedBox(width: 8),
                _ActionBtn(
                  icon: Icons.school_rounded,
                  label: 'Progress',
                  onTap: () => context.push(AppRoutes.progress, extra: child.id),
                ),
                const SizedBox(width: 8),
                _ActionBtn(
                  icon: Icons.timer_rounded,
                  label: 'Screen Time',
                  onTap: () => context.push(AppRoutes.screenTime, extra: child.id),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // ── Action buttons row 2 ──
            Row(
              children: [
                _ActionBtn(
                  icon: Icons.card_giftcard_rounded,
                  label: 'Gift Coins',
                  color: const Color(0xFFF59E0B),
                  onTap: () => _showGiftSheet(context, ref, child),
                ),
                const SizedBox(width: 8),
                _ActionBtn(
                  icon: Icons.favorite_rounded,
                  label: 'Message',
                  color: const Color(0xFFEC4899),
                  onTap: () => _showMessageDialog(context, ref, child),
                ),
                const SizedBox(width: 8),
                _ActionBtn(
                  icon: Icons.tune_rounded,
                  label: 'Modules',
                  color: const Color(0xFF10B981),
                  onTap: () => _showModulesSheet(context, ref, child),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Lock / Unlock button ──
            SizedBox(
              width: double.infinity,
              child: _LockButton(child: child),
            ),
          ],
        ),
      ),
    );
  }
}

  void _showGiftSheet(BuildContext context, WidgetRef ref, LinkedChild child) {
    final parentCoins = ref.read(parentWalletProvider).value ?? 0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GiftSheet(child: child, parentCoins: parentCoins),
    );
  }

  void _showMessageDialog(BuildContext context, WidgetRef ref, LinkedChild child) {
    showDialog(
      context: context,
      builder: (_) => _MessageDialog(child: child),
    );
  }

  void _showModulesSheet(BuildContext context, WidgetRef ref, LinkedChild child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModulesSheet(child: child),
    );
  }

class _LockButton extends ConsumerStatefulWidget {
  const _LockButton({required this.child});
  final LinkedChild child;

  @override
  ConsumerState<_LockButton> createState() => _LockButtonState();
}

class _LockButtonState extends ConsumerState<_LockButton> {
  bool _pending = false;

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.child.isLocked;
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isLocked
            ? const Color(0xFF16A34A)
            : const Color(0xFFB91C1C),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _pending
          ? null
          : () async {
              final ok = await showConfirmDialog(
                context,
                title: isLocked ? 'Unlock App?' : 'Lock App?',
                message: isLocked
                    ? '${widget.child.nickname} will be able to use the app again.'
                    : '${widget.child.nickname} will be locked out of the app immediately.',
                confirmLabel: isLocked ? 'Unlock' : 'Lock',
                confirmColor: isLocked ? const Color(0xFF16A34A) : const Color(0xFFB91C1C),
                icon: isLocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                iconColor: isLocked ? const Color(0xFF16A34A) : const Color(0xFFB91C1C),
              );
              if (!ok || !mounted) return;
              setState(() => _pending = true);
              await ref
                  .read(linkedChildrenProvider.notifier)
                  .setLocked(widget.child.id, locked: !isLocked);
              if (mounted) setState(() => _pending = false);
            },
      icon: _pending
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Icon(isLocked ? Icons.lock_open_rounded : Icons.lock_rounded),
      label: Text(
        isLocked ? 'Unlock App' : 'Lock App',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }
}

const _kAvatarEmojis = {
  'fox_01': '🦊',
  'bear_01': '🐻',
  'bunny_01': '🐰',
  'cat_01': '🐱',
  'dino_01': '🦕',
  'owl_01': '🦉',
};

class _Avatar extends StatelessWidget {
  const _Avatar({required this.child});
  final LinkedChild child;

  @override
  Widget build(BuildContext context) {
    final url = child.avatarUrl;
    if (url != null && url.startsWith('http')) {
      return CircleAvatar(
        radius: 30,
        backgroundImage: NetworkImage(url),
      );
    }
    final emoji = (url != null ? _kAvatarEmojis[url] : null) ??
        (child.avatarId.isNotEmpty ? _kAvatarEmojis[child.avatarId] : null);
    if (emoji != null) {
      return CircleAvatar(
        radius: 30,
        backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.30),
        child: Text(emoji, style: const TextStyle(fontSize: 26)),
      );
    }
    return CircleAvatar(
      radius: 30,
      backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.30),
      child: Text(
        child.nickname.isNotEmpty ? child.nickname[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.icon, required this.value, required this.color});
  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white70;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color != null
                ? color!.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color != null
                  ? color!.withValues(alpha: 0.30)
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: c, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: c,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    final walletCoins = ref.watch(parentWalletProvider).value ?? widget.parentCoins;
    final canAfford = walletCoins >= _amount && _amount > 0;

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
            Text('Your wallet: $walletCoins coins',
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 18),
            // Presets
            Wrap(
              spacing: 10,
              children: [10, 25, 50, 100].map((amt) {
                final sel = _amount == amt;
                return GestureDetector(
                  onTap: () => setState(() => _amount = amt),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFFF59E0B) : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sel ? const Color(0xFFF59E0B) : Colors.white12),
                    ),
                    child: Text('$amt',
                        style: TextStyle(
                            color: sel ? Colors.white : Colors.white60,
                            fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                );
              }).toList(),
            ),
            if (!canAfford && walletCoins < _amount) ...[
              const SizedBox(height: 10),
              const Text('Not enough coins in your wallet',
                  style: TextStyle(color: Colors.redAccent, fontSize: 12)),
            ],
            const SizedBox(height: 18),
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
                label: Text(_loading ? 'Sending…' : 'Gift $_amount Coins',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
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
          ? '$_amount coins sent to ${widget.child.nickname}! 🎁'
          : 'Error: $err'),
      backgroundColor: err == null ? const Color(0xFF059669) : Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}

// ── Encouragement message dialog ──────────────────────────────────────────────

class _MessageDialog extends ConsumerStatefulWidget {
  const _MessageDialog({required this.child});
  final LinkedChild child;

  @override
  ConsumerState<_MessageDialog> createState() => _MessageDialogState();
}

class _MessageDialogState extends ConsumerState<_MessageDialog> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1040),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Text('💌', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Message to ${widget.child.nickname}',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'This message will pop up the next time your child opens the app.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            maxLength: 120,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Great job today! Keep learning! 🌟',
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.07),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEC4899))),
              counterStyle: const TextStyle(color: Colors.white38),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEC4899),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: _sending
              ? const SizedBox(width: 14, height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send_rounded, size: 16),
          label: const Text('Send', style: TextStyle(fontWeight: FontWeight.w700)),
          onPressed: _sending || _ctrl.text.trim().isEmpty ? null : _send,
        ),
      ],
    );
  }

  Future<void> _send() async {
    final msg = _ctrl.text.trim();
    if (msg.isEmpty) return;
    setState(() => _sending = true);
    final client = ref.read(supabaseClientProvider);
    try {
      await client?.from('profiles')
          .update({'encouragement_message': msg})
          .eq('id', widget.child.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Message sent! 💌'),
          backgroundColor: Color(0xFFEC4899),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) setState(() => _sending = false);
    }
  }
}

// ── Module controls bottom sheet ──────────────────────────────────────────────

const _kModules = [
  ('abc',     '🔤', 'ABC Adventures'),
  ('math',    '🔢', 'Math Magic'),
  ('art',     '🎨', 'Art Explorers'),
  ('science', '🔬', 'Science Stars'),
  ('music',   '🎵', 'Music & Songs'),
  ('story',   '📖', 'Story Time'),
  ('puzzle',  '🧩', 'Jigsaw Puzzle'),
];

class _ModulesSheet extends ConsumerStatefulWidget {
  const _ModulesSheet({required this.child});
  final LinkedChild child;

  @override
  ConsumerState<_ModulesSheet> createState() => _ModulesSheetState();
}

class _ModulesSheetState extends ConsumerState<_ModulesSheet> {
  Map<String, bool> _controls = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fetchControls();
  }

  Future<void> _fetchControls() async {
    final client = ref.read(supabaseClientProvider);
    try {
      final data = await client
          ?.from('profiles')
          .select('module_controls')
          .eq('id', widget.child.id)
          .maybeSingle();
      final raw = data?['module_controls'] as Map<String, dynamic>? ?? {};
      if (mounted) {
        setState(() {
          _controls = {
            for (final m in _kModules)
              m.$1: raw[m.$1] as bool? ?? true,
          };
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final client = ref.read(supabaseClientProvider);
    try {
      await client?.from('profiles')
          .update({'module_controls': _controls})
          .eq('id', widget.child.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Module settings saved!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1040),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(
            color: Colors.white24, borderRadius: BorderRadius.circular(2),
          )),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: Color(0xFF10B981), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Modules for ${widget.child.nickname}',
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Toggle which learning modules your child can access.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            )
          else
            ...(_kModules.map((m) => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '${m.$2}  ${m.$3}',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              value: _controls[m.$1] ?? true,
              activeThumbColor: const Color(0xFF10B981),
              onChanged: (v) => setState(() => _controls[m.$1] = v),
            ))),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
