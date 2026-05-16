import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
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
    if (token.length != 6) {
      setState(() => _error = 'O código tem 6 dígitos');
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar no Figus')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _step == _Step.done
              ? _DoneView(onClose: () => Navigator.pop(context))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const Icon(Icons.sync_rounded, size: 52, color: AppTheme.seed),
                    const SizedBox(height: 16),
                    const Text(
                      'Sync entre dispositivos',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Entre com seu e-mail para sincronizar sua coleção em vários aparelhos. '
                      'Nenhuma senha necessária.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.inkSoft, height: 1.5),
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
                        style: const TextStyle(color: AppTheme.inkSoft),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _otpCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 12),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _verifyOtp(),
                        decoration: const InputDecoration(
                          labelText: 'Código de 6 dígitos',
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
                    const Text(
                      'Conta gratuita · sem senha · pode usar offline sem login',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppTheme.inkSoft),
                    ),
                  ],
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
        const Text(
          'Sua coleção será sincronizada automaticamente\nentre todos os seus dispositivos.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.inkSoft, height: 1.5),
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
