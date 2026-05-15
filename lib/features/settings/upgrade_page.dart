import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Pro upgrade screen — preview only. Real IAP comes when there's a Play
/// Console / App Store account connected (not in MVP scope).
class UpgradePage extends StatelessWidget {
  const UpgradePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            backgroundColor: AppTheme.seed,
            foregroundColor: Colors.white,
            title: const Text('Figus Pro'),
            flexibleSpace: const FlexibleSpaceBar(
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.seed, Color(0xFF7A5BFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList.list(
              children: [
                const Text(
                  'Pague uma vez. Use pra sempre.',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sem assinatura mensal. Sem pegadinha.',
                  style: TextStyle(color: AppTheme.inkSoft, fontSize: 15),
                ),
                const SizedBox(height: 24),
                _PriceCard(
                  title: 'Pro Lifetime',
                  price: 'R\$ 9,90',
                  highlight: true,
                  features: const [
                    'Remove o banner de anúncios',
                    'Temas premium (paletas e shimmer foil exclusivos)',
                    'Export PDF da coleção',
                  ],
                ),
                const SizedBox(height: 16),
                _PriceCard(
                  title: 'Pack Colecionador',
                  price: 'R\$ 19,90',
                  features: const [
                    'Tudo do Pro',
                    'Brindes físicos via Correios (adesivos exclusivos)',
                    'Acesso antecipado a novos álbuns',
                    'Selo de fundador',
                  ],
                ),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    'Pagamento único via loja. Sem renovação automática.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.inkSoft.withValues(alpha: 0.85)),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Voltar'),
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

class _PriceCard extends StatelessWidget {
  final String title;
  final String price;
  final List<String> features;
  final bool highlight;

  const _PriceCard({
    required this.title,
    required this.price,
    required this.features,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: highlight ? AppTheme.seed.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlight ? AppTheme.seed : AppTheme.slot.withValues(alpha: 0.4),
          width: highlight ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              if (highlight)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.seed,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Recomendado',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price,
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, height: 1)),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('uma vez',
                    style: TextStyle(color: AppTheme.inkSoft, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final f in features)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_rounded, size: 18, color: AppTheme.seed),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f, style: const TextStyle(fontSize: 14))),
                ],
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: highlight ? AppTheme.seed : AppTheme.ink,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Compra dentro do app chega quando o repositório do Daniel publicar na loja.'),
                  ),
                );
              },
              child: Text('Comprar $price'),
            ),
          ),
        ],
      ),
    );
  }
}
