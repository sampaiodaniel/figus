import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../pro/pro_service.dart';

// ── Plan definitions ──────────────────────────────────────────────────────────

enum _Plan { monthly, semiannual, annual }

extension _PlanDetails on _Plan {
  String get label => switch (this) {
        _Plan.monthly     => 'Mensal',
        _Plan.semiannual  => 'Semestral',
        _Plan.annual      => 'Anual',
      };

  String get price => switch (this) {
        _Plan.monthly     => 'R\$ 6,90',
        _Plan.semiannual  => 'R\$ 39',
        _Plan.annual      => 'R\$ 50',
      };

  String get period => switch (this) {
        _Plan.monthly     => '/mês',
        _Plan.semiannual  => '/6 meses',
        _Plan.annual      => '/ano',
      };

  String get perMonth => switch (this) {
        _Plan.monthly     => 'R\$ 6,90/mês',
        _Plan.semiannual  => 'R\$ 6,50/mês • economiza 6%',
        _Plan.annual      => 'R\$ 4,17/mês • economiza 40%',
      };

  String? get badge => switch (this) {
        _Plan.monthly     => null,
        _Plan.semiannual  => null,
        _Plan.annual      => '★ Melhor valor',
      };

  String? get hook => switch (this) {
        _Plan.monthly     => null,
        _Plan.semiannual  => null,
        _Plan.annual      => 'Figus o ano inteiro por menos que um café',
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
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            backgroundColor: AppTheme.inkDeep,
            foregroundColor: AppTheme.cream,
            title: Row(
              children: [
                Text('FIGUS',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.gold,
                      letterSpacing: 1.5,
                    )),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.gold,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('PRO',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.inkDeep,
                        letterSpacing: 1.0,
                      )),
                ),
              ],
            ),
            flexibleSpace: const FlexibleSpaceBar(
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.inkDeep, AppTheme.ink, Color(0xFF2A1F10)],
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
                    color: AppTheme.field,
                    icon: Icons.timer_rounded,
                    text: 'Trial ativo — ${pro.trialDaysLeft} dias restantes',
                  ),
                if (pro.isPro)
                  _StatusBadge(
                    color: AppTheme.gold,
                    icon: Icons.workspace_premium_rounded,
                    text: 'Você já é Pro! Obrigado ❤️',
                  ),

                if (!pro.isActive) ...[
                  Text(
                    'Sem anúncios.\nMais recursos.\nMais Copa.',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                      color: AppTheme.cream,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Mais recursos, sem distrações — a partir de R\$ 6,90/mês.',
                    style: TextStyle(
                      color: AppTheme.creamSoft,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Social proof
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.ink3,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_alt_rounded, size: 18, color: primary),
                        const SizedBox(width: 8),
                        Text(
                          '847 colecionadores já são Pro',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppTheme.cream,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Comparison table
                const _ComparisonTable(),
                const SizedBox(height: 28),

                // Plan selector + CTA
                if (!pro.isPro) ...[
                  Text('Escolha seu plano',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.cream,
                      )),
                  const SizedBox(height: 12),
                  for (final plan in _Plan.values) ...[
                    _PlanTile(
                      plan: plan,
                      selected: _selected == plan,
                      onTap: () => setState(() => _selected = plan),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 20),

                  // Trial CTA
                  if (!pro.hasUsedTrial) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.lock_open_rounded),
                        label: const Text('Experimentar 3 dias grátis'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.field,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          await ref.read(proProvider.notifier).startTrial();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Pro ativado! 3 dias grátis.'),
                                backgroundColor: AppTheme.field,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Sem cartão. Cancela a qualquer momento.',
                        style: TextStyle(fontSize: 11, color: AppTheme.creamSoft),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        '— ou —',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.creamSoft.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Buy CTA
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.gold,
                        foregroundColor: AppTheme.inkDeep,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onPressed: () => _showComingSoon(context),
                      child: Text('Assinar ${_selected.label} — ${_selected.price}'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Compra dentro do app disponível ao entrar nas lojas',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppTheme.creamSoft),
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
          'Use os 3 dias grátis para testar tudo!',
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
        color: color.withValues(alpha: 0.12),
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
    final accent = selected ? AppTheme.gold : AppTheme.ink4;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.gold.withValues(alpha: 0.10) : AppTheme.ink,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent, width: 2),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10, height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.gold,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
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
                            color: selected ? AppTheme.gold : AppTheme.cream,
                          )),
                      if (plan.badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.gold,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            plan.badge!,
                            style: const TextStyle(
                              color: AppTheme.inkDeep,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (plan.hook != null) ...[
                    const SizedBox(height: 2),
                    Text(plan.hook!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.goldSoft,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                  Text(plan.perMonth,
                      style: TextStyle(fontSize: 12, color: AppTheme.creamSoft)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(plan.price,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: selected ? AppTheme.gold : AppTheme.cream,
                    )),
                Text(plan.period,
                    style: TextStyle(fontSize: 11, color: AppTheme.creamSoft)),
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
    // ── Grátis para todos ────────────────────────────────────────────────────
    ('Marcar figurinhas (ilimitado)', true, true),
    ('Scan OCR · 3 por dia no Free', true, true),
    ('Estatísticas e progresso', true, true),
    ('Copa ao vivo · grupos e resultados', true, true),
    ('Comparar coleção com amigo', true, true),
    ('1 perfil pessoal', true, true),
    ('Importar do Figuritas App', true, true),
    ('Sync entre dispositivos · mesmo perfil em 2 celulares', true, true),
    // ── Exclusivo Pro ────────────────────────────────────────────────────────
    ('Sem anúncios no app', false, true),
    ('Temas de cor exclusivos · modo claro e escuro', false, true),
    ('Perfis adicionais (família) + renomear perfis', false, true),
    ('Scan OCR ilimitado', false, true),
    ('Troca por Bluetooth (em breve)', false, true),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.ink,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.ink4),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Recurso',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.creamSoft,
                      )),
                ),
                SizedBox(
                  width: 56,
                  child: Text('Free',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.creamSoft.withValues(alpha: 0.7),
                      )),
                ),
                SizedBox(
                  width: 56,
                  child: Text('Pro',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.gold,
                      )),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (int i = 0; i < _rows.length; i++)
            _TableRow(
              label: _rows[i].$1,
              free: _rows[i].$2,
              proVal: _rows[i].$3,
              last: i == _rows.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final String label;
  final bool free;
  final bool proVal;
  final bool last;
  const _TableRow({required this.label, required this.free, required this.proVal, required this.last});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    style: TextStyle(
                      fontSize: 13,
                      color: free ? AppTheme.cream : AppTheme.gold,
                      fontWeight: FontWeight.w500,
                    )),
              ),
              SizedBox(
                width: 56,
                child: Center(
                  child: free
                      ? const Icon(Icons.check_rounded, size: 18,
                          color: AppTheme.creamSoft)
                      : Icon(Icons.remove_rounded, size: 18,
                          color: AppTheme.ink4),
                ),
              ),
              SizedBox(
                width: 56,
                child: Center(
                  child: proVal
                      ? const Icon(Icons.check_rounded, size: 18, color: AppTheme.gold)
                      : Icon(Icons.remove_rounded, size: 18, color: AppTheme.ink4),
                ),
              ),
            ],
          ),
        ),
        if (!last) const Divider(height: 1),
      ],
    );
  }
}
