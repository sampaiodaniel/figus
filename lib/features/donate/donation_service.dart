import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Product IDs registered (or to be registered) in Play Console / App Store
/// Connect as **consumable** managed products. The amount is implied by the
/// suffix — Play uses whatever price you set per country in the console.
const Set<String> kDonationProductIds = {
  'donate_5',
  'donate_10',
  'donate_20',
  'donate_50',
};

/// UI-friendly snapshot of what the donation page should render.
enum DonationStatus { idle, loading, ready, unavailable, purchasing, error }

class DonationState {
  final DonationStatus status;
  final List<ProductDetails> products;
  final String? error;
  final String? lastPurchasedId;

  const DonationState({
    required this.status,
    this.products = const [],
    this.error,
    this.lastPurchasedId,
  });

  DonationState copyWith({
    DonationStatus? status,
    List<ProductDetails>? products,
    String? error,
    String? lastPurchasedId,
  }) {
    return DonationState(
      status: status ?? this.status,
      products: products ?? this.products,
      error: error,
      lastPurchasedId: lastPurchasedId,
    );
  }
}

class DonationNotifier extends StateNotifier<DonationState> {
  final InAppPurchase _iap;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  DonationNotifier({InAppPurchase? iap})
      : _iap = iap ?? InAppPurchase.instance,
        super(const DonationState(status: DonationStatus.idle));

  /// Loads available donation products from the store. Safe to call from web
  /// (returns unavailable) or in debug without a Play Console (returns ready
  /// with empty list, which the UI surfaces as "em breve").
  Future<void> init() async {
    if (kIsWeb) {
      state = const DonationState(status: DonationStatus.unavailable);
      return;
    }
    state = state.copyWith(status: DonationStatus.loading);
    try {
      final available = await _iap.isAvailable();
      if (!available) {
        state = const DonationState(status: DonationStatus.unavailable);
        return;
      }
      // Listen for purchase results.
      _sub ??= _iap.purchaseStream.listen(_onPurchaseUpdated,
          onDone: () => _sub?.cancel(), onError: (e) {
        debugPrint('[Donation] purchaseStream error: $e');
      });
      final res = await _iap.queryProductDetails(kDonationProductIds);
      if (res.notFoundIDs.isNotEmpty) {
        debugPrint('[Donation] productIds not found: ${res.notFoundIDs}');
      }
      // Sort by price ascending so R$5 always shows first.
      final sorted = res.productDetails.toList()
        ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
      state = state.copyWith(
        status: sorted.isEmpty
            ? DonationStatus.unavailable
            : DonationStatus.ready,
        products: sorted,
      );
    } catch (e) {
      debugPrint('[Donation] init error: $e');
      state = DonationState(
        status: DonationStatus.error,
        error: e.toString(),
      );
    }
  }

  Future<void> buy(ProductDetails product) async {
    state = state.copyWith(status: DonationStatus.purchasing);
    try {
      final param = PurchaseParam(productDetails: product);
      // Donations are consumable: user can donate again. The platform also
      // requires consumePurchase for Android consumables (handled below in
      // _onPurchaseUpdated).
      await _iap.buyConsumable(purchaseParam: param);
    } catch (e) {
      debugPrint('[Donation] buy error: $e');
      state = state.copyWith(
        status: DonationStatus.ready,
        error: e.toString(),
      );
    }
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> updates) async {
    for (final p in updates) {
      switch (p.status) {
        case PurchaseStatus.pending:
          state = state.copyWith(status: DonationStatus.purchasing);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Donations carry no benefit beyond the warm feeling — just
          // acknowledge so the user can donate again.
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          state = state.copyWith(
            status: DonationStatus.ready,
            lastPurchasedId: p.productID,
          );
          break;
        case PurchaseStatus.error:
          state = state.copyWith(
            status: DonationStatus.ready,
            error: p.error?.message ?? 'Falha desconhecida na compra',
          );
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          break;
        case PurchaseStatus.canceled:
          state = state.copyWith(status: DonationStatus.ready);
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          break;
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final donationProvider =
    StateNotifierProvider<DonationNotifier, DonationState>(
        (_) => DonationNotifier());
