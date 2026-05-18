import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/theme/figus_colors.dart';
import '../../core/widgets/figus_app_bar.dart';
import 'donation_service.dart';

/// Donation page. Primary path is Google Play / App Store in-app purchase
/// (consumable products). PIX is exposed as a fee-free fallback for users
/// who prefer it (or when IAP isn't available yet).
class DonatePage extends ConsumerStatefulWidget {
  const DonatePage({super.key});

  // Chave aleatória PIX — não expõe email/celular pessoal.
  static const String _pixKey = '3966f128-51b8-4441-a038-8f74c4e3933a';
  static const String _pixName = 'Daniel Sampaio';

  @override
  ConsumerState<DonatePage> createState() => _DonatePageState();
}

class _DonatePageState extends ConsumerState<DonatePage> {
  bool _showPix = false;

  @override
  void initState() {
    super.initState();
    // Kick off product fetch as soon as the page mounts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(donationProvider.notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final donation = ref.watch(donationProvider);

    // Show a success snackbar when a purchase completes.
    ref.listen<DonationState>(donationProvider, (prev, next) {
      if (next.lastPurchasedId != null &&
          prev?.lastPurchasedId != next.lastPurchasedId) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(
            content: Text('Doação recebida — muito obrigado! ♥'),
            duration: Duration(seconds: 4),
          ));
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text('Erro: ${next.error}'),
            backgroundColor: Colors.red.shade700,
          ));
      }
    });

    return Scaffold(
      appBar: const FigusAppBar(title: 'Apoiar o dev'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          // Hero
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.accent.withValues(alpha: 0.12),
              ),
              child: Icon(Icons.favorite_rounded, color: c.accent, size: 32),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Apoie o Figus',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: c.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'O Figus é gratuito e feito por uma pessoa só. Sem rastreamento '
            'invasivo, sem assinatura forçada, sem paywall em features '
            'essenciais. Se ajudou e quiser contribuir, qualquer valor cai '
            'direto pra manter o app vivo e sem propaganda agressiva.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 28),

          // Donation grid (Google Play IAP)
          _DonationGrid(state: donation),

          const SizedBox(height: 28),

          // Fallback PIX (collapsible)
          _PixFallback(
            showPix: _showPix,
            onToggle: () => setState(() => _showPix = !_showPix),
            pixKey: DonatePage._pixKey,
            pixName: DonatePage._pixName,
          ),

          const SizedBox(height: 24),
          _OtherWays(),
        ],
      ),
    );
  }
}

class _DonationGrid extends StatelessWidget {
  final DonationState state;
  const _DonationGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;

    if (state.status == DonationStatus.loading ||
        state.status == DonationStatus.idle) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state.status == DonationStatus.unavailable || state.products.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.cardAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Column(
          children: [
            Icon(Icons.hourglass_top_rounded, color: c.textMuted, size: 32),
            const SizedBox(height: 8),
            Text(
              'Doação via Google Play em breve',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: c.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Assim que o app for liberado na loja, os valores aparecem aqui. '
              'Por enquanto dá pra apoiar via PIX abaixo.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: c.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Escolha um valor',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: c.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            for (final p in state.products) _DonationButton(product: p),
          ],
        ),
        if (state.status == DonationStatus.purchasing) ...[
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Processando…',
              style: TextStyle(color: c.textMuted, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }
}

class _DonationButton extends ConsumerWidget {
  final ProductDetails product;
  const _DonationButton({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.fc;
    final disabled =
        ref.watch(donationProvider).status == DonationStatus.purchasing;
    return SizedBox(
      width: 140,
      child: FilledButton.tonal(
        onPressed: disabled
            ? null
            : () => ref.read(donationProvider.notifier).buy(product),
        style: FilledButton.styleFrom(
          backgroundColor: c.accent.withValues(alpha: 0.14),
          foregroundColor: c.accent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          product.price,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PixFallback extends StatelessWidget {
  final bool showPix;
  final VoidCallback onToggle;
  final String pixKey;
  final String pixName;

  const _PixFallback({
    required this.showPix,
    required this.onToggle,
    required this.pixKey,
    required this.pixName,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF32BCAD).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'PIX',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF32BCAD),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Preferir PIX? Toque pra ver',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.text,
                      ),
                    ),
                  ),
                  Icon(
                    showPix ? Icons.expand_less : Icons.expand_more,
                    color: c.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (showPix)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    pixName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    pixKey,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.accent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _copyKey(context, pixKey),
                    icon: const Icon(Icons.content_copy_rounded, size: 18),
                    label: const Text('Copiar chave PIX'),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Cole no app do seu banco · informe o valor que quiser',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: c.textMuted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _copyKey(BuildContext context, String key) async {
    await Clipboard.setData(ClipboardData(text: key));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Chave PIX copiada — cole no app do seu banco'),
          duration: Duration(seconds: 3),
        ),
      );
  }
}

class _OtherWays extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Outras formas de ajudar',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: c.text,
          ),
        ),
        const SizedBox(height: 8),
        _Helper(
          icon: Icons.star_rounded,
          text: 'Deixe 5 estrelas na Play Store — ajuda na descoberta',
        ),
        _Helper(
          icon: Icons.ios_share_rounded,
          text: 'Compartilhe com outros colecionadores via WhatsApp',
        ),
        _Helper(
          icon: Icons.bug_report_rounded,
          text: 'Reporte bugs e sugestões em Configurações → Ajuda',
        ),
      ],
    );
  }
}

class _Helper extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Helper({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: c.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 13, color: c.textMuted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
