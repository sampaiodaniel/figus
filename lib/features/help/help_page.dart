import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.inkDeep,
      appBar: AppBar(
        title: Text(
          'Como usar',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.cream,
          ),
        ),
        backgroundColor: AppTheme.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: const [
          _Section(
            icon: Icons.grid_view_rounded,
            iconColor: AppTheme.seed,
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
                    'Use as abas "Todas / Me faltam / Repetidas" no topo da coleção para focar no que precisa.',
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
                    'A coleção fica organizada por seleção com bandeira, código, nome e contador X/20. Toque o cabeçalho para expandir ou recolher.',
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
                    'Toque o ícone de compartilhar no topo — gera uma lista formatada por seleção para mandar no WhatsApp.',
              ),
            ],
          ),
          SizedBox(height: 12),
          _Section(
            icon: Icons.swap_horiz_rounded,
            iconColor: AppTheme.seed,
            title: 'Trocas',
            items: [
              _Item(
                emoji: '↗️',
                title: 'Compartilhar seu inventário',
                body:
                    'Na tela Trocas → "Comparar com amigo", toque o ícone ↗ no topo para exportar seu inventário em JSON e mandar para um amigo.',
              ),
              _Item(
                emoji: '📋',
                title: 'Comparar com amigo',
                body:
                    'Peça pro amigo compartilhar o inventário dele, cole no campo e toque "Comparar". O app sugere as trocas automaticamente.',
              ),
              _Item(
                emoji: '⭐',
                title: 'Regras de sugestão',
                body:
                    'Prioridade para trocas 1×1 do mesmo tipo. Brilhante vale 2 normais. As melhores trocas aparecem primeiro por pontuação.',
              ),
              _Item(
                emoji: '🃏',
                title: 'Pra trocar / Caçando',
                body:
                    'A tela também mostra o que você tem pra ofertar (repetidas) e o que ainda está caçando (faltando), agrupados por seleção.',
              ),
            ],
          ),
          SizedBox(height: 12),
          _Section(
            icon: Icons.upload_rounded,
            iconColor: AppTheme.cream,
            title: 'Importar coleção',
            items: [
              _Item(
                emoji: '📲',
                title: 'Vindo do Figuritas App',
                body:
                    'No Figuritas, vá em Compartilhar → Texto. Copie tudo. No Figus, vá em Você → Importar coleção → Colar lista, cole o texto e toque "Detectar". O app detecta o formato automaticamente.',
              ),
              _Item(
                emoji: '✅',
                title: 'Confirmação antes de salvar',
                body:
                    'Sempre aparece um resumo com Tenho / Repetidas / Faltam antes de importar. Nada é salvo sem você confirmar.',
              ),
              _Item(
                emoji: '📝',
                title: 'Lista de códigos',
                body:
                    'Também aceita listas avulsas tipo "BRA1, MEX5, FWC9" separadas por vírgula ou linha.',
              ),
            ],
          ),
          SizedBox(height: 12),
          _Section(
            icon: Icons.emoji_events_rounded,
            iconColor: AppTheme.gold,
            title: 'Copa ao vivo',
            items: [
              _Item(
                emoji: '📅',
                title: 'Jogos por dia',
                body:
                    'Veja os jogos de hoje, ontem e amanhã com horário e resultado atualizado durante a Copa.',
              ),
              _Item(
                emoji: '🏆',
                title: 'Grupos e fase eliminatória',
                body:
                    'Tabela de grupos com pontuação, placares e classificação em tempo real.',
              ),
            ],
          ),
          SizedBox(height: 12),
          _Section(
            icon: Icons.share_rounded,
            iconColor: AppTheme.seed,
            title: 'Compartilhar progresso',
            items: [
              _Item(
                emoji: '🖼️',
                title: 'Card visual',
                body:
                    'Na aba Coleção, toque o ícone de compartilhar → "Meu progresso". Gera um card 1080×1080 com porcentagem, estatísticas e sua logo.',
              ),
              _Item(
                emoji: '📋',
                title: 'Lista de faltando',
                body:
                    'A mesma tela permite compartilhar só a lista das que faltam — útil para pedir em grupos de WhatsApp.',
              ),
              _Item(
                emoji: '♻️',
                title: 'Lista de repetidas',
                body:
                    'Compartilha a lista completa de repetidas por seleção, perfeita para ofertar em grupos de troca.',
              ),
            ],
          ),
          SizedBox(height: 12),
          _Section(
            icon: Icons.palette_outlined,
            iconColor: AppTheme.gold,
            title: 'Temas de cor  ★ Pro',
            items: [
              _Item(
                emoji: '🎨',
                title: '5 temas disponíveis',
                body:
                    'Azul (padrão, grátis), Dourado, Vermelho, Esmeralda e Roxo. Os 4 coloridos são exclusivos Pro.',
              ),
              _Item(
                emoji: '👁️',
                title: 'Prévia de 10 segundos',
                body:
                    'Usuários free podem ver como fica o tema por 10 segundos antes de decidir assinar.',
              ),
              _Item(
                emoji: '📍',
                title: 'Onde acessar',
                body:
                    'Você → Temas de cor. A mudança é instantânea e afeta todo o app.',
              ),
            ],
          ),
          SizedBox(height: 12),
          _Section(
            icon: Icons.people_rounded,
            iconColor: AppTheme.creamSoft,
            title: 'Perfis múltiplos',
            items: [
              _Item(
                emoji: '👨‍👧',
                title: 'Um app, vários colecionadores',
                body:
                    'Crie perfis separados para pai, filho, irmão — cada um com sua própria coleção independente.',
              ),
              _Item(
                emoji: '✏️',
                title: 'Criar e renomear',
                body:
                    'Você → toque no seu avatar → Perfis. Toque o lápis para renomear ou "Novo perfil" para adicionar.',
              ),
              _Item(
                emoji: '🔄',
                title: 'Trocar de perfil',
                body:
                    'Na mesma tela, toque "Ativar" no perfil que quiser usar. Todos os dados da coleção mudam instantaneamente.',
              ),
            ],
          ),
          SizedBox(height: 12),
          _Section(
            icon: Icons.workspace_premium_rounded,
            iconColor: AppTheme.gold,
            title: 'Figus Pro',
            items: [
              _Item(
                emoji: '🚫',
                title: 'Sem anúncios',
                body: 'Remove o banner de anúncio que aparece no topo do app.',
              ),
              _Item(
                emoji: '🎨',
                title: 'Temas exclusivos',
                body: '4 temas de cor extras: Dourado, Vermelho, Esmeralda e Roxo.',
              ),
              _Item(
                emoji: '📡',
                title: 'Sync multi-device (em breve)',
                body:
                    'Acesse a mesma coleção em vários celulares — pai e mãe controlam juntos.',
              ),
              _Item(
                emoji: '❤️',
                title: 'Apoia o dev',
                body:
                    'O Figus é feito por um desenvolvedor independente. O Pro mantém o app gratuito pra todos.',
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
  final Color iconColor;
  final String title;
  final List<_Item> items;

  const _Section({
    required this.icon,
    required this.iconColor,
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
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.ink3,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.ink4),
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
                      color: widget.iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(widget.icon, color: widget.iconColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.cream,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppTheme.creamSoft,
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
                const Divider(height: 1, color: AppTheme.ink4),
                for (int i = 0; i < widget.items.length; i++) ...[
                  _ItemTile(item: widget.items[i]),
                  if (i < widget.items.length - 1)
                    const Divider(
                        height: 1,
                        color: AppTheme.ink4,
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
                    color: AppTheme.cream,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.body,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.creamSoft,
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
