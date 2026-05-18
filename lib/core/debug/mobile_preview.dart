import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent flag that constrains the app to a phone-width column inside a
/// black letterbox — handy for previewing the mobile layout while running on
/// a tablet via USB. Honored only in debug builds.
class MobilePreviewNotifier extends StateNotifier<bool> {
  static const _key = 'debug_mobile_preview';
  MobilePreviewNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = p.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, state);
  }
}

final mobilePreviewProvider =
    StateNotifierProvider<MobilePreviewNotifier, bool>(
        (_) => MobilePreviewNotifier());

/// Wraps [child] in a phone-width column when the mobile-preview flag is on
/// (debug builds only). Overrides MediaQuery.size so responsive code sees
/// the simulated width.
class MobilePreviewWrapper extends ConsumerWidget {
  final Widget child;
  const MobilePreviewWrapper({super.key, required this.child});

  static const double _phoneWidth = 420;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Honored in release too — Daniel uses the toggle on the M8 tablet to
    // preview phone-width layouts. The kDebugMode gate was masking the
    // toggle and making it look broken.
    final enabled = ref.watch(mobilePreviewProvider);
    if (!enabled) return child;

    final mq = MediaQuery.of(context);
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: SizedBox(
          width: _phoneWidth,
          child: MediaQuery(
            data: mq.copyWith(size: Size(_phoneWidth, mq.size.height)),
            child: child,
          ),
        ),
      ),
    );
  }
}
