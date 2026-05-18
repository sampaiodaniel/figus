import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/figus_colors.dart';

/// Standardized top bar used across the 5 main bottom-nav screens
/// (Coleção, Repetidas, Trocas, Copa, Ajustes). Keeps the Figus logo
/// pinned to the left, centers the screen title, and matches font/size
/// rules everywhere so the header never feels different from one tab
/// to the next.
class FigusAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const FigusAppBar({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return AppBar(
      // Title sits at the left edge; the brand logo floats absolutely in
      // the visual center via `flexibleSpace` so it isn't pushed off by
      // long titles or many trailing actions.
      centerTitle: false,
      titleSpacing: 16,
      backgroundColor: c.cardAlt,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: c.text,
        ),
      ),
      flexibleSpace: SafeArea(
        child: IgnorePointer(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Image.asset(
                'assets/figus-logo-square.png',
                width: 32,
                height: 32,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
      ),
      actions: actions,
      bottom: bottom,
    );
  }
}
