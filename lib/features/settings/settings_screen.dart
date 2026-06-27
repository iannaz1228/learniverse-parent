import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/supabase_bootstrap.dart';
import '../../routes/app_router.dart';
import '../auth/auth_notifier.dart';
import '../wallet/wallet_pin.dart';
import 'update_service.dart';
import 'update_dialog.dart';

// ── Colors ────────────────────────────────────────────────────────────────────

const _purple  = Color(0xFF7C3AED);
const _amber   = Color(0xFFF5A623);
const _card    = Color(0xFF1A1040);
const _surface = Color(0xFF120C30);
const _textSub = Color(0xFF9CA3AF);

// ── Settings Screen ───────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.read(supabaseClientProvider);
    final email  = client?.auth.currentUser?.email ?? '';
    final userId = client?.auth.currentUser?.id;

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
              // ── AppBar ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70),
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: Text('Settings',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  ),
                ]),
              ),

              // ── Body ──────────────────────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
                  children: [
                    // ── Account card ─────────────────────────────────────
                    _AccountCard(email: email),
                    const SizedBox(height: 24),

                    // ── App section ───────────────────────────────────────
                    const _SectionLabel('APP'),
                    _SettingsGroup(children: [
                      _GroupTile(
                        icon: Icons.info_outline_rounded,
                        label: 'About LearniVerse',
                        subtitle: 'Features, version & more',
                        color: _purple,
                        onTap: () => _showAbout(context),
                      ),
                      const _CheckUpdateTile(),
                      const _WalletPinTile(),
                    ]),

                    const SizedBox(height: 24),

                    // ── Support section ───────────────────────────────────
                    const _SectionLabel('SUPPORT'),
                    _SettingsGroup(children: [
                      _GroupTile(
                        icon: Icons.local_cafe_rounded,
                        label: 'Buy Me a Coffee',
                        subtitle: 'Support the developer ☕',
                        color: _amber,
                        onTap: () => _showBuyMeCoffee(context),
                      ),
                      _GroupTile(
                        icon: Icons.feedback_outlined,
                        label: 'Feedback & Bug Report',
                        subtitle: 'Report issues or share ideas',
                        color: const Color(0xFF10B981),
                        onTap: () => _showFeedback(context),
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // ── Inbox ─────────────────────────────────────────────
                    const _SectionLabel('MESSAGES'),
                    _SettingsGroup(children: [
                      _GroupTile(
                        icon: Icons.inbox_rounded,
                        label: 'Inbox',
                        subtitle: 'Messages & replies from admin',
                        color: const Color(0xFF3B82F6),
                        onTap: () => context.push(AppRoutes.inbox),
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // ── Admin Panel (role == 'admin' only) ────────────────
                    _AdminSection(userId: userId),

                    // ── Account ───────────────────────────────────────────
                    const _SectionLabel('ACCOUNT'),
                    _SettingsGroup(children: [
                      _GroupTile(
                        icon: Icons.logout_rounded,
                        label: 'Sign Out',
                        subtitle: 'Sign out of your parent account',
                        color: Colors.redAccent,
                        onTap: () => _signOut(context, ref),
                      ),
                    ]),

                    const SizedBox(height: 32),

                    // ── Developer card ────────────────────────────────────
                    const _DeveloperCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AboutSheet(),
    );
  }

  void _showBuyMeCoffee(BuildContext context) => showBuyMeCoffeeSheet(context);

  void _showFeedback(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FeedbackSheet(),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: const Text('You will be signed out of your parent account.',
            style: TextStyle(color: _textSub, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authProvider.notifier).signOut();
  }
}

// ── Admin section (only shown for admin role) ─────────────────────────────────

class _AdminSection extends StatefulWidget {
  final String? userId;
  const _AdminSection({this.userId});

  @override
  State<_AdminSection> createState() => _AdminSectionState();
}

class _AdminSectionState extends State<_AdminSection> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    if (widget.userId == null) return;
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', widget.userId!)
          .maybeSingle();
      if (mounted && data != null && data['role'] == 'admin') {
        setState(() => _isAdmin = true);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('ADMIN PANEL'),
        _SettingsGroup(children: [
          _GroupTile(
            icon: Icons.campaign_rounded,
            label: 'Post Announcement',
            subtitle: 'Visible to all parents in the app',
            color: const Color(0xFFF59E0B),
            onTap: () => _showPostAnnouncement(context),
          ),
          _GroupTile(
            icon: Icons.feedback_rounded,
            label: 'Parent Feedback Inbox',
            subtitle: 'Read & reply to bug reports / feedback',
            color: const Color(0xFFEC4899),
            onTap: () => _showAdminFeedbackInbox(context),
          ),
          _GroupTile(
            icon: Icons.message_rounded,
            label: 'Message a Parent',
            subtitle: 'Send a message to a specific parent',
            color: const Color(0xFF3B82F6),
            onTap: () => _showAdminMessageDialog(context),
          ),
        ]),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showPostAnnouncement(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PostAnnouncementSheet(),
    );
  }

  void _showAdminFeedbackInbox(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AdminFeedbackInboxSheet(),
    );
  }

  void _showAdminMessageDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AdminMessageSheet(),
    );
  }
}

// ── Account card ──────────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  final String email;
  const _AccountCard({required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_purple.withValues(alpha: 0.30), _card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _purple.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: _purple.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_rounded, color: Colors.white70, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Parent Account',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(email,
                style: const TextStyle(color: _textSub, fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      ]),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _textSub,
              letterSpacing: 1.2),
        ),
      );
}

// ── Settings group ────────────────────────────────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1)
                Divider(height: 1, thickness: 1,
                    color: Colors.white.withValues(alpha: 0.07),
                    indent: 54, endIndent: 0),
            ],
          ],
        ),
      );
}

// ── Group tile ────────────────────────────────────────────────────────────────

class _GroupTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _GroupTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
        subtitle: subtitle != null
            ? Text(subtitle!, style: const TextStyle(fontSize: 12, color: _textSub))
            : null,
        trailing: trailing ??
            (onTap != null
                ? const Icon(Icons.chevron_right_rounded, size: 18, color: _textSub)
                : null),
        onTap: onTap,
      );
}

// ── Check Update tile ─────────────────────────────────────────────────────────

class _CheckUpdateTile extends StatefulWidget {
  const _CheckUpdateTile();

  @override
  State<_CheckUpdateTile> createState() => _CheckUpdateTileState();
}

class _CheckUpdateTileState extends State<_CheckUpdateTile> {
  bool _checking = false;

  Future<void> _check() async {
    if (_checking) return;
    setState(() => _checking = true);
    final info = await UpdateService.checkForUpdate(app: 'parent');
    if (!mounted) return;
    setState(() => _checking = false);
    if (info != null) {
      showDialog<void>(
        context: context,
        barrierDismissible: !info.isForce,
        builder: (_) => UpdateDialog(info: info),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You're up to date!"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (_, snap) {
        final version = snap.hasData
            ? '${snap.data!.version} (Build ${snap.data!.buildNumber})'
            : '…';
        return _GroupTile(
          icon: Icons.system_update_rounded,
          label: 'Check for Updates',
          subtitle: 'Current: $version',
          color: _purple,
          trailing: _checking
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _purple))
              : null,
          onTap: _check,
        );
      },
    );
  }
}

// ── Wallet PIN tile ───────────────────────────────────────────────────────────

class _WalletPinTile extends StatefulWidget {
  const _WalletPinTile();

  @override
  State<_WalletPinTile> createState() => _WalletPinTileState();
}

class _WalletPinTileState extends State<_WalletPinTile> {
  bool _pinSet = false;

  @override
  void initState() {
    super.initState();
    _checkPin();
  }

  Future<void> _checkPin() async {
    final set = await WalletPin.isSet();
    if (mounted) setState(() => _pinSet = set);
  }

  void _manage() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PinManageSheet(
        pinSet: _pinSet,
        onChanged: _checkPin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _GroupTile(
      icon: Icons.pin_rounded,
      label: 'Wallet PIN',
      subtitle: _pinSet ? 'PIN is set — tap to change or remove' : 'Set a PIN to protect coin top-ups',
      color: const Color(0xFF10B981),
      trailing: _pinSet
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('ON', style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.w800)),
            )
          : null,
      onTap: _manage,
    );
  }
}

class _PinManageSheet extends StatelessWidget {
  const _PinManageSheet({required this.pinSet, required this.onChanged});
  final bool pinSet;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1040),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Icon(Icons.pin_rounded, color: Color(0xFF10B981), size: 36),
          const SizedBox(height: 12),
          Text(
            pinSet ? 'Wallet PIN' : 'Set Wallet PIN',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            pinSet ? 'Your wallet is PIN-protected.' : 'Protect coin top-ups with a 4-digit PIN.',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await Future.delayed(const Duration(milliseconds: 300));
                if (!context.mounted) return;
                final result = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const _SetPinFromSettingsSheet(),
                );
                if (result == true) onChanged();
              },
              icon: Icon(pinSet ? Icons.edit_rounded : Icons.lock_rounded, size: 18),
              label: Text(pinSet ? 'Change PIN' : 'Set PIN',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          if (pinSet) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await WalletPin.clear();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  onChanged();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Wallet PIN removed'),
                    behavior: SnackBarBehavior.floating,
                  ));
                },
                icon: const Icon(Icons.lock_open_rounded, size: 16),
                label: const Text('Remove PIN', style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SetPinFromSettingsSheet extends StatefulWidget {
  const _SetPinFromSettingsSheet();

  @override
  State<_SetPinFromSettingsSheet> createState() => _SetPinFromSettingsSheetState();
}

class _SetPinFromSettingsSheetState extends State<_SetPinFromSettingsSheet> {
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
    return _PinSheetWrapperSettings(
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

class _PinSheetWrapperSettings extends StatelessWidget {
  const _PinSheetWrapperSettings({
    required this.title,
    required this.subtitle,
    required this.pin,
    required this.error,
    required this.onDigit,
    required this.onDelete,
    required this.onCancel,
  });

  final String title, subtitle, pin;
  final String? error;
  final void Function(String) onDigit;
  final VoidCallback onDelete, onCancel;

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
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 24),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.40)),
              ),
              child: const Icon(Icons.pin_rounded, color: Color(0xFF10B981), size: 28),
            ),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 28),
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
                        : filled ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.15),
                    border: Border.all(
                      color: isError
                          ? Colors.redAccent
                          : filled ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),
            AnimatedOpacity(
              opacity: error != null ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(error ?? '', style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 28),
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

// ── Developer card ────────────────────────────────────────────────────────────

class _DeveloperCard extends StatelessWidget {
  const _DeveloperCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_purple.withValues(alpha: 0.30), _card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _purple.withValues(alpha: 0.22)),
      ),
      child: Column(children: [
        Image.asset('assets/images/app-logo.png', height: 54,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.school_rounded, size: 54, color: Color(0xFFAB8FE8))),
        const SizedBox(height: 12),
        const Text('LearniVerse',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 4),
        const Text('PARENT ZONE',
            style: TextStyle(fontSize: 11, color: _amber, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
        const SizedBox(height: 18),
        Container(height: 1, color: Colors.white.withValues(alpha: 0.07)),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _purple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.code_rounded, size: 16, color: Color(0xFFAB8FE8)),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Developed by',
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.45))),
            const Text('IanNaz',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
          ]),
        ]),
        const SizedBox(height: 14),
        Text(
          'Built with love for Filipino families.\nHelping children learn every day.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.42), height: 1.55),
        ),
      ]),
    );
  }
}

// ── About sheet ───────────────────────────────────────────────────────────────

class _AboutSheet extends StatelessWidget {
  const _AboutSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
              children: [
                Row(children: [
                  Image.asset('assets/images/app-logo.png', height: 44,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.school_rounded, size: 44, color: Color(0xFFAB8FE8))),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('LearniVerse',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (_, snap) => Text(
                        snap.hasData ? 'v${snap.data!.version}' : 'v1.0.0',
                        style: const TextStyle(fontSize: 12, color: _textSub),
                      ),
                    ),
                  ]),
                ]),
                const SizedBox(height: 14),
                Text(
                  'LearniVerse is a gamified learning platform for young children (ages 3–8). Parents monitor progress, control screen time, and reward their kids with coins while children learn through fun adventures.',
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.68), height: 1.55),
                ),
                const SizedBox(height: 22),
                const Text('Parent Features',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 14),
                const _FeatureTile(
                  icon: Icons.child_friendly_rounded,
                  color: _purple,
                  title: 'Child Dashboard',
                  desc: 'Monitor all your linked children — see their XP, coins, level, streak, and recent activity at a glance.',
                ),
                const _FeatureTile(
                  icon: Icons.timer_rounded,
                  color: Color(0xFFF59E0B),
                  title: 'Screen Time Control',
                  desc: 'Set daily learning time limits per child. The app locks automatically when the limit is reached.',
                ),
                const _FeatureTile(
                  icon: Icons.card_giftcard_rounded,
                  color: Color(0xFFEC4899),
                  title: 'Reward Shop',
                  desc: 'Post custom rewards (toys, snacks, screen time) that your child can request using their earned LearniVerse coins.',
                ),
                const _FeatureTile(
                  icon: Icons.account_balance_wallet_rounded,
                  color: Color(0xFF10B981),
                  title: 'Coin Wallet',
                  desc: 'Manage your parent wallet and gift coins to your children as motivation for learning milestones.',
                ),
                const _FeatureTile(
                  icon: Icons.storefront_rounded,
                  color: Color(0xFF3B82F6),
                  title: 'Content Store',
                  desc: 'Browse and unlock premium learning content — stories, modules, and activities — for your children.',
                ),
                const _FeatureTile(
                  icon: Icons.bar_chart_rounded,
                  color: Color(0xFFF97316),
                  title: 'Progress Reports',
                  desc: 'View detailed learning progress per child — completed modules, quiz scores, streaks, and improvement over time.',
                ),
                const SizedBox(height: 8),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.07)),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.code_rounded, size: 14, color: Color(0xFFAB8FE8)),
                  const SizedBox(width: 6),
                  Text('Developed by Ian Naz',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.6))),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;

  const _FeatureTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 3),
              Text(desc,
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.58), height: 1.45)),
            ]),
          ),
        ]),
      );
}

// ── Buy Me a Coffee sheet ─────────────────────────────────────────────────────

void showBuyMeCoffeeSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _BuyMeCoffeeSheet(),
  );
}

class _BuyMeCoffeeSheet extends StatelessWidget {
  const _BuyMeCoffeeSheet();

  static const _methods = [
    _PayMethod(
      name: 'GCash',
      icon: Icons.account_balance_wallet_rounded,
      iconColor: Color(0xFF007DFF),
      color: Color(0xFF007DFF),
      details: [('Name', 'Ian Naz'), ('Number', '09105673778')],
      imagePath: 'assets/images/gcash.png',
    ),
    _PayMethod(
      name: 'PayPal',
      icon: Icons.payment_rounded,
      iconColor: Color(0xFF003087),
      color: Color(0xFF003087),
      details: [('Email', 'iannaz1228@gmail.com')],
      link: 'https://paypal.me/iannaz1997',
      imagePath: 'assets/images/paypal.png',
    ),
    _PayMethod(
      name: 'Maya',
      icon: Icons.phone_android_rounded,
      iconColor: Color(0xFF00A859),
      color: Color(0xFF00A859),
      details: [('Name', 'Ian Naz'), ('Number', '09915527842')],
      imagePath: 'assets/images/maya.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.80,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F1123),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: ctrl,
          padding: EdgeInsets.fromLTRB(20, 0, 20, 32 + MediaQuery.of(context).viewInsets.bottom),
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_amber.withValues(alpha: 0.18), _amber.withValues(alpha: 0.06)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _amber.withValues(alpha: 0.35)),
              ),
              child: Row(children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _amber.withValues(alpha: 0.2),
                    border: Border.all(color: _amber.withValues(alpha: 0.5), width: 2),
                  ),
                  child: const Center(child: Text('☕', style: TextStyle(fontSize: 26))),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Buy Me a Coffee',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
                    SizedBox(height: 2),
                    Text('by Ian Magistrado Naz',
                        style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
            ),

            const SizedBox(height: 12),

            // Thank you message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('💛', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'If LearniVerse helped your child learn and grow, a small coffee tip keeps this project alive. Your support means the world! 💛',
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7), height: 1.5),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 20),

            // Payment methods
            for (final method in _methods) ...[
              _MethodCard(method: method),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 4),
            const Center(
              child: Text('Every coffee helps! Salamat! ☕',
                  style: TextStyle(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.w600)),
            ),

            const SizedBox(height: 20),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.07)),
            const SizedBox(height: 16),

            // Leave a thank-you note
            const _CoffeeMessageForm(),
          ],
        ),
      ),
    );
  }
}

class _PayMethod {
  final String name;
  final IconData icon;
  final Color iconColor;
  final Color color;
  final List<(String, String)> details;
  final String link;
  final String imagePath;

  const _PayMethod({
    required this.name,
    required this.icon,
    required this.iconColor,
    required this.color,
    required this.details,
    this.link = '',
    this.imagePath = '',
  });
}

class _MethodCard extends StatelessWidget {
  final _PayMethod method;
  const _MethodCard({required this.method});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: method.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: method.color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Try image, fall back to icon
          SizedBox(
            width: 32, height: 32,
            child: Image.asset(
              method.imagePath,
              width: 32, height: 32, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: method.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(method.icon, color: method.iconColor, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(method.name,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: method.color)),
        ]),
        const SizedBox(height: 10),
        for (final (label, value) in method.details) ...[
          _CopyRow(label: label, value: value, color: method.color),
          const SizedBox(height: 6),
        ],
        if (method.link.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(method.link);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 16, color: Colors.white),
              label: const Text('Open PayPal',
                  style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: method.color,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

class _CopyRow extends StatefulWidget {
  final String label, value;
  final Color color;
  const _CopyRow({required this.label, required this.value, required this.color});

  @override
  State<_CopyRow> createState() => _CopyRowState();
}

class _CopyRowState extends State<_CopyRow> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.label.toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.4), letterSpacing: 0.8)),
              const SizedBox(height: 2),
              Text(widget.value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            ]),
          ),
          GestureDetector(
            onTap: _copy,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _copied
                    ? Colors.green.withValues(alpha: 0.15)
                    : widget.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _copied ? Icons.check_rounded : Icons.copy_rounded,
                size: 14,
                color: _copied ? Colors.green : widget.color,
              ),
            ),
          ),
        ]),
      );
}

// ── Coffee message form ───────────────────────────────────────────────────────

class _CoffeeMessageForm extends ConsumerStatefulWidget {
  const _CoffeeMessageForm();

  @override
  ConsumerState<_CoffeeMessageForm> createState() => _CoffeeMessageFormState();
}

class _CoffeeMessageFormState extends ConsumerState<_CoffeeMessageForm> {
  final _msgCtrl  = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _sending    = false;
  bool _sent       = false;
  bool _showOnWall = true;
  String? _error;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final msg  = _msgCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    if (msg.isEmpty) { setState(() => _error = 'Write a short message first.'); return; }
    setState(() { _sending = true; _error = null; });
    final client = ref.read(supabaseClientProvider);
    final user = client?.auth.currentUser;
    try {
      await Supabase.instance.client.from('coffee_messages').insert({
        'user_id':      user?.id,
        'user_email':   user?.email ?? '',
        'message':      msg,
        'display_name': name.isEmpty ? 'Anonymous' : name,
        'show_on_wall': _showOnWall,
      });
      if (mounted) setState(() { _sending = false; _sent = true; });
    } catch (e) {
      if (mounted) setState(() { _sending = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: const Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
          SizedBox(width: 10),
          Expanded(child: Text(
            "Thank-you note sent! 💛 We'll reply in your inbox.",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          )),
        ]),
      );
    }

    final _inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Leave a Thank-You Note',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
      const SizedBox(height: 4),
      Text("After donating, drop us a message — we'll reply!",
          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.45))),
      const SizedBox(height: 10),

      // Name field
      TextField(
        controller: _nameCtrl,
        maxLength: 40,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Your name or nickname (optional)',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
          filled: true,
          fillColor: _surface,
          counterStyle: const TextStyle(color: _textSub, fontSize: 10),
          border: _inputBorder,
          enabledBorder: _inputBorder,
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _amber)),
        ),
      ),
      const SizedBox(height: 8),

      // Message field
      TextField(
        controller: _msgCtrl,
        maxLines: 3,
        maxLength: 300,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        onChanged: (_) { if (_error != null) setState(() => _error = null); },
        decoration: InputDecoration(
          hintText: 'Thank you for LearniVerse! My kids love it ☕',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
          filled: true,
          fillColor: _surface,
          counterStyle: const TextStyle(color: _textSub, fontSize: 10),
          border: _inputBorder,
          enabledBorder: _inputBorder,
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _amber)),
        ),
      ),

      // Show on wall toggle
      GestureDetector(
        onTap: () => setState(() => _showOnWall = !_showOnWall),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _showOnWall
                ? const Color(0xFFF5A623).withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _showOnWall
                  ? const Color(0xFFF5A623).withValues(alpha: 0.40)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _showOnWall ? Icons.public_rounded : Icons.public_off_rounded,
                color: _showOnWall ? _amber : Colors.white38,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _showOnWall
                      ? 'Show my name on the Supporters Wall 🌟'
                      : 'Keep my message private',
                  style: TextStyle(
                    color: _showOnWall ? Colors.white : Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: _showOnWall,
                onChanged: (v) => setState(() => _showOnWall = v),
                activeColor: _amber,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),

      if (_error != null) ...[
        const SizedBox(height: 6),
        Text(_error!, style: const TextStyle(fontSize: 11, color: Colors.red)),
      ],
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _sending ? null : _submit,
          icon: _sending
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send_rounded, size: 16),
          label: Text(_sending ? 'Sending…' : 'Send Note',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _amber,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ]);
  }
}

// ── Feedback sheet ────────────────────────────────────────────────────────────

class _FeedbackSheet extends ConsumerStatefulWidget {
  const _FeedbackSheet();

  @override
  ConsumerState<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends ConsumerState<_FeedbackSheet> {
  final _msgCtrl = TextEditingController();
  String _category = 'general';
  bool _sending = false;
  bool _sent = false;
  String? _error;

  static const _cats = [
    ('bug',        Icons.bug_report_rounded,          'Bug Report', Colors.red),
    ('suggestion', Icons.lightbulb_rounded,            'Idea',       Color(0xFFF59E0B)),
    ('general',    Icons.chat_bubble_outline_rounded,  'General',    Color(0xFF3B82F6)),
  ];

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Color _catColor(String id) {
    for (final c in _cats) {
      if (c.$1 == id) return c.$4;
    }
    return const Color(0xFF3B82F6);
  }

  Future<void> _submit() async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty) {
      setState(() => _error = 'Please write a message.');
      return;
    }
    setState(() { _sending = true; _error = null; });
    final client  = ref.read(supabaseClientProvider);
    final authUser = client?.auth.currentUser;
    try {
      await Supabase.instance.client.from('parent_feedback').insert({
        'user_id':    authUser?.id,
        'user_email': authUser?.email ?? '',
        'category':   _category,
        'message':    msg,
      });
      if (mounted) setState(() { _sending = false; _sent = true; });
    } catch (e) {
      if (mounted) setState(() { _sending = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          Expanded(
            child: _sent ? _buildSuccess() : ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                const Row(children: [
                  Icon(Icons.feedback_rounded, color: Color(0xFF10B981), size: 22),
                  SizedBox(width: 10),
                  Text('Feedback & Bug Report',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                ]),
                const SizedBox(height: 4),
                Text('Report a bug or share an idea.',
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
                const SizedBox(height: 20),

                // Category
                const Text('Category',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70)),
                const SizedBox(height: 8),
                Row(
                  children: _cats.asMap().entries.map((entry) {
                    final i = entry.key;
                    final cat = entry.value;
                    final sel = _category == cat.$1;
                    final clr = cat.$4;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() { _category = cat.$1; _error = null; }),
                        child: Container(
                          margin: EdgeInsets.only(right: i < _cats.length - 1 ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: sel ? clr.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: sel ? clr.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08),
                              width: sel ? 1.5 : 1,
                            ),
                          ),
                          child: Column(children: [
                            Icon(cat.$2, size: 18, color: sel ? clr : Colors.white38),
                            const SizedBox(height: 3),
                            Text(cat.$3, style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w700,
                                color: sel ? clr : Colors.white38)),
                          ]),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Message
                const Text('Message',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70)),
                const SizedBox(height: 8),
                TextField(
                  controller: _msgCtrl,
                  maxLines: 5,
                  maxLength: 500,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  onChanged: (_) { if (_error != null) setState(() => _error = null); },
                  decoration: InputDecoration(
                    hintText: 'Describe the issue or your idea…',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
                    filled: true,
                    fillColor: _surface,
                    counterStyle: const TextStyle(color: _textSub, fontSize: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF10B981))),
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!,
                          style: const TextStyle(fontSize: 12, color: Colors.red, height: 1.4))),
                    ]),
                  ),
                ],
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _catColor(_category),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _sending
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Send Feedback',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildSuccess() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 64),
            const SizedBox(height: 16),
            const Text('Feedback Sent!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Thank you for helping improve LearniVerse.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.55), height: 1.4)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
      );
}

// ── Admin: Post Announcement sheet ────────────────────────────────────────────

class _PostAnnouncementSheet extends StatefulWidget {
  const _PostAnnouncementSheet();

  @override
  State<_PostAnnouncementSheet> createState() => _PostAnnouncementSheetState();
}

class _PostAnnouncementSheetState extends State<_PostAnnouncementSheet> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl  = TextEditingController();
  bool _sending = false;
  bool _sent    = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final body  = _bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) {
      setState(() => _error = 'Title and message are required.');
      return;
    }
    setState(() { _sending = true; _error = null; });
    try {
      await Supabase.instance.client.from('announcements').insert({
        'title':   title,
        'body':    body,
        'is_active': true,
      });
      if (mounted) setState(() { _sending = false; _sent = true; });
    } catch (e) {
      if (mounted) setState(() { _sending = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFF59E0B);

    return DraggableScrollableSheet(
      initialChildSize: 0.70,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          Expanded(
            child: _sent
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.campaign_rounded, color: gold, size: 56),
                      const SizedBox(height: 12),
                      const Text('Announcement Posted!',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text('All parents will see this in their dashboard.',
                          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.55))),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(backgroundColor: gold),
                        child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                      ),
                    ]),
                  )
                : ListView(
                    controller: ctrl,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    children: [
                      const Row(children: [
                        Icon(Icons.campaign_rounded, color: gold, size: 22),
                        SizedBox(width: 10),
                        Text('Post Announcement',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                      ]),
                      const SizedBox(height: 4),
                      Text('Visible to all parents on the dashboard.',
                          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
                      const SizedBox(height: 20),

                      const Text('Title',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        onChanged: (_) { if (_error != null) setState(() => _error = null); },
                        decoration: _fieldDecor('e.g. New content available!', gold),
                      ),
                      const SizedBox(height: 14),

                      const Text('Message',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _bodyCtrl,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        onChanged: (_) { if (_error != null) setState(() => _error = null); },
                        decoration: _fieldDecor('Write your announcement…', gold),
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.red)),
                      ],
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _sending ? null : _submit,
                          icon: _sending
                              ? const SizedBox(width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send_rounded, size: 18),
                          label: const Text('Post Announcement',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: gold,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }

  InputDecoration _fieldDecor(String hint, Color accent) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accent)),
      );
}

// ── Admin: Feedback inbox sheet ────────────────────────────────────────────────

class _AdminFeedbackInboxSheet extends StatefulWidget {
  const _AdminFeedbackInboxSheet();

  @override
  State<_AdminFeedbackInboxSheet> createState() => _AdminFeedbackInboxSheetState();
}

class _AdminFeedbackInboxSheetState extends State<_AdminFeedbackInboxSheet> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String _filter = 'all';

  static const _filters = ['all', 'bug', 'suggestion', 'general', 'unresolved'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await Supabase.instance.client
          .from('parent_feedback')
          .select()
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _items = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'unresolved') return _items.where((i) => i['resolved'] != true).toList();
    if (_filter == 'all') return _items;
    return _items.where((i) => i['category'] == _filter).toList();
  }

  Future<void> _reply(String id, String replyText) async {
    try {
      await Supabase.instance.client.from('parent_feedback').update({
        'admin_reply': replyText,
        'admin_replied_at': DateTime.now().toIso8601String(),
        'resolved': true,
      }).eq('id', id);
      await _load();
    } catch (_) {}
  }

  void _showReplyDialog(Map<String, dynamic> item) {
    final ctrl = TextEditingController(text: item['admin_reply'] as String? ?? '');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reply to Feedback',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Type your reply…',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
            filled: true,
            fillColor: _surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _reply(item['id'] as String, ctrl.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: _purple),
            child: const Text('Send Reply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(children: [
              const Icon(Icons.inbox_rounded, color: Color(0xFFEC4899), size: 22),
              const SizedBox(width: 10),
              const Text('Parent Feedback', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: _textSub, size: 20),
                onPressed: _load,
              ),
            ]),
          ),
          // Filter chips
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _filters.map((f) {
                final selected = _filter == f;
                return GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? _purple.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? _purple.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      f[0].toUpperCase() + f.substring(1),
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: selected ? const Color(0xFFAB8FE8) : Colors.white54),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(child: Text('No feedback.', style: TextStyle(color: _textSub, fontSize: 13)))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          controller: ctrl,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final item = _filtered[i];
                            final resolved = item['resolved'] == true;
                            final cat = item['category'] as String? ?? 'general';
                            final msg = item['message'] as String? ?? '';
                            final reply = item['admin_reply'] as String?;
                            final email = item['user_email'] as String? ?? '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: resolved
                                    ? Colors.green.withValues(alpha: 0.06)
                                    : Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: resolved
                                      ? Colors.green.withValues(alpha: 0.3)
                                      : Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _purple.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(cat.toUpperCase(),
                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFAB8FE8))),
                                  ),
                                  const SizedBox(width: 6),
                                  if (email.isNotEmpty)
                                    Expanded(child: Text(email,
                                        style: const TextStyle(fontSize: 10, color: _textSub),
                                        overflow: TextOverflow.ellipsis)),
                                  if (resolved)
                                    const Icon(Icons.check_circle_rounded, size: 14, color: Colors.green),
                                ]),
                                const SizedBox(height: 8),
                                Text(msg, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                if (reply != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _purple.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(children: [
                                      const Icon(Icons.admin_panel_settings_rounded, size: 14, color: Color(0xFFAB8FE8)),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(reply,
                                          style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4))),
                                    ]),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => _showReplyDialog(item),
                                    child: Text(reply != null ? 'Edit Reply' : 'Reply',
                                        style: const TextStyle(color: Color(0xFFAB8FE8), fontSize: 12, fontWeight: FontWeight.w700)),
                                  ),
                                ),
                              ]),
                            );
                          },
                        ),
                      ),
          ),
        ]),
      ),
    );
  }
}

// ── Admin: Message parent sheet ───────────────────────────────────────────────

class _AdminMessageSheet extends StatefulWidget {
  const _AdminMessageSheet();

  @override
  State<_AdminMessageSheet> createState() => _AdminMessageSheetState();
}

class _AdminMessageSheetState extends State<_AdminMessageSheet> {
  final _emailCtrl   = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl    = TextEditingController();
  bool _sending = false;
  bool _sent    = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email   = _emailCtrl.text.trim();
    final subject = _subjectCtrl.text.trim();
    final body    = _bodyCtrl.text.trim();
    if (email.isEmpty || subject.isEmpty || body.isEmpty) {
      setState(() => _error = 'All fields are required.');
      return;
    }
    setState(() { _sending = true; _error = null; });
    try {
      // Look up user id by email
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      if (profile == null) {
        setState(() { _sending = false; _error = 'No parent found with that email.'; });
        return;
      }
      final userId = profile['id'] as String;

      // Create thread + first message
      final thread = await Supabase.instance.client.from('message_threads').insert({
        'user_id':        userId,
        'username':       email,
        'subject':        subject,
        'type':           'general',
        'user_unread':    true,
        'admin_unread':   false,
        'last_message_at': DateTime.now().toUtc().toIso8601String(),
      }).select().single();

      await Supabase.instance.client.from('thread_messages').insert({
        'thread_id': thread['id'],
        'sender':    'admin',
        'body':      body,
      });

      if (mounted) setState(() { _sending = false; _sent = true; });
    } catch (e) {
      if (mounted) setState(() { _sending = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF3B82F6);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          Expanded(
            child: _sent
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.check_circle_rounded, color: blue, size: 56),
                      const SizedBox(height: 12),
                      const Text('Message Sent!',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text('The parent will see this in their Inbox.',
                          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.55))),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(backgroundColor: blue),
                        child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                      ),
                    ]),
                  )
                : ListView(
                    controller: ctrl,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    children: [
                      const Row(children: [
                        Icon(Icons.message_rounded, color: blue, size: 22),
                        SizedBox(width: 10),
                        Text('Message a Parent',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                      ]),
                      const SizedBox(height: 20),
                      _buildField('Parent Email', _emailCtrl, 'parent@email.com', blue, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 12),
                      _buildField('Subject', _subjectCtrl, 'e.g. Welcome to LearniVerse!', blue),
                      const SizedBox(height: 12),
                      _buildField('Message', _bodyCtrl, 'Write your message…', blue, maxLines: 5),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.red)),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _sending ? null : _send,
                          icon: _sending
                              ? const SizedBox(width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send_rounded, size: 18),
                          label: const Text('Send Message',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, Color accent,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        onChanged: (_) { if (_error != null) setState(() => _error = null); },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
          filled: true,
          fillColor: _surface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accent)),
        ),
      ),
    ]);
  }
}
