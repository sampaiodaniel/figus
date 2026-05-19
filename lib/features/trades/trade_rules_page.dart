import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/figus_colors.dart';
import '../../core/widgets/figus_app_bar.dart';
import 'trade_rules.dart';

/// Settings page where the user tunes how the matcher generates trade
/// suggestions. Daniel: "1 brilhante por 3 normais no prédio do amigo,
/// outro lugar pode ser 1×2 — preciso conseguir configurar".
class TradeRulesPage extends ConsumerWidget {
  const TradeRulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(tradeRulesProvider);
    final notifier = ref.read(tradeRulesProvider.notifier);
    final c = context.fc;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: const FigusAppBar(title: 'Trocas'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _SectionHeader(
            icon: Icons.balance_rounded,
            label: 'PROPORÇÕES DE TROCA',
            subtitle:
                'Ajuste pro padrão do seu grupo — em alguns lugares 1 brilhante vale 3 normais, em outros 1×2.',
          ),
          const SizedBox(height: 12),
          _RuleTile(
            title: 'Normal por normal',
            sublabel: 'A maioria das trocas',
            leftValue: rules.normalGive,
            leftLabel: 'normais',
            rightValue: rules.normalReceive,
            rightLabel: 'normais',
            onLeft: (n) => notifier.update(rules.copyWith(normalGive: n)),
            onRight: (n) => notifier.update(rules.copyWith(normalReceive: n)),
          ),
          const SizedBox(height: 10),
          _RuleTile(
            title: 'Brilhante por brilhante',
            sublabel: 'Trocas entre figurinhas metalizadas',
            leftValue: rules.foilGive,
            leftLabel: 'brilhantes',
            rightValue: rules.foilReceive,
            rightLabel: 'brilhantes',
            onLeft: (n) => notifier.update(rules.copyWith(foilGive: n)),
            onRight: (n) => notifier.update(rules.copyWith(foilReceive: n)),
          ),
          const SizedBox(height: 10),
          _RuleTile(
            title: 'Brilhante por normais',
            sublabel:
                'Quantas figurinhas comuns equivalem a uma metalizada no seu grupo',
            leftValue: 1,
            leftLabel: 'brilhante',
            leftEditable: false,
            rightValue: rules.foilToNormalRatio,
            rightLabel: 'normais',
            onRight: (n) =>
                notifier.update(rules.copyWith(foilToNormalRatio: n)),
          ),
          const SizedBox(height: 24),

          _SectionHeader(
            icon: Icons.shuffle_rounded,
            label: 'COMO ESCOLHER AS QUE EU DOU',
            subtitle:
                'Quando tenho várias opções de repetidas, qual o app sugere primeiro?',
          ),
          const SizedBox(height: 12),
          _StrategyTile(
            value: GiveStrategy.random,
            current: rules.giveStrategy,
            title: 'Aleatório',
            sub: 'Sorteia entre as repetidas. Recomendado se você não tem preferência.',
            onTap: () =>
                notifier.update(rules.copyWith(giveStrategy: GiveStrategy.random)),
          ),
          const SizedBox(height: 8),
          _StrategyTile(
            value: GiveStrategy.alphabetical,
            current: rules.giveStrategy,
            title: 'Ordem alfabética (por seleção)',
            sub:
                'Alemanha antes de Brasil, Coreia do Sul antes de Egito. Bom pra confirmar com o álbum físico na mão.',
            onTap: () => notifier.update(
                rules.copyWith(giveStrategy: GiveStrategy.alphabetical)),
          ),
          const SizedBox(height: 8),
          _StrategyTile(
            value: GiveStrategy.randomKeepFavorites,
            current: rules.giveStrategy,
            title: 'Aleatório · poupa favoritas',
            sub:
                'Aleatório, mas guarda as repetidas das suas seleções favoritas pro fim da fila.',
            onTap: () => notifier.update(rules.copyWith(
                giveStrategy: GiveStrategy.randomKeepFavorites)),
          ),
          const SizedBox(height: 28),

          OutlinedButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Restaurar padrões (1×1 e 1 × 2)'),
            onPressed: notifier.reset,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: c.accent, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: c.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: c.textMuted, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _RuleTile extends StatelessWidget {
  final String title;
  final String sublabel;
  final int leftValue;
  final String leftLabel;
  final bool leftEditable;
  final int rightValue;
  final String rightLabel;
  final void Function(int)? onLeft;
  final void Function(int)? onRight;

  const _RuleTile({
    required this.title,
    required this.sublabel,
    required this.leftValue,
    required this.leftLabel,
    this.leftEditable = true,
    required this.rightValue,
    required this.rightLabel,
    this.onLeft,
    this.onRight,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: c.text,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: TextStyle(fontSize: 11, color: c.textMuted, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CounterField(
                  value: leftValue,
                  unit: leftLabel,
                  editable: leftEditable,
                  onChanged: onLeft,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.swap_horiz_rounded, color: c.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: _CounterField(
                  value: rightValue,
                  unit: rightLabel,
                  onChanged: onRight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CounterField extends StatelessWidget {
  final int value;
  final String unit;
  final bool editable;
  final void Function(int)? onChanged;

  const _CounterField({
    required this.value,
    required this.unit,
    this.editable = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: c.cardAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (editable)
            _RoundIconButton(
              icon: Icons.remove,
              enabled: value > 1,
              onTap: () => onChanged?.call((value - 1).clamp(1, 99)),
            )
          else
            const SizedBox(width: 32),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$value',
                    style: GoogleFonts.jetBrainsMono(
                      color: c.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  Text(
                    unit,
                    style: TextStyle(fontSize: 10, color: c.textMuted),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
          if (editable)
            _RoundIconButton(
              icon: Icons.add,
              enabled: value < 20,
              onTap: () => onChanged?.call((value + 1).clamp(1, 99)),
            )
          else
            const SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return SizedBox(
      width: 32,
      height: 32,
      child: Material(
        color: enabled ? c.accent.withValues(alpha: 0.15) : c.cardAlt,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  onTap();
                }
              : null,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? c.accent : c.textMuted,
          ),
        ),
      ),
    );
  }
}

class _StrategyTile extends StatelessWidget {
  final GiveStrategy value;
  final GiveStrategy current;
  final String title;
  final String sub;
  final VoidCallback onTap;
  const _StrategyTile({
    required this.value,
    required this.current,
    required this.title,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final selected = value == current;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: selected ? c.accent.withValues(alpha: 0.10) : c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? c.accent : c.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? c.accent : c.textMuted,
              size: 22,
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
                      color: c.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: TextStyle(
                      color: c.textMuted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
