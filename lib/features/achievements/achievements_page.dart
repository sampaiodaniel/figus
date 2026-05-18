import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/figus_colors.dart';
import '../../core/widgets/figus_app_bar.dart';
import '../../data/providers.dart';
import 'badge_service.dart';
import 'badges_catalog.dart';

/// Showcase of every achievement the app tracks. Locked ones render greyed
/// out; earned ones gain the catalog color + emoji. Counter at the top
/// summarizes progress (X / Y).
class AchievementsPage extends ConsumerStatefulWidget {
  const AchievementsPage({super.key});

  @override
  ConsumerState<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends ConsumerState<AchievementsPage> {
  bool _rechecking = false;

  @override
  void initState() {
    super.initState();
    // Run a recheck on entry so badges earned implicitly (via streak / coll
    // progress) appear instantly without waiting for the next sync tick.
    WidgetsBinding.instance.addPostFrameCallback((_) => _recheck());
  }

  Future<void> _recheck() async {
    if (_rechecking) return;
    setState(() => _rechecking = true);
    try {
      final pid = (await ref.read(profileRepoProvider).active()).id;
      await ref.read(badgeServiceProvider).recheckAll(pid);
      ref.read(badgesVersionProvider.notifier).state++;
    } finally {
      if (mounted) setState(() => _rechecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final earnedAsync = ref.watch(earnedBadgesProvider);
    final total = kAchievements.length;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: const FigusAppBar(title: 'Conquistas'),
      body: earnedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (earned) {
          final earnedCount = kAchievements
              .where((a) => earned.contains(a.id))
              .length;
          final pct = total > 0 ? (earnedCount / total) : 0.0;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _ProgressHeader(
                earned: earnedCount,
                total: total,
                pct: pct,
              ),
              const SizedBox(height: 24),
              for (final entry in achievementsByCategory.entries) ...[
                _SectionHeader(
                  label: entry.key.label,
                  earned: entry.value.where((a) => earned.contains(a.id)).length,
                  total: entry.value.length,
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.92,
                  ),
                  itemCount: entry.value.length,
                  itemBuilder: (_, i) {
                    final a = entry.value[i];
                    return _BadgeTile(def: a, unlocked: earned.contains(a.id));
                  },
                ),
                const SizedBox(height: 24),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int earned;
  final int total;
  final double pct;

  const _ProgressHeader({
    required this.earned,
    required this.total,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            c.accent.withValues(alpha: 0.18),
            c.accent.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          // Circular progress dial
          SizedBox(
            width: 76,
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: CircularProgressIndicator(
                    value: pct,
                    strokeWidth: 7,
                    backgroundColor: c.border,
                    valueColor: AlwaysStoppedAnimation<Color>(c.accent),
                  ),
                ),
                Text(
                  '${(pct * 100).round()}%',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: c.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$earned / $total',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: c.text,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'troféus desbloqueados',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: c.textMuted,
                    fontWeight: FontWeight.w500,
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

class _SectionHeader extends StatelessWidget {
  final String label;
  final int earned;
  final int total;

  const _SectionHeader({
    required this.label,
    required this.earned,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: c.textMuted,
            ),
          ),
          const Spacer(),
          Text(
            '$earned/$total',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: c.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final AchievementDef def;
  final bool unlocked;

  const _BadgeTile({required this.def, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Big colored gradient panel for unlocked / flat grey for locked.
          // The emoji fills the tile so the badge feels like a real medal,
          // not a tiny pictogram floating in white space.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: unlocked
                  ? LinearGradient(
                      colors: [
                        def.color.withValues(alpha: 0.95),
                        def.color.withValues(alpha: 0.55),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: unlocked ? null : c.cardAlt,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: unlocked ? def.color : c.border,
                width: unlocked ? 0 : 1,
              ),
              boxShadow: unlocked
                  ? [
                      BoxShadow(
                        color: def.color.withValues(alpha: 0.30),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
          ),
          // Emoji — fills most of the tile area. Opacity drops when locked.
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Opacity(
                opacity: unlocked ? 1.0 : 0.18,
                child: LayoutBuilder(builder: (_, cons) {
                  final dim = cons.maxWidth < cons.maxHeight
                      ? cons.maxWidth
                      : cons.maxHeight;
                  return Text(
                    def.emoji,
                    style: TextStyle(fontSize: dim * 0.55),
                  );
                }),
              ),
            ),
          ),
          // Label as a subtle ribbon at the bottom — only the persona/marco
          // name, no description. Always readable: white on color tile,
          // muted on grey tile.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              decoration: BoxDecoration(
                color: unlocked
                    ? Colors.black.withValues(alpha: 0.28)
                    : Colors.transparent,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Text(
                def.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: unlocked
                      ? Colors.white
                      : c.textMuted.withValues(alpha: 0.7),
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          // Lock overlay only — unlocked badges don't need a checkmark, the
          // saturated color already screams "earned".
          if (!unlocked)
            const Positioned(
              top: 8,
              right: 8,
              child: Icon(Icons.lock_rounded, size: 14, color: Colors.white70),
            ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final c = context.fc;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Opacity(
              opacity: unlocked ? 1.0 : 0.35,
              child: Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: def.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  def.emoji,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              def.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: c.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              def.description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: c.textMuted, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: unlocked
                    ? def.color.withValues(alpha: 0.15)
                    : c.cardAlt,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: unlocked ? def.color.withValues(alpha: 0.4) : c.border,
                ),
              ),
              child: Text(
                unlocked ? '✓ Desbloqueado' : 'Bloqueado',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: unlocked ? def.color : c.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
