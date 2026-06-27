import 'package:flutter/material.dart';

class ContentStoreScreen extends StatelessWidget {
  const ContentStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {

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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              // ── Header ─────────────────────────────────────────────────
              const Text(
                'Content Store',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Unlock learning content packs for your children',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.50),
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 24),

              // ── Story Pack ─────────────────────────────────────────────
              _PackCard(
                emoji: '📖',
                title: 'Story Pack',
                description: 'Premium illustrated stories for your child to read and explore.',
                tag: 'FREE',
                tagColor: const Color(0xFF10B981),
                gradient: const [Color(0xFF0C4A6E), Color(0xFF0369A1), Color(0xFF0EA5E9)],
              ),

              const SizedBox(height: 16),

              // ── Coming Soon packs ──────────────────────────────────────
              _ComingSoonCard(
                emoji: '🔢',
                title: 'Math Pack',
                description: 'Advanced math challenges and puzzle stages.',
                gradient: const [Color(0xFF1E3A5F), Color(0xFF1D4ED8)],
              ),
              const SizedBox(height: 12),
              _ComingSoonCard(
                emoji: '🔬',
                title: 'Science Pack',
                description: 'Interactive science experiments and discoveries.',
                gradient: const [Color(0xFF14532D), Color(0xFF15803D)],
              ),
              const SizedBox(height: 12),
              _ComingSoonCard(
                emoji: '🎨',
                title: 'Art Pack',
                description: 'Creative coloring pages and art activities.',
                gradient: const [Color(0xFF4A1D96), Color(0xFF7C3AED)],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Active pack card ──────────────────────────────────────────────────────────

class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.tag,
    required this.tagColor,
    required this.gradient,
  });

  final String emoji;
  final String title;
  final String description;
  final String tag;
  final Color tagColor;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tagColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                    height: 1.4,
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

// ── Coming soon card ──────────────────────────────────────────────────────────

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.gradient,
  });
  final String emoji;
  final String title;
  final String description;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.55,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'SOON',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
