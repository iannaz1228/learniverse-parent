import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/supabase_bootstrap.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _activityProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, childId) async {
  final client = ref.read(supabaseClientProvider);
  if (client == null) return {};

  final profile = await client
      .from('profiles')
      .select('nickname, xp, coins, level, streak_current, streak_longest, last_active_at, daily_limit_minutes')
      .eq('id', childId)
      .single();

  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final sessions = await client
      .from('activity_sessions')
      .select('route, started_at, ended_at, duration_sec')
      .eq('child_id', childId)
      .gte('started_at', '${today}T00:00:00')
      .order('started_at', ascending: false);

  final totalSec = (sessions as List).fold<int>(
    0,
    (sum, s) => sum + ((s['duration_sec'] as num?)?.toInt() ?? 0),
  );

  return {
    'profile': profile,
    'sessions': sessions,
    'total_sec_today': totalSec,
  };
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key, required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_activityProvider(childId));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0A1E), Color(0xFF1A1040), Color(0xFF1A0F30)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
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
                      "Today's Activity",
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
                          color: Color(0xFF8B5CF6))),
                  error: (e, _) => Center(
                      child: Text('Error: $e',
                          style: const TextStyle(color: Colors.white70))),
                  data: (data) {
                    if (data.isEmpty) {
                      return const Center(
                          child: Text('No data',
                              style: TextStyle(color: Colors.white70)));
                    }
                    final profile =
                        data['profile'] as Map<String, dynamic>;
                    final sessions =
                        data['sessions'] as List;
                    final totalSec =
                        data['total_sec_today'] as int;
                    final limitMin =
                        (profile['daily_limit_minutes'] as num?)?.toInt() ?? 60;
                    final nickname =
                        profile['nickname'] as String? ?? 'Child';
                    final xp = (profile['xp'] as num?)?.toInt() ?? 0;
                    final coins =
                        (profile['coins'] as num?)?.toInt() ?? 0;
                    final streak =
                        (profile['streak_current'] as num?)?.toInt() ?? 0;
                    final lastActive =
                        profile['last_active_at'] as String?;

                    return ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Usage overview
                        _UsageCard(
                          nickname: nickname,
                          totalSec: totalSec,
                          limitMin: limitMin,
                        ),
                        const SizedBox(height: 16),

                        // Quick stats
                        Row(
                          children: [
                            Expanded(
                              child: _MiniStat(
                                label: 'XP Today',
                                value: '$xp',
                                icon: Icons.star_rounded,
                                color: const Color(0xFF8B5CF6),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MiniStat(
                                label: 'Coins',
                                value: '$coins',
                                icon: Icons.monetization_on_rounded,
                                color: const Color(0xFFEAB308),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MiniStat(
                                label: 'Streak',
                                value: '${streak}d',
                                icon: Icons.local_fire_department_rounded,
                                color: const Color(0xFFF97316),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (lastActive != null) ...[
                          _InfoRow(
                            icon: Icons.access_time_rounded,
                            label: 'Last active',
                            value: _formatTimestamp(lastActive),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Sessions list
                        if (sessions.isNotEmpty) ...[
                          const Text(
                            'Sessions Today',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...sessions.map((s) => _SessionTile(session: s)),
                        ] else
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.bedtime_outlined,
                                    color: Colors.white.withValues(alpha: 0.30),
                                    size: 40),
                                const SizedBox(height: 8),
                                Text(
                                  'No activity today',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.50),
                                    fontSize: 14,
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

  String _formatTimestamp(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      return DateFormat('MMM d, h:mm a').format(dt);
    } catch (_) {
      return ts;
    }
  }
}

class _UsageCard extends StatelessWidget {
  const _UsageCard(
      {required this.nickname,
      required this.totalSec,
      required this.limitMin});
  final String nickname;
  final int totalSec;
  final int limitMin;

  @override
  Widget build(BuildContext context) {
    final usedMin = totalSec ~/ 60;
    final progress = (usedMin / limitMin).clamp(0.0, 1.0);
    final isOver = usedMin >= limitMin;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isOver
              ? [const Color(0xFF7F1D1D), const Color(0xFF991B1B)]
              : [const Color(0xFF1E1060), const Color(0xFF2D1B69)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOver
              ? Colors.red.withValues(alpha: 0.50)
              : const Color(0xFF7C3AED).withValues(alpha: 0.40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                nickname,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                isOver ? 'Limit reached!' : 'Active today',
                style: TextStyle(
                  color: isOver ? Colors.redAccent : const Color(0xFF7C3AED),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmt(usedMin),
                style: TextStyle(
                  color: isOver ? Colors.redAccent : Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '/ ${_fmt(limitMin)} limit',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.50),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(
                isOver ? Colors.redAccent : const Color(0xFF7C3AED),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int mins) =>
      mins >= 60 ? '${mins ~/ 60}h ${mins % 60}m' : '${mins}m';
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});
  final Map session;

  @override
  Widget build(BuildContext context) {
    final route = session['route'] as String? ?? 'Unknown';
    final durationSec = (session['duration_sec'] as num?)?.toInt() ?? 0;
    final startedAt = session['started_at'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.play_circle_rounded,
                color: Color(0xFF8B5CF6), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatRoute(route),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                if (startedAt != null)
                  Text(
                    _formatTime(startedAt),
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11),
                  ),
              ],
            ),
          ),
          Text(
            durationSec > 0 ? _fmtSec(durationSec) : '--',
            style: const TextStyle(
                color: Color(0xFF8B5CF6),
                fontSize: 13,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  String _formatRoute(String route) =>
      route.replaceAll('/', '').replaceAll('-', ' ').trim().toUpperCase();

  String _formatTime(String ts) {
    try {
      return DateFormat('h:mm a').format(DateTime.parse(ts).toLocal());
    } catch (_) {
      return '';
    }
  }

  String _fmtSec(int s) =>
      s >= 60 ? '${s ~/ 60}m ${s % 60}s' : '${s}s';
}
