import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import 'pro_service.dart';

enum PaywallContext {
  ocrLimit,
  theme,
  interstitialUpgrade,
  generic,
}

Future<void> showPaywall(BuildContext context, {PaywallContext trigger = PaywallContext.generic}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => PaywallSheet(trigger: trigger),
  );
}

class PaywallSheet extends ConsumerWidget {
  final PaywallContext trigger;
  const PaywallSheet({super.key, required this.trigger});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pro = ref.watch(proProvider);

    String header;
    String headerEmoji;
    switch (trigger) {
      case PaywallContext.ocrLimit:
        headerEmoji = '📷';
        header = 'Você usou os 3 scans de hoje';
      case PaywallContext.theme:
        headerEmoji = '🎨';
        header = 'Temas exclusivos são Pro';
      case PaywallContext.interstitialUpgrade:
        headerEmoji = '⚡';
        header = 'Cansou dos anúncios?';
      case PaywallContext.generic:
        headerEmoji = '✨';
        header = 'Desbloqueie tudo de uma vez';
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      builder: (_, scroll) => SingleChildScrollView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              headerEmoji,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 8),
            Text(
              header,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Figus Pro resolve isso — para sempre.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.inkSoft),
            ),
            const SizedBox(height: 24),

            // Feature list
            _FeatureRow(
              icon: Icons.document_scanner_rounded,
              title: 'Scan OCR ilimitado',
              subtitle: 'Sem limite diário. Scaneie quantas páginas quiser.',
            ),
            _FeatureRow(
              icon: Icons.block_rounded,
              title: 'Sem anúncios',
              subtitle: 'Remove banner e intersticiais completamente.',
            ),
            _FeatureRow(
              icon: Icons.palette_rounded,
              title: '5 temas exclusivos',
              subtitle: 'Dourado, Vermelho, Esmeralda, Roxo + padrão.',
            ),
            _FeatureRow(
              icon: Icons.bluetooth_rounded,
              title: 'Troca por Bluetooth (em breve)',
              subtitle: 'Membros Pro terão acesso primeiro.',
            ),
            _FeatureRow(
              icon: Icons.picture_as_pdf_rounded,
              title: 'Export da coleção em PDF',
              subtitle: 'Liste o que tem, falta e repetidas para imprimir.',
            ),

            const SizedBox(height: 20),

            // Social proof
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.slotSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_rounded, color: Color(0xFFB8860B), size: 18),
                  SizedBox(width: 6),
                  Text(
                    '847 colecionadores já são Pro',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Scarcity badge
            const Center(
              child: Text(
                '🏷️  Oferta de fundador — preço sobe quando chegar na loja',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppTheme.inkSoft),
              ),
            ),

            const SizedBox(height: 20),

            // Trial CTA (if available)
            if (!pro.hasUsedTrial && !pro.isActive) ...[
              FilledButton.icon(
                icon: const Icon(Icons.lock_open_rounded),
                label: const Text('Experimentar 7 dias grátis'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF22C58A),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await ref.read(proProvider.notifier).startTrial();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎉 Pro ativado! 7 dias grátis.'),
                        backgroundColor: Color(0xFF22C58A),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Sem cartão. Sem cobrança automática.',
                  style: TextStyle(fontSize: 11, color: AppTheme.inkSoft),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Buy CTA
            OutlinedButton.icon(
              icon: const Icon(Icons.workspace_premium_rounded),
              label: const Text('Ver planos Pro — a partir de R\$ 6,90/mês'),
              onPressed: () {
                Navigator.pop(context);
                context.push('/upgrade');
              },
            ),

            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Talvez depois',
                style: TextStyle(color: AppTheme.inkSoft, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _FeatureRow({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.seed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppTheme.seed),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
