import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase_bootstrap.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _progressProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, childId) async {
  final client = ref.read(supabaseClientProvider);
  if (client == null) return null;
  final data = await client
      .from('profiles')
      .select('nickname, xp, coins, level, streak_current, streak_longest, badges, hive_progress')
      .eq('id', childId)
      .single();
  return data;
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key, required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_progressProvider(childId));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0A1E), Color(0xFF1A1040), Color(0xFF1A2040)],
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
                      'Progress Report',
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
                          color: Color(0xFF3B82F6))),
                  error: (e, _) => Center(
                      child: Text('Error: $e',
                          style: const TextStyle(color: Colors.white70))),
                  data: (data) {
                    if (data == null) {
                      return const Center(
                          child: Text('No data',
                              style: TextStyle(color: Colors.white70)));
                    }

                    final nickname = data['nickname'] as String? ?? 'Child';
                    final xp = (data['xp'] as num?)?.toInt() ?? 0;
                    final coins = (data['coins'] as num?)?.toInt() ?? 0;
                    final level = (data['level'] as num?)?.toInt() ?? 1;
                    final streakCurrent = (data['streak_current'] as num?)?.toInt() ?? 0;
                    final streakLongest = (data['streak_longest'] as num?)?.toInt() ?? 0;
                    final badges = (data['badges'] as List?)?.cast<String>() ?? [];
                    final hive = data['hive_progress'] as Map<String, dynamic>? ?? {};

                    return ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Hero card
                        _HeroCard(
                          nickname: nickname,
                          xp: xp,
                          coins: coins,
                          level: level,
                        ),
                        const SizedBox(height: 16),

                        // Streak
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Current Streak',
                                value: '$streakCurrent days',
                                icon: Icons.local_fire_department_rounded,
                                color: const Color(0xFFF97316),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatCard(
                                label: 'Best Streak',
                                value: '$streakLongest days',
                                icon: Icons.emoji_events_rounded,
                                color: const Color(0xFFEAB308),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Subject progress from hive
                        _SubjectProgress(hive: hive),
                        const SizedBox(height: 16),

                        // Quiz stats
                        _QuizStats(hive: hive),
                        const SizedBox(height: 16),

                        // Badges
                        if (badges.isNotEmpty) ...[
                          const Text(
                            'Earned Badges',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: badges
                                .map((b) => _BadgeChip(badgeId: b))
                                .toList(),
                          ),
                        ],
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.nickname,
    required this.xp,
    required this.coins,
    required this.level,
  });
  final String nickname;
  final int xp, coins, level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.50)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            child: Text(
              nickname.isNotEmpty ? nickname[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.50)),
                  ),
                  child: Text(
                    'Level $level',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$xp XP  •  $coins coins',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
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
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectProgress extends StatelessWidget {
  const _SubjectProgress({required this.hive});
  final Map<String, dynamic> hive;

  @override
  Widget build(BuildContext context) {
    final subjects = [
      _Subject('ABC Letters', Icons.abc_rounded, const Color(0xFF6366F1),
          _countKeys(hive, 'abc_learned'), 26),
      _Subject('Spellings', Icons.edit_rounded, const Color(0xFF06B6D4),
          _countKeys(hive, 'abc_challenge'), 26),
      _Subject('Math Stages', Icons.calculate_rounded, const Color(0xFF10B981),
          _countKeys(hive, 'math_challenge'), 40),
      _Subject('Puzzle Stages', Icons.extension_rounded, const Color(0xFFF97316),
          _countKeys(hive, 'puzzle_challenge'), 24),
      _Subject('Planets', Icons.public_rounded, const Color(0xFF3B82F6),
          _countKeys(hive, 'space_discovered'), 10),
      _Subject('Animals', Icons.pets_rounded, const Color(0xFF22C55E),
          _countKeys(hive, 'animal_discovered'), 32),
    ];

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
          const Text(
            'Learning Progress',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...subjects.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _SubjectBar(subject: s),
              )),
        ],
      ),
    );
  }

  int _countKeys(Map<String, dynamic> hive, String key) {
    final val = hive[key];
    if (val == null) return 0;
    if (val is List) return val.length;
    if (val is Map) {
      // space_discovered / animal_discovered store { 'ids': [...] }
      final ids = val['ids'];
      if (ids is List) return ids.length;
      // abc_learned stores { 'letters': [...] }
      final letters = val['letters'];
      if (letters is List) return letters.length;
      // math/abc/puzzle_challenge store { 'results': { '0': {...} } }
      final results = val['results'];
      if (results is Map) return results.length;
      return val.length;
    }
    return 0;
  }
}

class _Subject {
  const _Subject(this.name, this.icon, this.color, this.done, this.total);
  final String name;
  final IconData icon;
  final Color color;
  final int done, total;
}

class _SubjectBar extends StatelessWidget {
  const _SubjectBar({required this.subject});
  final _Subject subject;

  @override
  Widget build(BuildContext context) {
    final progress = subject.total == 0 ? 0.0 : subject.done / subject.total;

    return Column(
      children: [
        Row(
          children: [
            Icon(subject.icon, color: subject.color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                subject.name,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            Text(
              '${subject.done}/${subject.total}',
              style: TextStyle(
                color: subject.color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation(subject.color),
          ),
        ),
      ],
    );
  }
}

class _QuizStats extends StatelessWidget {
  const _QuizStats({required this.hive});
  final Map<String, dynamic> hive;

  @override
  Widget build(BuildContext context) {
    final daily = hive['daily_quiz_v2'] as Map?;
    final weekly = hive['weekly_quiz_v2'] as Map?;
    final streak = (daily?['streak'] as num?)?.toInt() ?? 0;
    final dailyScore = (daily?['last_score'] as num?)?.toInt();
    final weeklyScore = (weekly?['last_score'] as num?)?.toInt();
    final weeklyBest = (weekly?['best_score'] as num?)?.toInt() ?? 0;

    if (daily == null && weekly == null) return const SizedBox.shrink();

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
          const Text(
            'Quiz Performance',
            style: TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (streak > 0)
                Expanded(
                  child: _QuizStatTile(
                    emoji: '🔥',
                    label: 'Daily Streak',
                    value: '$streak day${streak == 1 ? '' : 's'}',
                    color: Colors.orange,
                  ),
                ),
              if (streak > 0) const SizedBox(width: 10),
              if (dailyScore != null)
                Expanded(
                  child: _QuizStatTile(
                    emoji: '🦉',
                    label: 'Last Daily',
                    value: '$dailyScore / 5',
                    color: const Color(0xFF818CF8),
                  ),
                ),
              if (dailyScore != null && weeklyBest > 0) const SizedBox(width: 10),
              if (weeklyBest > 0)
                Expanded(
                  child: _QuizStatTile(
                    emoji: '📚',
                    label: 'Best Weekly',
                    value: '$weeklyBest / 12',
                    color: const Color(0xFF34D399),
                  ),
                ),
            ],
          ),
          if (weeklyScore != null && weeklyScore == 12) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: Colors.amber.withValues(alpha: 0.35)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium_rounded,
                      color: Colors.amber, size: 14),
                  SizedBox(width: 6),
                  Text('Perfect Weekly Score!',
                      style: TextStyle(
                          color: Colors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuizStatTile extends StatelessWidget {
  const _QuizStatTile({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  final String emoji, label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w900)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badgeId});
  final String badgeId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium_rounded,
              color: Colors.amber, size: 14),
          const SizedBox(width: 6),
          Text(
            badgeId,
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
