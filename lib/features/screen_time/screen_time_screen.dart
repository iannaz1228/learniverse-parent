import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase_bootstrap.dart';
import '../../shared/widgets/confirm_dialog.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _screenTimeProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, childId) async {
  final client = ref.read(supabaseClientProvider);
  if (client == null) return null;
  final rows = await client
      .from('profiles')
      .select('daily_limit_minutes, is_locked, nickname, access_start_time, access_end_time')
      .eq('id', childId)
      .limit(1);
  final list = rows as List;
  if (list.isEmpty) return null;
  return list.first as Map<String, dynamic>;
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ScreenTimeScreen extends ConsumerStatefulWidget {
  const ScreenTimeScreen({super.key, required this.childId});
  final String childId;

  @override
  ConsumerState<ScreenTimeScreen> createState() => _ScreenTimeScreenState();
}

class _ScreenTimeScreenState extends ConsumerState<ScreenTimeScreen> {
  int _limitMinutes = 60;
  bool _saving = false;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _hoursEnabled = false;

  TimeOfDay? _parseTime(String? s) {
    if (s == null || s.isEmpty) return null;
    final parts = s.split(':');
    if (parts.length != 2) return null;
    return TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? (_startTime ?? const TimeOfDay(hour: 7, minute: 0))
                            : (_endTime ?? const TimeOfDay(hour: 20, minute: 0));
    final t = await showTimePicker(context: context, initialTime: initial);
    if (t != null) setState(() => isStart ? _startTime = t : _endTime = t);
  }

  Future<void> _saveAccessHours() async {
    setState(() => _saving = true);
    final client = ref.read(supabaseClientProvider);
    await client?.from('profiles').update({
      'access_start_time': (_hoursEnabled && _startTime != null) ? _fmtTime(_startTime!) : null,
      'access_end_time':   (_hoursEnabled && _endTime   != null) ? _fmtTime(_endTime!)   : null,
    }).eq('id', widget.childId);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access hours updated!')),
      );
      ref.invalidate(_screenTimeProvider(widget.childId));
    }
  }

  Future<void> _saveLimit() async {
    final h = _limitMinutes ~/ 60;
    final m = _limitMinutes % 60;
    final label = h > 0 ? '${h}h ${m}m' : '${m}m';
    final ok = await showConfirmDialog(
      context,
      title: 'Update Screen Time?',
      message: 'Set daily limit to $label. This takes effect immediately.',
      confirmLabel: 'Save',
      icon: Icons.timer_rounded,
      iconColor: const Color(0xFF10B981),
      confirmColor: const Color(0xFF10B981),
    );
    if (!ok || !mounted) return;
    setState(() => _saving = true);
    final client = ref.read(supabaseClientProvider);
    if (client != null) {
      await client
          .from('profiles')
          .update({'daily_limit_minutes': _limitMinutes})
          .eq('id', widget.childId);
    }
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Screen time limit updated!')),
      );
      ref.invalidate(_screenTimeProvider(widget.childId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_screenTimeProvider(widget.childId));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0A1E), Color(0xFF1A1040), Color(0xFF0D2E1A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white),
                    ),
                    const Text(
                      'Screen Time',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: async.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF10B981))),
                  error: (e, _) => Center(
                      child: Text('Error: $e',
                          style: const TextStyle(color: Colors.white70))),
                  data: (data) {
                    if (data == null) {
                      return const Center(
                          child: Text('No data',
                              style: TextStyle(color: Colors.white70)));
                    }
                    final saved =
                        (data['daily_limit_minutes'] as num?)?.toInt() ?? 60;
                    final savedStart = _parseTime(data['access_start_time'] as String?);
                    final savedEnd   = _parseTime(data['access_end_time']   as String?);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() {
                        if (_limitMinutes == 60 && saved != 60) _limitMinutes = saved;
                        if (_startTime == null && savedStart != null) {
                          _startTime   = savedStart;
                          _endTime     = savedEnd;
                          _hoursEnabled = true;
                        }
                      });
                    });
                    final isLocked = data['is_locked'] as bool? ?? false;
                    final nickname = data['nickname'] as String? ?? 'Child';

                    return ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Status card
                        _StatusCard(
                            nickname: nickname, isLocked: isLocked),
                        const SizedBox(height: 20),

                        // Daily limit
                        _SectionCard(
                          icon: Icons.timer_rounded,
                          title: 'Daily Time Limit',
                          color: const Color(0xFF10B981),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_limitMinutes ~/ 60}h ${_limitMinutes % 60}m',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    '$_limitMinutes min',
                                    style: TextStyle(
                                      color: Colors.white
                                          .withValues(alpha: 0.55),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Slider(
                                value: _limitMinutes.toDouble(),
                                min: 15,
                                max: 240,
                                divisions: 15,
                                activeColor: const Color(0xFF10B981),
                                inactiveColor: const Color(0xFF10B981)
                                    .withValues(alpha: 0.20),
                                onChanged: (v) =>
                                    setState(() => _limitMinutes = v.round()),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('15 min',
                                      style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.40),
                                          fontSize: 11)),
                                  Text('4 hours',
                                      style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.40),
                                          fontSize: 11)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                  ),
                                  onPressed: _saving ? null : _saveLimit,
                                  child: _saving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white))
                                      : const Text('Save Limit'),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Quick additions
                        _SectionCard(
                          icon: Icons.add_alarm_rounded,
                          title: 'Quick Add',
                          color: const Color(0xFF3B82F6),
                          child: Wrap(
                            spacing: 10,
                            children: [15, 30, 60].map((mins) {
                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF3B82F6).withValues(alpha: 0.20),
                                  foregroundColor: const Color(0xFF3B82F6),
                                  side: const BorderSide(
                                      color: Color(0xFF3B82F6)),
                                ),
                                onPressed: () {
                                  setState(() => _limitMinutes =
                                      (_limitMinutes + mins).clamp(15, 240));
                                },
                                child: Text('+${mins}m'),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Access hours
                        _SectionCard(
                          icon: Icons.schedule_rounded,
                          title: 'Access Hours',
                          color: const Color(0xFF8B5CF6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Restrict to specific hours',
                                      style: TextStyle(color: Colors.white70, fontSize: 13),
                                    ),
                                  ),
                                  Switch(
                                    value: _hoursEnabled,
                                    activeColor: const Color(0xFF8B5CF6),
                                    onChanged: (v) => setState(() => _hoursEnabled = v),
                                  ),
                                ],
                              ),
                              if (_hoursEnabled) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _TimePicker(
                                        label: 'From',
                                        time: _startTime,
                                        onTap: () => _pickTime(true),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 12),
                                      child: Text('→', style: TextStyle(color: Colors.white54, fontSize: 18)),
                                    ),
                                    Expanded(
                                      child: _TimePicker(
                                        label: 'Until',
                                        time: _endTime,
                                        onTap: () => _pickTime(false),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF8B5CF6),
                                    ),
                                    onPressed: _saving ? null : _saveAccessHours,
                                    child: const Text('Save Hours'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.30)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: Colors.amber, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'When the daily limit is reached, the child app locks automatically. Use Lock/Unlock on the main screen for immediate control.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.70),
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.nickname, required this.isLocked});
  final String nickname;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLocked
            ? Colors.red.withValues(alpha: 0.12)
            : const Color(0xFF10B981).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLocked
              ? Colors.red.withValues(alpha: 0.40)
              : const Color(0xFF10B981).withValues(alpha: 0.40),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
            color: isLocked ? Colors.redAccent : const Color(0xFF10B981),
            size: 28,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nickname,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              Text(
                isLocked ? 'App is locked' : 'App is active',
                style: TextStyle(
                  color: isLocked ? Colors.redAccent : const Color(0xFF10B981),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.icon,
      required this.title,
      required this.color,
      required this.child});
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  const _TimePicker({required this.label, required this.time, required this.onTap});
  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.40)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              time != null
                  ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}'
                  : 'Tap to set',
              style: TextStyle(
                color: time != null ? Colors.white : Colors.white38,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
