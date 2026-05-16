import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        title: const Text('Entrar no Figus'),
        backgroundColor: c.cardAlt,
      ),
      body: SafeArea(
        child: Center(
          // Constrain to mobile width so desktop browser doesn't stretch the form
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _step == _Step.done
                  ? _DoneView(onClose: () => Navigator.pop(context))
                  : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Icon(Icons.sync_rounded, size: 52, color: context.fc.accent),
                    const SizedBox(height: 16),
                    const Text(
                      'Sync entre dispositivos',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Entre com seu e-mail para sincronizar sua coleção em vários aparelhos. '
                      'Nenhuma senha necessária.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.fc.textMuted, height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    if (_step == _Step.email) ...[
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _sendOtp(),
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          hintText: 'seu@email.com',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_rounded),
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Código enviado para ${_emailCtrl.text}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.fc.textMuted),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _otpCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 8),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _verifyOtp(),
                        decoration: const InputDecoration(
                          labelText: 'Código recebido por email',
                          border: OutlineInputBorder(),
                          counterText: '',
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _loading
                          ? null
                          : (_step == _Step.email ? _sendOtp : _verifyOtp),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_step == _Step.email
                              ? 'Enviar código'
                              : 'Confirmar'),
                    ),
                    if (_step == _Step.otp) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => setState(() {
                          _step = _Step.email;
                          _otpCtrl.clear();
                          _error = null;
                        }),
                        child: const Text('Usar outro e-mail'),
                      ),
                    ],
                        const Spacer(),
                        Text(
                          'Conta gratuita · sem senha · pode usar offline sem login',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: context.fc.textMuted),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
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
