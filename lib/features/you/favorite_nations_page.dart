import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/country_codes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../../data/seeds/wc2026_seed.dart';

class FavoriteNationsPage extends ConsumerStatefulWidget {
  const FavoriteNationsPage({super.key});
  @override
  ConsumerState<FavoriteNationsPage> createState() => _FavoriteNationsPageState();
}

class _FavoriteNationsPageState extends ConsumerState<FavoriteNationsPage> {
  Set<String>? _favorites;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final favs = await ref.read(profileRepoProvider).favoriteNations();
    if (mounted) setState(() => _favorites = favs);
  }

  Future<void> _toggle(String code) async {
    final repo = ref.read(profileRepoProvider);
    await repo.toggleFavoriteNation(code);
    final updated = await repo.favoriteNations();
    if (mounted) setState(() => _favorites = updated);
  }

  @override
  Widget build(BuildContext context) {
    final favs = _favorites;
    return Scaffold(
      appBar: AppBar(title: const Text('Seleções favoritas')),
      body: favs == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Text(
                    'Marque suas seleções de coração — figurinhas dessas seleções '
                    'sobem na lista de trocas sugeridas.',
                    style: TextStyle(color: AppTheme.inkSoft.withValues(alpha: 0.9)),
                  ),
                ),
                for (final n in WC2026Seed.nations)
                  _NationTile(
                    code: n.code,
                    name: n.name,
                    selected: favs.contains(n.code),
                    onTap: () => _toggle(n.code),
                  ),
              ],
            ),
    );
  }
}

class _NationTile extends StatelessWidget {
  final String code;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const _NationTile({
    required this.code,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iso = paniniToIso2[code];
    return ListTile(
      leading: iso == null
          ? const Icon(Icons.flag_outlined)
          : ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CountryFlag.fromCountryCode(iso, width: 32, height: 22),
            ),
      title: Text('$code · $name', style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Icon(
        selected ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: selected ? Colors.pinkAccent : AppTheme.inkSoft,
      ),
      onTap: onTap,
    );
  }
}
