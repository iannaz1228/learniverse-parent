import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/confirm_dialog.dart';
import 'parent_shop_provider.dart';

const _kEmojis = [
  '🎁', '🍕', '🍦', '🎮', '🎲', '📚', '🖊️', '🎨', '⚽', '🏀',
  '🎸', '🎤', '🎬', '🍫', '🍬', '🧁', '🍩', '🥤', '🎠', '🎡',
  '🌈', '⭐', '🏆', '🥇', '🎗️', '🎪', '🎭', '🎯', '🎳', '🎻',
];

class ParentShopScreen extends ConsumerWidget {
  const ParentShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewards = ref.watch(parentShopProvider);
    final pending = ref.watch(pendingRequestsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0A1E), Color(0xFF1A1040), Color(0xFF1A0A30)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text(
                  'Reward Shop',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  'Post rewards your child can buy with their coins',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.50),
                    fontSize: 13,
                  ),
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  children: [
                    // ── Pending requests ──────────────────────────────────
                    pending.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (requests) {
                        if (requests.isEmpty) return const SizedBox.shrink();
                        return _PendingSection(requests: requests);
                      },
                    ),

                    const SizedBox(height: 8),

                    // ── Rewards list ──────────────────────────────────────
                    rewards.when(
                      loading: () => const Center(
                          child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                            color: Color(0xFF7C3AED)),
                      )),
                      error: (e, _) => Center(
                          child: Text('Error: $e',
                              style: const TextStyle(color: Colors.white70))),
                      data: (list) => list.isEmpty
                          ? _EmptyRewards(
                              onAdd: () => _showRewardDialog(context, ref))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Your Rewards (${list.length})',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () =>
                                          _showRewardDialog(context, ref),
                                      icon: const Icon(Icons.add_rounded,
                                          size: 18),
                                      label: const Text('Add'),
                                      style: TextButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFF7C3AED)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...list.map((r) => _RewardCard(
                                      reward: r,
                                      onEdit: () => _showRewardDialog(
                                          context, ref,
                                          reward: r),
                                      onDelete: () =>
                                          _confirmDelete(context, ref, r),
                                      onToggle: (v) => ref
                                          .read(parentShopProvider.notifier)
                                          .toggleActive(r.id, active: v),
                                    )),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRewardDialog(context, ref),
        backgroundColor: const Color(0xFF7C3AED),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Reward'),
      ),
    );
  }

  void _showRewardDialog(BuildContext context, WidgetRef ref,
      {ParentReward? reward}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RewardFormSheet(reward: reward, ref: ref),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, ParentReward reward) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete Reward?',
      message: '"${reward.emoji} ${reward.name}" will be permanently removed.',
      confirmLabel: 'Delete',
      confirmColor: Colors.red,
      icon: Icons.delete_outline_rounded,
      iconColor: Colors.red,
    );
    if (!ok || !context.mounted) return;
    await ref.read(parentShopProvider.notifier).deleteReward(reward.id);
  }
}

// ── Pending requests section ──────────────────────────────────────────────────

class _PendingSection extends ConsumerWidget {
  const _PendingSection({required this.requests});
  final List<RewardRequest> requests;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.notifications_active_rounded, color: Colors.orange, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              'Pending Requests (${requests.length})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...requests.map((r) => _RequestCard(request: r)),
        const SizedBox(height: 20),
        Divider(color: Colors.white.withValues(alpha: 0.10)),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  const _RequestCard({required this.request});
  final RewardRequest request;

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _pending = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Text(r.rewardEmoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.rewardName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                Text(
                  '${r.childNickname}  •  ${r.coinPrice} coins',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12),
                ),
              ],
            ),
          ),
          if (_pending)
            const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.orange))
          else
            Row(
              children: [
                _ActionIconBtn(
                  icon: Icons.close_rounded,
                  color: Colors.red,
                  onTap: () => _resolve(approve: false),
                ),
                const SizedBox(width: 6),
                _ActionIconBtn(
                  icon: Icons.check_rounded,
                  color: const Color(0xFF10B981),
                  onTap: () => _resolve(approve: true),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _resolve({required bool approve}) async {
    final label = approve ? 'Approve' : 'Deny';
    final ok = await showConfirmDialog(
      context,
      title: '$label Request?',
      message: approve
          ? '${widget.request.coinPrice} coins will be deducted from ${widget.request.childNickname}.'
          : 'The request will be denied and no coins deducted.',
      confirmLabel: label,
      confirmColor: approve ? const Color(0xFF10B981) : Colors.red,
      icon: approve ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
      iconColor: approve ? const Color(0xFF10B981) : Colors.red,
    );
    if (!ok || !mounted) return;
    setState(() => _pending = true);
    final actions = ref.read(requestActionsProvider);
    if (approve) {
      await actions.approve(
          widget.request.id, widget.request.childId, widget.request.coinPrice);
    } else {
      await actions.deny(widget.request.id);
    }
    if (mounted) setState(() => _pending = false);
  }
}

class _ActionIconBtn extends StatelessWidget {
  const _ActionIconBtn(
      {required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.40)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

// ── Reward card ───────────────────────────────────────────────────────────────

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });
  final ParentReward reward;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: reward.isActive
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: reward.isActive
              ? const Color(0xFF7C3AED).withValues(alpha: 0.30)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          // Emoji
          Opacity(
            opacity: reward.isActive ? 1.0 : 0.40,
            child: Text(reward.emoji,
                style: const TextStyle(fontSize: 36)),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Opacity(
              opacity: reward.isActive ? 1.0 : 0.55,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (reward.description.isNotEmpty)
                    Text(
                      reward.description,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.50),
                          fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.monetization_on_rounded,
                          color: Color(0xFFEAB308), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${reward.coinPrice} coins',
                        style: const TextStyle(
                          color: Color(0xFFEAB308),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Controls
          Column(
            children: [
              Switch(
                value: reward.isActive,
                onChanged: onToggle,
                activeThumbColor: const Color(0xFF7C3AED),
                activeTrackColor: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: onEdit,
                    child: const Icon(Icons.edit_rounded,
                        color: Colors.white38, size: 18),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: onDelete,
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyRewards extends StatelessWidget {
  const _EmptyRewards({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
        child: Column(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Text('🎁',
                  style: TextStyle(fontSize: 44),
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 20),
            const Text(
              'No rewards yet',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Add rewards your child can buy with the coins they earn by learning.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.50), fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add First Reward'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reward form bottom sheet ──────────────────────────────────────────────────

class _RewardFormSheet extends ConsumerStatefulWidget {
  const _RewardFormSheet({this.reward, required this.ref});
  final ParentReward? reward;
  final WidgetRef ref;

  @override
  ConsumerState<_RewardFormSheet> createState() => _RewardFormSheetState();
}

class _RewardFormSheetState extends ConsumerState<_RewardFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late String _selectedEmoji;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.reward != null;

  @override
  void initState() {
    super.initState();
    final r = widget.reward;
    _nameCtrl = TextEditingController(text: r?.name ?? '');
    _descCtrl = TextEditingController(text: r?.description ?? '');
    _priceCtrl = TextEditingController(text: r != null ? '${r.coinPrice}' : '');
    _selectedEmoji = r?.emoji ?? '🎁';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_nameCtrl.text.trim().isEmpty) return 'Enter a reward name';
    if (_nameCtrl.text.trim().length < 2) return 'Name too short';
    final price = int.tryParse(_priceCtrl.text.trim());
    if (price == null || price < 1) return 'Enter a valid coin price (min 1)';
    if (price > 99999) return 'Price too high (max 99,999 coins)';
    return null;
  }

  Future<void> _save() async {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() { _saving = true; _error = null; });

    final notifier = ref.read(parentShopProvider.notifier);
    final price = int.parse(_priceCtrl.text.trim());

    String? result;
    if (_isEdit) {
      result = await notifier.updateReward(
        id: widget.reward!.id,
        name: _nameCtrl.text.trim(),
        emoji: _selectedEmoji,
        description: _descCtrl.text.trim(),
        coinPrice: price,
      );
    } else {
      result = await notifier.addReward(
        name: _nameCtrl.text.trim(),
        emoji: _selectedEmoji,
        description: _descCtrl.text.trim(),
        coinPrice: price,
      );
    }

    if (!mounted) return;
    if (result != null) {
      setState(() { _saving = false; _error = result; });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + bottom),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1060), Color(0xFF2D1B69)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            _isEdit ? 'Edit Reward' : 'Add Reward',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),

          // Error
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.redAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Emoji picker
          Text('Emoji',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65), fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _kEmojis.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final e = _kEmojis[i];
                final selected = e == _selectedEmoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF7C3AED).withValues(alpha: 0.30)
                          : Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF7C3AED)
                            : Colors.white.withValues(alpha: 0.12),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 22)),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Name
          TextFormField(
            controller: _nameCtrl,
            style: const TextStyle(color: Colors.white),
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Reward Name *',
              hintText: 'e.g. Movie Night, Extra Screen Time',
              prefixIcon: Icon(Icons.card_giftcard_rounded, color: Colors.white54),
            ),
          ),
          const SizedBox(height: 12),

          // Description
          TextFormField(
            controller: _descCtrl,
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'e.g. One hour of your favourite movie',
              prefixIcon: Icon(Icons.notes_rounded, color: Colors.white54),
            ),
          ),
          const SizedBox(height: 12),

          // Coin price
          TextFormField(
            controller: _priceCtrl,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Coin Price *',
              hintText: 'e.g. 50',
              prefixIcon: Icon(Icons.monetization_on_rounded, color: Color(0xFFEAB308)),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      _isEdit ? 'Save Changes' : 'Add Reward',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
