import 'package:flutter/material.dart';

/// Small gold "PRO" tag — drop next to feature labels to flag Pro-only
/// functionality. Two sizes: regular for menu rows, compact for tight UI.
class ProBadge extends StatelessWidget {
  final bool compact;
  const ProBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 1 : 3,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE5B14B), Color(0xFFB8860B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(compact ? 4 : 6),
      ),
      child: Text(
        'PRO',
        style: TextStyle(
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
