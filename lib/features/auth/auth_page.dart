import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/figus_colors.dart';
import '../../data/providers.dart';
import '../../data/repos/sync_repo.dart';

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
        widget.onSignedIn?.call();
      } else {
        _error = err;
      }
    });
    if (err == null) {
      // First push everything we have locally (in case user marked stickers
      // before logging in), then pull to merge whatever else is on the
      // server.
      final repo = ref.read(collectionRepoProvider);
      await repo.pushAllLocal();
      final remote = await ref.read(syncRepoProvider).pullAll();
      if (remote.isNotEmpty && mounted) {
        await repo.applyRemoteEntries(remote);
        ref.invalidate(collectionVersionProvider);
      }
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
                    ? _DoneView(onClose: () => Navigator.pop(context))
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

class _DoneView extends StatelessWidget {
  final VoidCallback onClose;
  const _DoneView({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_rounded, size: 72, color: Color(0xFF22C58A)),
        const SizedBox(height: 16),
        const Text('Conta conectada!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          'Sua coleção será sincronizada automaticamente\nentre todos os seus dispositivos.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.fc.textMuted, height: 1.5),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: onClose,
          child: const Text('Pronto'),
        ),
      ],
    );
  }
}
