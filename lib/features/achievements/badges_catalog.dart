/// Static catalog of every achievement the app knows about. The list is
/// the source of truth — the DB only stores which `id`s a given profile
/// has earned (table `badges`), so adding/removing entries here is safe.
library;

import 'package:flutter/material.dart';

enum AchievementCategory {
  streak('Sequência'),
  collection('Coleção'),
  nations('Seleções'),
  foils('Brilhantes'),
  extras('Extras');

  final String label;
  const AchievementCategory(this.label);
}

@immutable
class AchievementDef {
  final String id;
  final String label;
  final String description;
  final String emoji;
  final Color color;
  final AchievementCategory category;

  const AchievementDef({
    required this.id,
    required this.label,
    required this.description,
    required this.emoji,
    required this.color,
    required this.category,
  });
}

const kAchievements = <AchievementDef>[
  // ── Sequência (streak) ─────────────────────────────────────────────────────
  AchievementDef(
    id: 'streak_3',
    label: 'Brotinho',
    description: '3 dias seguidos abrindo o Figus',
    emoji: '🌱',
    color: Color(0xFF22C58A),
    category: AchievementCategory.streak,
  ),
  AchievementDef(
    id: 'streak_7',
    label: 'Em chamas',
    description: '1 semana sem perder o dia',
    emoji: '🔥',
    color: Color(0xFFFF7B3D),
    category: AchievementCategory.streak,
  ),
  AchievementDef(
    id: 'streak_14',
    label: 'Disciplinado',
    description: '2 semanas seguidas',
    emoji: '💪',
    color: Color(0xFFE5B14B),
    category: AchievementCategory.streak,
  ),
  AchievementDef(
    id: 'streak_30',
    label: 'Lendário',
    description: '1 mês inteiro de visitas diárias',
    emoji: '🏆',
    color: Color(0xFFB8860B),
    category: AchievementCategory.streak,
  ),
  AchievementDef(
    id: 'streak_60',
    label: 'Eterno',
    description: '2 meses seguidos — você nunca falha',
    emoji: '👑',
    color: Color(0xFF8A3FFC),
    category: AchievementCategory.streak,
  ),

  // ── Coleção (sticker count) ────────────────────────────────────────────────
  AchievementDef(
    id: 'first_sticker',
    label: 'Primeira figurinha',
    description: 'Marcou a primeira do álbum',
    emoji: '⭐',
    color: Color(0xFFFFD166),
    category: AchievementCategory.collection,
  ),
  AchievementDef(
    id: 'ten_stickers',
    label: 'Começando bem',
    description: '10 figurinhas marcadas',
    emoji: '🎯',
    color: Color(0xFF1AB4D3),
    category: AchievementCategory.collection,
  ),
  AchievementDef(
    id: 'hundred_stickers',
    label: 'Cem por cento',
    description: '100 figurinhas no álbum',
    emoji: '💯',
    color: Color(0xFF1F66FF),
    category: AchievementCategory.collection,
  ),
  AchievementDef(
    id: 'half_album',
    label: 'Meio caminho',
    description: 'Metade do álbum completa',
    emoji: '🌗',
    color: Color(0xFF6B3FA0),
    category: AchievementCategory.collection,
  ),
  AchievementDef(
    id: 'complete_album',
    label: 'Álbum cheio!',
    description: 'Todas as 980 figurinhas',
    emoji: '🎉',
    color: Color(0xFFFF2D87),
    category: AchievementCategory.collection,
  ),

  // ── Seleções ───────────────────────────────────────────────────────────────
  AchievementDef(
    id: 'complete_one_nation',
    label: 'Primeira seleção',
    description: 'Completou uma seleção inteira',
    emoji: '🏁',
    color: Color(0xFF22A87E),
    category: AchievementCategory.nations,
  ),
  AchievementDef(
    id: 'complete_five_nations',
    label: 'Caçador de bandeiras',
    description: '5 seleções completas',
    emoji: '🌟',
    color: Color(0xFFE5B14B),
    category: AchievementCategory.nations,
  ),
  AchievementDef(
    id: 'complete_all_nations',
    label: 'Hexa mundial',
    description: 'As 48 seleções completas',
    emoji: '🌍',
    color: Color(0xFF1F66FF),
    category: AchievementCategory.nations,
  ),

  // ── Brilhantes ─────────────────────────────────────────────────────────────
  AchievementDef(
    id: 'first_foil',
    label: 'Primeira brilhante',
    description: 'Marcou sua primeira foil',
    emoji: '✨',
    color: Color(0xFFE5B14B),
    category: AchievementCategory.foils,
  ),
  AchievementDef(
    id: 'ten_foils',
    label: 'Brilhante coleção',
    description: '10 brilhantes marcadas',
    emoji: '⚡',
    color: Color(0xFFFFD166),
    category: AchievementCategory.foils,
  ),
  AchievementDef(
    id: 'all_foils',
    label: 'Todas brilhando',
    description: 'As 49 brilhantes completas',
    emoji: '🌠',
    color: Color(0xFFFF7B3D),
    category: AchievementCategory.foils,
  ),

  // ── Extras (engajamento) ───────────────────────────────────────────────────
  AchievementDef(
    id: 'first_scan',
    label: 'Scanner ativado',
    description: 'Usou o OCR pela primeira vez',
    emoji: '📷',
    color: Color(0xFF1AB4D3),
    category: AchievementCategory.extras,
  ),
  AchievementDef(
    id: 'first_share',
    label: 'Espalhou a notícia',
    description: 'Compartilhou seu álbum',
    emoji: '📲',
    color: Color(0xFF22C58A),
    category: AchievementCategory.extras,
  ),
  AchievementDef(
    id: 'pro_member',
    label: 'Figus Pro',
    description: 'Apoiou o app virando Pro',
    emoji: '💎',
    color: Color(0xFF8A3FFC),
    category: AchievementCategory.extras,
  ),
  AchievementDef(
    id: 'figus_pioneer',
    label: 'Pioneiro',
    description: 'Está no Figus desde o início',
    emoji: '🚀',
    color: Color(0xFF1F66FF),
    category: AchievementCategory.extras,
  ),
];

/// Defs grouped by category — for the UI section list.
Map<AchievementCategory, List<AchievementDef>> get achievementsByCategory {
  final map = <AchievementCategory, List<AchievementDef>>{};
  for (final a in kAchievements) {
    map.putIfAbsent(a.category, () => []).add(a);
  }
  return map;
}
