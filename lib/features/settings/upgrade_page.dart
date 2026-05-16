import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../pro/pro_service.dart';

// ── Plan definitions ──────────────────────────────────────────────────────────

enum _Plan { monthly, semiannual, annual }

extension _PlanDetails on _Plan {
  String get label => switch (this) {
        _Plan.monthly => 'Mensal',
        _Plan.semiannual => 'Semestral',
        _Plan.annual => 'Anual',
      };

  String get price => switch (this) {
        _Plan.monthly => 'R\$ 6,90',
        _Plan.semiannual => 'R\$ 39',
        _Plan.annual => 'R\$ 50',
      };

  String get period => switch (this) {
        _Plan.monthly => '/mês',
        _Plan.semiannual => 'por 6 meses',
        _Plan.annual => 'por 12 meses',
      };

  String get perMonth => switch (this) {
        _Plan.monthly => 'R\$ 6,90/mês',
        _Plan.semiannual => 'R\$ 6,50/mês',
        _Plan.annual => 'R\$ 4,17/mês',
      };

  String? get badge => switch (this) {
        _Plan.monthly => null,
        _Plan.semiannual => 'Popular',
        _Plan.annual => '★ Melhor valor',
      };

  String? get hook => switch (this) {
        _Plan.monthly => null,
        _Plan.semiannual => null,
        _Plan.annual => 'Só R\$ 11 a mais que semestral — 2× o tempo!',
      };
}

// ── Page ──────────────────────────────────────────────────────────────────────

class UpgradePage extends ConsumerStatefulWidget {
  const UpgradePage({super.key});
  @override
  ConsumerState<UpgradePage> createState() => _UpgradePageState();
}

class _UpgradePageState extends ConsumerState<UpgradePage> {
  _Plan _selected = _Plan.annual;

  @override
  Widget build(BuildContext context) {
    final pro = ref.watch(proProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            backgroundColor: const Color(0xFF1A0A3C),
            foregroundColor: Colors.white,
            title: const Text('Figus Pro'),
            flexibleSpace: const FlexibleSpaceBar(
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A0A3C), Color(0xFF2E1A6E), Color(0xFF1F66FF)],
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
                // Status badges
                if (pro.isTrial)
                  _StatusBadge(
                    color: const Color(0xFF22C58A),
                    icon: Icons.timer_rounded,
                    text: 'Trial ativo — ${pro.trialDaysLeft} dias restantes',
                  ),
                if (pro.isPro)
                  const _StatusBadge(
                    color: Color(0xFFB8860B),
                    icon: Icons.workspace_premium_rounded,
                    text: 'Você já é Pro! Obrigado ❤️',
                  ),

                if (!pro.isActive) ...[
                  const Text(
                    'Mais por menos.\nSem anúncios, sempre.',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.1),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Figuritas cobra R\$ 9,90/mês. Nós custamos R\$ 6,90.',
                    style: TextStyle(color: AppTheme.inkSoft, fontSize: 14),
                  ),
                  const SizedBox(height: 16),

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
                        Icon(Icons.people_alt_rounded, size: 18, color: AppTheme.seed),
                        SizedBox(width: 8),
                        Text(
                          '847 colecionadores já são Pro',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Comparison table
                const _ComparisonTable(),
                const SizedBox(height: 24),

                // Plan selector + CTA
                if (!pro.isPro) ...[
                  const Text('Escolha seu plano',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  for (final plan in _Plan.values) ...[
                    _PlanTile(
                      plan: plan,
                      selected: _selected == plan,
                      onTap: () => setState(() => _selected = plan),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 16),

                  // Trial CTA (if eligible)
                  if (!pro.hasUsedTrial) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.lock_open_rounded),
                        label: const Text('Experimentar 7 dias grátis'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF22C58A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          await ref.read(proProvider.notifier).startTrial();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Pro ativado! 7 dias grátis.'),
                                backgroundColor: Color(0xFF22C58A),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text('Sem cartão. Cancela a qualquer momento.',
                          style: TextStyle(fontSize: 11, color: AppTheme.inkSoft)),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text('— ou —',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.inkSoft.withValues(alpha: 0.6))),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Buy CTA
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.seed,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => _showComingSoon(context),
                      child: Text('Assinar ${_selected.label} — ${_selected.price}'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'Compra dentro do app disponível ao entrar nas lojas',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppTheme.inkSoft),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
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

  void _showComingSoon(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Em breve nas lojas'),
        content: Text(
          'A cobrança do plano ${_selected.label} (${_selected.price}) será ativada '
          'quando o Figus entrar na Play Store / App Store.\n\n'
          'Use os 7 dias grátis para testar tudo!',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  const _StatusBadge({required this.color, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  final _Plan plan;
  final bool selected;
  final VoidCallback onTap;
  const _PlanTile({required this.plan, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? scheme.primary.withValues(alpha: 0.08) : AppTheme.slotSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? scheme.primary : AppTheme.inkSoft, width: 2),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Plan info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(plan.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: selected ? scheme.primary : null,
                          )),
                      if (plan.badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: plan == _Plan.annual
                                ? const Color(0xFFB8860B)
                                : scheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            plan.badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (plan.hook != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      plan.hook!,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB8860B),
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                  Text(plan.perMonth,
                      style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
                ],
              ),
            ),
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(plan.price,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: selected ? scheme.primary : null,
                    )),
                Text(plan.period,
                    style: const TextStyle(fontSize: 10, color: AppTheme.inkSoft)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable();

  static const _rows = <(String, bool, bool)>[
    ('Marcar figurinhas (ilimitado)', true, true),
    ('Scan OCR de páginas', true, true),
    ('Estatísticas e progresso', true, true),
    ('Copa do Mundo ao vivo', true, true),
    ('Comparar coleção com amigo', true, true),
    ('Scan OCR ilimitado (3/dia no free)', false, true),
    ('Sem banner e sem intersticiais', false, true),
    ('5 temas exclusivos de cor', false, true),
    ('Export da coleção em PDF', false, true),
    ('Sync entre dispositivos', false, true),
    ('Troca por Bluetooth (em breve)', false, true),
    ('Acesso antecipado a novos álbuns', false, true),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Recurso',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.inkSoft)),
            ),
            SizedBox(
              width: 56,
              child: Text('Free',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.inkSoft.withValues(alpha: 0.7),
                  )),
            ),
            SizedBox(
              width: 56,
              child: Text('Pro',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB8860B),
                  )),
            ),
          ],
        ),
        const Divider(height: 16),
        for (final (label, free, proVal) in _rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                Expanded(
                  child: Text(label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: free ? FontWeight.w400 : FontWeight.w600,
                      )),
                ),
                SizedBox(
                  width: 56,
                  child: Center(
                    child: free
                        ? Icon(Icons.check_rounded, size: 18,
                            color: AppTheme.inkSoft.withValues(alpha: 0.5))
                        : const Icon(Icons.remove_rounded, size: 18, color: AppTheme.slot),
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Center(
                    child: proVal
                        ? const Icon(Icons.check_rounded, size: 18, color: Color(0xFF22C58A))
                        : const Icon(Icons.remove_rounded, size: 18, color: AppTheme.slot),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
