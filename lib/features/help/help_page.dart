import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/figus_colors.dart';
import '../../core/widgets/figus_app_bar.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: const FigusAppBar(title: 'Como usar'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: const [
          _Section(
            icon: Icons.grid_view_rounded,
            title: 'Coleção',
            items: [
              _Item(
                emoji: '👆',
                title: 'Marcar como tenho',
                body:
                    'Toque uma figurinha cinza — ela fica colorida com o gradiente da seleção.',
              ),
              _Item(
                emoji: '👆👆',
                title: 'Marcar como repetida',
                body:
                    'Toque de novo na figurinha que já tem — aparece o badge rosa ×N no canto.',
              ),
              _Item(
                emoji: '✋',
                title: 'Remover',
                body:
                    'Toque longo em qualquer figurinha para remover (volta a "faltando").',
              ),
              _Item(
                emoji: '🔍',
                title: 'Filtros',
                body:
                    'No topo, alterne entre "Todas" e "Me faltam". As repetidas estão no menu próprio embaixo.',
              ),
              _Item(
                emoji: '🔎',
                title: 'Busca',
                body:
                    'A barra de busca aceita código (BRA10, FWC5) ou nome do jogador se você já tiver adicionado.',
              ),
              _Item(
                emoji: '🚩',
                title: 'Agrupado por seleção',
                body:
                    'A coleção fica organizada por seleção com bandeira, código, nome e contador. Toque o cabeçalho para expandir ou recolher.',
              ),
              _Item(
                emoji: '↗',
                title: 'Compartilhar progresso',
                body:
                    'Botão de compartilhar no topo abre 3 opções: card visual 1080×1080, lista de faltando ou lista de repetidas.',
              ),
            ],
          ),
          SizedBox(height: 12),
          _Section(
            icon: Icons.copy_all_rounded,
            iconColor: AppTheme.pulpSoft,
            title: 'Repetidas',
            items: [
              _Item(
                emoji: '📋',
                title: 'Sua lista de extras',
                body:
                    'Mostra todas as cópias extras agrupadas por seleção com a quantidade de cada uma.',
              ),
              _Item(
                emoji: '➖',
                title: 'Remover uma cópia',
                body:
                    'Toque o ícone − no canto direito do chip. Aparece um aviso "Desfazer" por 4 segundos caso seja acidente.',
              ),
              _Item(
                emoji: '📤',
                title: 'Compartilhar lista',
                body:
                    'Ícone de compartilhar no topo gera uma lista formatada por seleção pra mandar no WhatsApp.',
              ),
            ],
          ),
          SizedBox(height: 12),
          _Section(
            icon: Icons.swap_horiz_rounded,
            title: 'Trocas',
            items: [
              _Item(
                emoji: '📷',
                title: 'Trocar por QR Code',
                body:
                    'Mostre seu QR ou escaneie o do amigo. As sugestões aparecem na hora — não precisa de internet pra escanear.',
              ),
              _Item(
                emoji: '📋',
                title: 'Comparar com amigo',
                body:
                    'Compartilhe seu inventário ou cole o de outro colecionador. O app calcula as trocas sugeridas.',
              ),
              _Item(
                emoji: '🤝',
                title: 'One-tap "Marcamos!"',
                body:
                    'Cada sugestão tem botão verde "Marcamos!" — confirma e atualiza sua coleção: remove o que entregou das repetidas, adiciona o que recebeu.',
              ),
              _Item(
                emoji: '⭐',
                title: 'Regras de sugestão',
                body:
                    'Prioridade pra trocas 1×1 do mesmo tipo. Brilhante vale 2 normais. As melhores aparecem primeiro por pontuação.',
              ),
              _Item(
                emoji: '↗',
                title: 'Exportar repetidas',
                body:
                    'Manda sua lista formatada pelo WhatsApp ou copia pra colar em grupos.',
              ),
              _Item(
                emoji: '🔗',
                title: 'Bluetooth (em breve)',
                body:
                    'Encontre amigos por perto e troque sem internet — chega no próximo update.',
              ),
            ],
          ),
          SizedBox(height: 12),
          _Section(
            icon: Icons.emoji_events_rounded,
            title: 'Copa ao vivo',
            items: [
              _Item(
                emoji: '📅',
                title: 'Jogos por dia',
                body:
                    'Veja os jogos com filtros Hoje / Amanhã / Esta semana / Todos.',
              ),
              _Item(
                emoji: '🏆',
                title: 'Grupos e Chaveamento',
                body:
                    'Abas Grupos (com tabela de pontuação) e Chaveamento (fase eliminatória) atualizam durante a Copa.',
              ),
            ],
          ),
          SizedBox(height: 12),
          _Section(
            icon: Icons.settings_rounded,
            title: 'Ajustes',
            items: [
              _Item(
                emoji: '☁',
                title: 'Sincronizar entre dispositivos',
                body:
                    'O status de sync fica no card de Progresso (em cima). Toque pra entrar/sair — quando logado, sua coleção, tema, avatar e nome ficam sincronizados em todos os seus celulares.',
              ),
              _Item(
                emoji: '👤',
                title: 'Editar perfil',
                body:
                    'Tap no seu cartão de perfil no topo — abre edição de nome e avatar. Outros perfis (família) ficam embaixo pra você alternar.',
              ),
              _Item(
                emoji: '📊',
                title: 'Estatísticas',
                body:
                    'Painel completo com progresso, ritmo semanal, melhor dia da semana e tempo médio entre figurinhas.',
              ),
              _Item(
                emoji: '🏅',
                title: 'Conquistas',
                body:
                    '20 troféus em 5 categorias (sequência, coleção, seleções, brilhantes, extras). Vão acendendo conforme você joga.',
              ),
              _Item(
                emoji: '🎨',
                title: 'Temas de cor',
                body:
                    '2 grátis + 13 Pro. Tap num tema Pro mostra prévia de 10s antes de decidir assinar.',
              ),
              _Item(
                emoji: '⭐',
                title: 'Seleções favoritas',
                body:
                    'Marque suas seleções favoritas pra elas aparecerem primeiro nas sugestões de troca.',
              ),
              _Item(
                emoji: '📲',
                title: 'Importar coleção',
                body:
                    'Aceita texto colado do Figuritas/Cromo26 ou listas avulsas tipo "BRA1, MEX5". Sempre mostra resumo antes de salvar.',
              ),
            ],
          ),
          SizedBox(height: 12),
          _Section(
            icon: Icons.local_fire_department_rounded,
            iconColor: AppTheme.pulpSoft,
            title: 'Sequência (streak)',
            items: [
              _Item(
                emoji: '🌱',
                title: 'Conte os dias',
                body:
                    'Toda vez que você abre o app num dia novo, a sequência cresce. Marcos em 3, 7, 14, 30 e 60 dias.',
              ),
              _Item(
                emoji: '🛡',
                title: 'Escudos',
                body:
                    '3 escudos automáticos por mês. Se você pula um dia, um escudo é gasto e a sequência continua.',
              ),
            ],
          ),
          SizedBox(height: 12),
          _Section(
            icon: Icons.people_rounded,
            title: 'Perfis múltiplos',
            items: [
              _Item(
                emoji: '👨‍👧',
                title: 'Um app, vários colecionadores',
                body:
                    'Perfis separados — pai, filho, irmã — cada um com sua coleção. O 1º perfil é grátis, perfis extras são Pro.',
              ),
              _Item(
                emoji: '🔄',
                title: 'Trocar de perfil',
                body:
                    'Em Ajustes → tap no perfil ativo, depois "Ativar" em outro perfil. Tudo muda instantaneamente.',
              ),
            ],
          ),
          SizedBox(height: 12),
          _Section(
            icon: Icons.workspace_premium_rounded,
            title: 'Figus Pro',
            items: [
              _Item(
                emoji: '🚫',
                title: 'Sem anúncios',
                body: 'Remove o banner de anúncio do app.',
              ),
              _Item(
                emoji: '🎨',
                title: 'Temas premium',
                body: '13 temas exclusivos: clássicos escuros, claros quentes e claros frios.',
              ),
              _Item(
                emoji: '🎭',
                title: 'Avatares premium',
                body: '20 avatares exclusivos (clássicos diversos, estilos, festivos) além dos 5 grátis.',
              ),
              _Item(
                emoji: '📈',
                title: 'Estatísticas avançadas',
                body:
                    'Histórico semanal e identificação do seu melhor dia da semana.',
              ),
              _Item(
                emoji: '👨‍👩‍👧',
                title: 'Perfis extras',
                body: 'Mais de 1 perfil de coleção no mesmo dispositivo.',
              ),
              _Item(
                emoji: '❤️',
                title: 'Apoia o dev',
                body:
                    'Figus é feito por um dev independente. O Pro mantém o app gratuito pra todo mundo.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _Section extends StatefulWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final List<_Item> items;

  const _Section({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.items,
  });

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (widget.iconColor ?? c.accent).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(widget.icon, color: widget.iconColor ?? c.accent, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: c.text,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: c.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // Items
          if (_expanded)
            Column(
              children: [
                Divider(height: 1, color: c.border),
                for (int i = 0; i < widget.items.length; i++) ...[
                  _ItemTile(item: widget.items[i]),
                  if (i < widget.items.length - 1)
                    Divider(
                        height: 1,
                        color: c.border,
                        indent: 16,
                        endIndent: 16),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _Item {
  final String emoji;
  final String title;
  final String body;
  const _Item({required this.emoji, required this.title, required this.body});
}

class _ItemTile extends StatelessWidget {
  final _Item item;
  const _ItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.body,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: c.textMuted,
                    height: 1.45,
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
