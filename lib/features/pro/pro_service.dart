import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class ProState {
  final bool isPro;
  final DateTime? trialEndsAt;
  final bool hasUsedTrial;
  final int ocrScansToday;
  final String ocrCountDate;

  const ProState({
    required this.isPro,
    required this.trialEndsAt,
    required this.hasUsedTrial,
    required this.ocrScansToday,
    required this.ocrCountDate,
  });

  bool get isActive =>
      isPro ||
      (trialEndsAt != null && trialEndsAt!.isAfter(DateTime.now()));

  bool get isTrial => !isPro && isActive;

  int get trialDaysLeft {
    if (trialEndsAt == null) return 0;
    return trialEndsAt!.difference(DateTime.now()).inDays + 1;
  }

  bool get canScanOcr => isActive || ocrScansToday < 3;

  int get ocrScansRemaining => isActive ? 999 : (3 - ocrScansToday).clamp(0, 3);

  ProState copyWith({
    bool? isPro,
    DateTime? trialEndsAt,
    bool? hasUsedTrial,
    int? ocrScansToday,
    String? ocrCountDate,
  }) =>
      ProState(
        isPro: isPro ?? this.isPro,
        trialEndsAt: trialEndsAt ?? this.trialEndsAt,
        hasUsedTrial: hasUsedTrial ?? this.hasUsedTrial,
        ocrScansToday: ocrScansToday ?? this.ocrScansToday,
        ocrCountDate: ocrCountDate ?? this.ocrCountDate,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ProNotifier extends StateNotifier<ProState> {
  ProNotifier()
      : super(const ProState(
          isPro: false,
          trialEndsAt: null,
          hasUsedTrial: false,
          ocrScansToday: 0,
          ocrCountDate: '',
        )) {
    _load();
  }

  static const _keyIsPro = 'pro_is_pro';
  static const _keyTrialEnds = 'pro_trial_ends';
  static const _keyHasUsedTrial = 'pro_has_used_trial';
  static const _keyOcrScans = 'pro_ocr_scans';
  static const _keyOcrDate = 'pro_ocr_date';

  String get _today {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final trialStr = p.getString(_keyTrialEnds);
    final ocrDate = p.getString(_keyOcrDate) ?? '';
    final today = _today;

    state = ProState(
      isPro: p.getBool(_keyIsPro) ?? false,
      trialEndsAt: trialStr != null ? DateTime.tryParse(trialStr) : null,
      hasUsedTrial: p.getBool(_keyHasUsedTrial) ?? false,
      ocrScansToday: ocrDate == today ? (p.getInt(_keyOcrScans) ?? 0) : 0,
      ocrCountDate: today,
    );
    if (ocrDate != today) {
      await p.setString(_keyOcrDate, today);
      await p.setInt(_keyOcrScans, 0);
    }
  }

  Future<void> activatePro() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyIsPro, true);
    state = state.copyWith(isPro: true);
  }

  Future<bool> startTrial() async {
    if (state.hasUsedTrial || state.isActive) return false;
    final ends = DateTime.now().add(const Duration(days: 7));
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyTrialEnds, ends.toIso8601String());
    await p.setBool(_keyHasUsedTrial, true);
    state = state.copyWith(trialEndsAt: ends, hasUsedTrial: true);
    return true;
  }

  Future<void> incrementOcrScan() async {
    if (state.isActive) return;
    final next = state.ocrScansToday + 1;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_keyOcrScans, next);
    await p.setString(_keyOcrDate, _today);
    state = state.copyWith(ocrScansToday: next, ocrCountDate: _today);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final proProvider = StateNotifierProvider<ProNotifier, ProState>(
  (_) => ProNotifier(),
);
