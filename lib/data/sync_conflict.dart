import 'package:flutter/material.dart';

import '../core/theme/figus_colors.dart';

/// Result of comparing local vs remote collection counts during a sync.
/// Drives whichever side overwrites the other (or whether we ask the user
/// to pick).
enum SyncDecision {
  /// Both sides empty — nothing to do.
  identical,

  /// Local has nothing; pull from cloud silently (no risk).
  autoPull,

  /// Cloud empty; push local silently (cloud only gains).
  autoPush,

  /// Counts match — silent two-way merge is safe (apply remote, then
  /// push to cover any new local rows the cloud doesn't have yet).
  silentMerge,

  /// User picked: overwrite cloud with this device's data.
  useLocal,

  /// User picked: overwrite local with cloud data.
  useCloud,

  /// User cancelled the sync.
  cancel,
}

/// Decides how a sync should proceed. Auto-resolves the safe cases and
/// only opens the dialog when both sides have data and they don't match.
/// Returns the chosen action.
Future<SyncDecision> decideSyncAction({
  required BuildContext context,
  required int localMarked,
  required int localExtras,
  required int remoteMarked,
  required int remoteExtras,
}) async {
  if (localMarked == 0 && remoteMarked == 0) return SyncDecision.identical;
  if (localMarked == 0) return SyncDecision.autoPull;
  if (remoteMarked == 0) return SyncDecision.autoPush;
  if (localMarked == remoteMarked && localExtras == remoteExtras) {
    return SyncDecision.silentMerge;
  }
  final picked = await showDialog<SyncDecision>(
    context: context,
    barrierDismissible: false,
    builder: (_) => SyncConflictDialog(
      localMarked: localMarked,
      localExtras: localExtras,
      remoteMarked: remoteMarked,
      remoteExtras: remoteExtras,
    ),
  );
  return picked ?? SyncDecision.cancel;
}

/// Dialog shown when local and cloud both have data and they don't match.
/// Each side is itself a tappable button — so the user picks by tapping
/// the side they want to keep, not by reading info and then hunting for
/// the matching button below. Cancel sits at the bottom as a quiet exit.
class SyncConflictDialog extends StatelessWidget {
  final int localMarked;
  final int localExtras;
  final int remoteMarked;
  final int remoteExtras;

  const SyncConflictDialog({
    super.key,
    required this.localMarked,
    required this.localExtras,
    required this.remoteMarked,
    required this.remoteExtras,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return AlertDialog(
      title: const Text('Conflito de sincronização'),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Os dados deste dispositivo e da nuvem são diferentes. '
            'Toque no lado que você quer manter — o outro será '
            'sobrescrito.',
            style: TextStyle(color: c.text, height: 1.4, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _SideChoiceButton(
            icon: Icons.phone_android_rounded,
            title: 'Manter este dispositivo',
            subtitle:
                '$localMarked figurinhas'
                '${localExtras > 0 ? "  ·  $localExtras repetidas" : ""}',
            footer: 'A nuvem será sobrescrita com estes dados',
            color: c.accent,
            onTap: () => Navigator.pop(context, SyncDecision.useLocal),
          ),
          const SizedBox(height: 10),
          _SideChoiceButton(
            icon: Icons.cloud_done_rounded,
            title: 'Usar dados da nuvem',
            subtitle:
                '$remoteMarked figurinhas'
                '${remoteExtras > 0 ? "  ·  $remoteExtras repetidas" : ""}',
            footer: 'Este dispositivo será sobrescrito com a nuvem',
            color: const Color(0xFF1AB4D3),
            onTap: () => Navigator.pop(context, SyncDecision.useCloud),
          ),
          const SizedBox(height: 4),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, SyncDecision.cancel),
          child: const Text('Não sincronizar agora'),
        ),
      ],
    );
  }
}

class _SideChoiceButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String footer;
  final Color color;
  final VoidCallback onTap;

  const _SideChoiceButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.footer,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.55), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      footer,
                      style: TextStyle(
                        fontSize: 11,
                        color: c.textMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: color.withValues(alpha: 0.7), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
