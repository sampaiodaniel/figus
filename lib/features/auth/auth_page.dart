import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/figus_colors.dart';
import '../../data/providers.dart';
import '../../data/repos/sync_repo.dart';
import '../pro/theme_service.dart';

enum _Step { email, otp, done }

class AuthPage extends ConsumerStatefulWidget {
  final VoidCallback? onSignedIn;
  const AuthPage({super.key, this.onSignedIn});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  _Step _step = _Step.email;
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  // Summary of what came down from the cloud — shown on the done screen
  // so the user knows whether the sync brought their existing data or if
  // they just opened a fresh account (no rows to restore).
  _SyncSummary? _syncSummary;
  String? _syncError;
  bool _syncInProgress = false;
  // Stage tracker so the spinner can show "Baixando…" / "Aplicando…" /
  // "Subindo…" instead of an ambiguous indefinite circle.
  String _syncStage = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Digite um e-mail válido');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final err = await ref.read(syncRepoProvider).sendOtp(email);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (err == null) {
        _step = _Step.otp;
      } else {
        _error = err;
      }
    });
  }

  Future<void> _verifyOtp() async {
    final token = _otpCtrl.text.trim();
    // Supabase OTP length is configurable (4-10 digits); just check it's
    // a reasonable numeric string.
    if (token.length < 4 || token.length > 10 || int.tryParse(token) == null) {
      setState(() => _error = 'Digite o código numérico recebido por email');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final err = await ref.read(syncRepoProvider).verifyOtp(_emailCtrl.text.trim(), token);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (err == null) {
        _step = _Step.done;
      } else {
        _error = err;
      }
    });
    if (err == null) {
      // Run the initial sync in its own method so the "Tentar de novo"
      // button on the done screen can reuse it.
      await _runInitialSync();
    }
  }

  Future<void> _runInitialSync() async {
    if (!mounted) return;
    setState(() {
      _syncInProgress = true;
      _syncError = null;
      _syncSummary = null;
      _syncStage = 'Conectando...';
    });

    final repo = ref.read(collectionRepoProvider);
    final sync = ref.read(syncRepoProvider);

    try {
      // ── 1. Pull collection from cloud ───────────────────────────────────
      if (mounted) setState(() => _syncStage = 'Baixando figurinhas...');
      final remote = await sync.pullAll();
      // ignore: avoid_print
      print('[Auth] pull returned ${remote.length} rows');

      // ── 2. Pull user metadata (theme/avatar/name) ──────────────────────
      if (mounted) setState(() => _syncStage = 'Baixando perfil...');
      final settings = await sync.pullUserSettings();
      // ignore: avoid_print
      print('[Auth] settings: theme=${settings.theme} '
          'avatar=${settings.avatar} name=${settings.profileName} '
          'favs=${settings.favoriteNations?.length}');

      if (!mounted) return;

      // ── 3. Apply remote entries locally ─────────────────────────────────
      var applyStats =
          (applied: 0, unmatched: 0, markedApplied: 0, extrasApplied: 0);
      if (remote.isNotEmpty) {
        setState(() => _syncStage = 'Aplicando...');
        applyStats = await repo.applyRemoteEntries(remote);
      }
      await _applyRemoteSettings(settings);

      // ── 4. Push anything local that the cloud didn't have ──────────────
      setState(() => _syncStage = 'Sincronizando...');
      final pushStats = await repo.pushAllLocal();
      // ignore: avoid_print
      print('[Auth] pushed ${pushStats.totalRows} rows back up');

      if (!mounted) return;
      ref.read(collectionVersionProvider.notifier).state++;
      ref.invalidate(albumStatsProvider);
      ref.invalidate(albumSectionsProvider);
      ref.invalidate(profilesListProvider);

      setState(() {
        _syncInProgress = false;
        _syncStage = '';
        _syncSummary = _SyncSummary(
          email: sync.userEmail ?? '',
          userId: sync.userId ?? '',
          pulledRows: remote.length,
          appliedMarks: applyStats.markedApplied,
          appliedExtras: applyStats.extrasApplied,
          unmatched: applyStats.unmatched,
          hasTheme: settings.theme != null,
          hasAvatar: settings.avatar != null && settings.avatar!.isNotEmpty,
          hasProfileName: settings.profileName != null &&
              settings.profileName!.trim().isNotEmpty,
          hasFavorites: settings.favoriteNations != null &&
              settings.favoriteNations!.isNotEmpty,
        );
        _step = _Step.done;
      });
      widget.onSignedIn?.call();
    } catch (e, st) {
      // Any error in the sync flow surfaces here so the user can see what
      // went wrong instead of staring at a frozen spinner.
      // ignore: avoid_print
      print('[Auth] sync error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _syncInProgress = false;
        _syncStage = '';
        _syncError = e.toString();
        _step = _Step.done;
      });
    }
  }

  Future<void> _applyRemoteSettings(
      ({
        String? theme,
        List<String>? favoriteNations,
        String? profileName,
        String? avatar,
      }) s) async {
    if (s.theme != null) {
      final seed = AppThemeSeed.values
          .where((t) => t.name == s.theme)
          .firstOrNull;
      if (seed != null) {
        await ref.read(themeSeedProvider.notifier)
            .set(seed, pushToCloud: false);
      }
    }
    if (s.favoriteNations != null) {
      await ref.read(profileRepoProvider).setFavoriteNations(
            s.favoriteNations!.toSet(),
            pushToCloud: false,
          );
    }
    if (s.profileName != null && s.profileName!.trim().isNotEmpty) {
      final active = await ref.read(profileRepoProvider).active();
      if (active.name != s.profileName) {
        await ref.read(profileRepoProvider).rename(
              active.id,
              s.profileName!,
              pushToCloud: false,
            );
      }
    }
    if (s.avatar != null && s.avatar!.isNotEmpty) {
      await ref.read(profileRepoProvider)
          .setAvatarEmoji(s.avatar!, pushToCloud: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            Image.asset(
              'assets/figus-logo-square.png',
              width: 32,
              height: 32,
              filterQuality: FilterQuality.medium,
            ),
            const SizedBox(width: 10),
            Text(
              'Entrar no Figus',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: c.text,
              ),
            ),
          ],
        ),
        backgroundColor: c.cardAlt,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _step == _Step.done
                    ? _DoneView(
                        summary: _syncSummary,
                        syncInProgress: _syncInProgress,
                        syncStage: _syncStage,
                        syncError: _syncError,
                        onClose: () => Navigator.pop(context),
                        onRetry: _runInitialSync,
                      )
                    : _AuthCard(
                        c: c,
                        child: _step == _Step.email
                            ? _emailForm(c)
                            : _otpForm(c),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emailForm(FigusColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Image.asset(
          'assets/figus-logo-square.png',
          width: 84,
          height: 84,
          filterQuality: FilterQuality.medium,
        ),
        const SizedBox(height: 16),
        Text(
          'Sync entre dispositivos',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: c.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Entre com seu e-mail para sincronizar sua coleção em vários aparelhos. Nenhuma senha necessária.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: c.textMuted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _sendOtp(),
          style: GoogleFonts.inter(color: c.text),
          decoration: _inputDeco(c, 'E-mail', 'seu@email.com',
              prefix: const Icon(Icons.email_rounded)),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 13)),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _loading ? null : _sendOtp,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Enviar código'),
        ),
        const SizedBox(height: 14),
        Text(
          'Conta gratuita · sem senha · pode usar offline sem login',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 11, color: c.textMuted),
        ),
      ],
    );
  }

  Widget _otpForm(FigusColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Image.asset(
          'assets/figus-logo-square.png',
          width: 64,
          height: 64,
          filterQuality: FilterQuality.medium,
        ),
        const SizedBox(height: 12),
        Text(
          'Confirme o código',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: c.text,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enviamos o código para',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 12, color: c.textMuted),
        ),
        Text(
          _emailCtrl.text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: c.accent,
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 10,
          textAlign: TextAlign.center,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 6,
            color: c.text,
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _verifyOtp(),
          decoration: _inputDeco(c, 'Código', null).copyWith(counterText: ''),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 13)),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _loading ? null : _verifyOtp,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Confirmar'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() {
            _step = _Step.email;
            _otpCtrl.clear();
            _error = null;
          }),
          child: const Text('Usar outro e-mail'),
        ),
      ],
    );
  }

  InputDecoration _inputDeco(FigusColors c, String label, String? hint,
      {Widget? prefix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.inter(color: c.textMuted),
      hintStyle: GoogleFonts.inter(color: c.textMuted.withValues(alpha: 0.5)),
      filled: true,
      fillColor: c.bg,
      prefixIcon: prefix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.accent, width: 1.5),
      ),
    );
  }
}

/// Card wrapping the auth form so it looks consistent with other Figus
/// surfaces (rounded container, accent ring, themed background).
class _AuthCard extends StatelessWidget {
  final FigusColors c;
  final Widget child;
  const _AuthCard({required this.c, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: c.accent.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SyncSummary {
  final String email;
  final String userId;
  final int pulledRows;
  final int appliedMarks;
  final int appliedExtras;
  final int unmatched;
  final bool hasTheme;
  final bool hasAvatar;
  final bool hasProfileName;
  final bool hasFavorites;

  const _SyncSummary({
    required this.email,
    required this.userId,
    required this.pulledRows,
    required this.appliedMarks,
    required this.appliedExtras,
    required this.unmatched,
    required this.hasTheme,
    required this.hasAvatar,
    required this.hasProfileName,
    required this.hasFavorites,
  });

  // Treat "pulled rows" as the source of truth for whether the cloud had
  // data — appliedMarks only counts owned/duplicate, so a user who marked
  // then unmarked stickers (status=missing in the cloud) would otherwise
  // see "no data" even though their sync history is intact.
  bool get restoredAnything =>
      pulledRows > 0 ||
      hasTheme ||
      hasAvatar ||
      hasProfileName ||
      hasFavorites;
}

class _DoneView extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onRetry;
  final _SyncSummary? summary;
  final bool syncInProgress;
  final String syncStage;
  final String? syncError;

  const _DoneView({
    required this.onClose,
    required this.onRetry,
    required this.syncInProgress,
    required this.syncStage,
    required this.syncError,
    this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final s = summary;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Icon(
            syncError != null
                ? Icons.warning_amber_rounded
                : Icons.check_circle_rounded,
            size: 72,
            color: syncError != null
                ? const Color(0xFFE5B14B)
                : const Color(0xFF22C58A),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          syncError != null ? 'Conta conectada, mas...' : 'Conta conectada!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),

        // ── IN PROGRESS ────────────────────────────────────────────────────
        if (syncInProgress) ...[
          const SizedBox(
            height: 32,
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            syncStage.isEmpty ? 'Sincronizando...' : syncStage,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),
        ]
        // ── ERROR ──────────────────────────────────────────────────────────
        else if (syncError != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE5B14B).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE5B14B).withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Falha ao baixar seus dados:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: c.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  syncError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: c.textMuted,
                      fontSize: 11,
                      fontFamily: 'monospace',
                      height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar de novo'),
            onPressed: onRetry,
          ),
          const SizedBox(height: 8),
        ]
        // ── SUCCESS WITH DATA ──────────────────────────────────────────────
        else if (s != null && s.restoredAnything) ...[
          Text(
            'Dados restaurados da nuvem:',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: c.text, fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 12),
          _restoreLine('📡', '${s.pulledRows} linhas baixadas da nuvem'),
          if (s.appliedMarks > 0)
            _restoreLine('📒',
                '${s.appliedMarks} figurinhas marcadas'
                '${s.appliedExtras > 0 ? " · ${s.appliedExtras} repetidas" : ""}'),
          if (s.hasProfileName) _restoreLine('🪪', 'Nome do perfil'),
          if (s.hasAvatar) _restoreLine('🎭', 'Avatar'),
          if (s.hasTheme) _restoreLine('🎨', 'Tema de cor'),
          if (s.hasFavorites) _restoreLine('⭐', 'Seleções favoritas'),
          if (s.unmatched > 0) ...[
            const SizedBox(height: 8),
            Text(
              '⚠ ${s.unmatched} código(s) da nuvem não bate com este álbum',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: c.textMuted),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Logado como: ${s.email}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.textMuted,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ]
        // ── SUCCESS, BUT EMPTY ─────────────────────────────────────────────
        else if (s != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.cardAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.border),
            ),
            child: Column(
              children: [
                Text(
                  'Esta conta ainda não tinha dados na nuvem.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: c.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  'Logado como:',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.textMuted, fontSize: 11),
                ),
                Text(
                  s.email,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: c.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  'Se este NÃO é o e-mail dos seus outros dispositivos, '
                  'volte, faça logout em Ajustes e relogue com o e-mail '
                  'certo. Daqui em diante, tudo que marcar será sincronizado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: c.textMuted, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar sincronizar de novo'),
            onPressed: onRetry,
          ),
          const SizedBox(height: 8),
        ],

        const SizedBox(height: 16),
        FilledButton(
          onPressed: syncInProgress ? null : onClose,
          child: const Text('Pronto'),
        ),
      ],
    );
  }

  Widget _restoreLine(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
